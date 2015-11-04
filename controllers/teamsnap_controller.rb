class TeamsnapController < BabelController
  def authenticate!
    user     = params[:email] || ENV['TEAMSNAP_USER']
    password = params[:password] || ENV['TEAMSNAP_PASSWORD']

    digest = Digest::SHA256.hexdigest("#{user}#{password}")

    @token = tokens.fetch(digest) do
      Teamsnap::Auth.token(
        user: user,
        password: password
      )
    end
  end

  before '*' do
    content_type 'application/json'
    if %w[
        push
        pull
        teams
        divisions
        locations
        test-push
        test
      ].include? request.path_info.split('/').last
      authenticate!
    end
  end

  get '/sports' do
    cache.fetch(:sports) do
      {
        sports: Teamsnap::Sport.all.map do |sport|
          {
            id: sport['sport']['id'],
            name: sport['sport']['sport_name']
          }
        end
      }.to_json
    end
  end

  get '/time_zones' do
    cache.fetch(:time_zones) do
      {
        time_zones: Teamsnap::TimeZone.all.map do |time_zone|
          time_zone['time_zone']
        end
      }.to_json
    end
  end

  if ENV['RACK_ENV'] == 'development'
    get '/test-push' do
      divisions = Teamsnap::Division.all({token: @token})

      unless divisions.first
        halt 400, {
          error: "Teamsnap account does not contain a root division"
        }.to_json
      end

      do_push({
        body: File.open("samples/sample5.json", "r").read,
        division_id: divisions.first['id'],
        sport_id: 59,
        time_zone: "Central Time (US & Canada)",
        zip_code: '18273',
      })
    end

    get '/test' do
      teams = Teamsnap::Team.all({token: @token})

      teams.to_json
    end
  end

  post '/pull' do
    response = nil
    timeout = 0

    job = -> {
      do_pull
    }

    result = -> (val) { response = val }

    EventMachine::defer job, result

    stream do |out|
      until response || timeout >= TIME_OUT_LIMIT
        sleep 1
        timeout += 1
        out << " "
      end

      if timeout >= TIME_OUT_LIMIT
        out << { error: "Timeout error" }.to_json
        sleep 0.1
        EventMachine.stop
        Kernel.exit(false)
      else
        out << response
      end
    end
  end

  post '/push' do
    body = request.body.read
    logger.info body

    divisions = Teamsnap::Division.all({token: @token})

    unless divisions.first
      halt 400, {
        error: "Teamsnap account does not contain a root division"
      }.to_json
    end

    response = nil
    timeout = 0

    job = -> {
      do_push({
        body: body,
        division_id: divisions.first['id'],
        country: params[:country],
        sport_id: params[:sport_id],
        time_zone: params[:time_zone],
        zip_code: params[:zip_code] || '',
      })
    }

    result = -> (val) { response = val }

    EventMachine::defer job, result

    stream do |out|
      until response || timeout >= TIME_OUT_LIMIT
        sleep 1
        timeout += 1
        out << " "
      end

      if timeout >= TIME_OUT_LIMIT
        out << { error: "Timeout error" }.to_json
        sleep 0.1
        EventMachine.stop
        Kernel.exit(false)
      else
        out << response
      end
    end
  end

  get '/divisions' do
    Teamsnap::Division.all({
      token: @token
    }).to_json
  end

  get '/teams' do
    Teamsnap::Team.all({
      token: @token
    }).to_json
  end

  get '/locations' do
    divisions = Teamsnap::Division.all({token: @token})

    locations = []

    divisions.each do |division|
      locations += Teamsnap::Location.all({
        token: @token,
        division_id: division['id']
      })
    end

    locations.to_json
  end

  def do_pull(options={})
    mapping = {
      divisions: {},
      teams:     {},
      venues:    {},
    }

    logger.info 'fetch teams'
    teams = Teamsnap::Team.all({token: @token})

    logger.info 'fetch divisions'
    divisions = Teamsnap::Division.all({token: @token})

    divisions.each do |division|
      ds_division = DiamondScheduler::Division.new
      ds_division['name'] = division['name']
      ds_division['metadata'].set(:teamsnap, id: division['id'])
      division_id = division['id']

      mapping[:divisions][division['id']] = ds_division

      locations = Teamsnap::Location.all({
        token: @token,
        division_id: division_id,
      })

      locations.each do |location|
        location = location['location']

        venue = DiamondScheduler::Venue.new
        venue['name'] = location['location_name']
        venue['map_url'] = location['location_url']
        venue['address_1'] = location['address']
        venue['phone'] = location['location_phone']
        venue['metadata'].set(:teamsnap, id: location['id'])

        mapping[:venues][location['id']] = venue
      end
    end

    teams.each do |team|
      team = team['team']
      next unless team

      ds_team = DiamondScheduler::Team.new
      ds_team['name'] = team['team_name']
      ds_team['metadata'].set(:teamsnap, id: team['id'])
      ds_team['metadata'].set(:teamsnap, timezone: team['timezone'])

      mapping[:teams][team['id']] = ds_team

      if team['division_id']
        if division = mapping[:divisions][team['division_id']]
          division[:teams] ||= []
          division[:teams] << ds_team
        end
      else
        mapping[:divisions][0] ||= {
          name: 'No Division',
          teams: []
        }
        mapping[:divisions][0][:teams] << ds_team
      end
    end

    ds_divisions = mapping[:divisions].map { |k, v| v }
    ds_divisions.delete_if { |d| (d['teams'] || []).empty? }

    league = DiamondScheduler::League.new('league' => {
      'divisions' => ds_divisions,
      'venues' => mapping[:venues].map { |k, v| v },
    })

    now = Time.now
    pulls = league[:metadata].get(:teamsnap, 'pulls') || []
    pulls << {
      'created_at' => now.to_s,
      'created_at_timestamp' => now.to_i
    }
    league[:metadata].set(:teamsnap, pulls: pulls)

    logger.info '=> pull complete'

    league.to_json
  end

  def do_push(options={})
    pushed = {
      teams:     {},
      players:   {},
      locations: {},
      opponents: {},
      games:     {},
      practices: {},
    }

    body        = options[:body]
    country     = options[:country] || 'United States'
    sport_id    = options[:sport_id]
    time_zone   = options[:time_zone]
    zip_code    = options[:zip_code]
    division_id = options[:division_id]

    league = DiamondScheduler::League.new JSON.parse(body)

    logger.info "#{league.teams.size} team(s)"

    league.teams.each do |team|
      result = Teamsnap::Team.create_or_update({
        token: @token,
        team: {
          id: team[:metadata].get(:teamsnap, :id),
          team_name: team[:name],
          sport_id: sport_id,
          timezone: time_zone,
          country: country,
          zipcode: zip_code,
        }
      })

      logger.info "Pushed team name=#{team[:name]}"

      team_id = result['team']['id']
      roster_id = result['team']['available_rosters'].first['id']

      team[:metadata].set(:teamsnap, id: team_id)
      team[:metadata].set(:teamsnap, roster_id: roster_id)

      logger.info "#{team[:players].size} player(s)"

      team[:players].each do |player|
        result = Teamsnap::Roster.create_or_update({
          token: @token,
          team_id: team_id,
          roster_id: roster_id,
          roster: {
            id: player[:metadata].get(:teamsnap, :id),
            first: player[:first_name],
            last: player[:last_name],
          }
        })

        logger.info "Pushed player first=#{player[:first_name]} last=#{player[:last_name]}"

        player_id = result['roster']['id']

        player[:metadata].set(:teamsnap, id: player_id)
      end
    end

    logger.info "#{league.events.size} event(s)"

    league.events.each do |event|
      game = event[:game]

      venue   = league.find_venue_by :guid, event[:venue_guid]
      home    = league.find_team_by :guid, game[:home_guid]
      visitor = league.find_team_by :guid, game[:visitor_guid]

      # ensure existence of venue and opponent on each roster
      [home, visitor].compact.each do |team|
        team_id = team[:metadata].get(:teamsnap, :id)
        roster_id = team[:metadata].get(:teamsnap, :roster_id)

        location_id_ns = "location_id".to_sym
        location_id = venue[:metadata].get(:teamsnap, :id)

        unless pushed[:locations]["#{location_id_ns}_#{location_id}"]
          result = Teamsnap::Location.create_or_update({
            token: @token,
            division_id: division_id,
            location: {
              id: location_id,
              location_name: venue[:name],
              location_url: venue[:map_url],
              address: venue[:address_1],
              location_phone: venue[:phone],
            }
          })

          location_id = result['location']['id']
          venue[:metadata].set(:teamsnap, id: location_id)
          pushed[:locations]["#{location_id_ns}_#{location_id}"] = true

          logger.info "Pushed venue name=#{venue[:name]}"
        else

          logger.info "Skipped push venue name=#{venue[:name]}"
        end

        opponent = if team == home then visitor else home end
        opponent_team_id = opponent[:metadata].get(:teamsnap, :id)

        # opponent_id_ns = "team_#{team_id}_roster_#{roster_id}_opponent_id".to_sym
        # opponent_id = opponent[:metadata].get(:teamsnap, opponent_id_ns)

        # unless pushed[:opponents]["#{opponent_id_ns}_#{opponent_id}"]
        #   result = Teamsnap::Opponent.create_or_update({
        #     token: @token,
        #     team_id: team_id,
        #     roster_id: roster_id,
        #     opponent: {
        #       id: opponent[:metadata].get(:teamsnap, opponent_id_ns),
        #       opponent_name: opponent[:name],
        #       opponent_contact_name: opponent.coach_name,
        #     }
        #   })

        #   opponent_id = result['opponent']['id']
        #   opponent[:metadata].set(:teamsnap, opponent_id_ns => opponent_id)
        #   pushed[:opponents]["#{opponent_id_ns}_#{opponent_id}"] = true

        #   logger.info "Pushed opponent name=#{opponent[:name]}"
        # else
        #   logger.info "Skipped push opponent name=#{opponent[:name]}"
        # end

        if event[:is_practice]
          event_id_ns = "team_#{team_id}_roster_#{roster_id}_event_id".to_sym
          event_id = event[:metadata].get(:teamsnap, event_id_ns)

          unless pushed[:practices]["#{event_id_ns}_#{event_id}"]
            date_start = converted_time(event[:start_timestamp])

            result = Teamsnap::Practice.create_or_update({
              token: @token,
              team_id: team_id,
              roster_id: roster_id,
              practice: {
                id: event_id,
                event_date_start: date_start,
                location_id: location_id,
                eventname: 'Practice',
              }
            })

            event_id = result['practice']['id']
            event[:metadata].set(:teamsnap, event_id_ns => event_id)
            pushed[:practices]["#{event_id_ns}_#{event_id}"] = true

            logger.info "Push practice start_time=#{event[:start_time]}"
          else
            logger.info "Skipped push practice start_time=#{event[:start_time]}"
          end
        else
          event_id_ns = "team_#{team_id}_roster_#{roster_id}_event_id".to_sym
          event_id = event[:metadata].get(:teamsnap, event_id_ns)

          unless pushed[:games]["#{event_id_ns}_#{event_id}"]
            date_start = converted_time(event[:start_timestamp])

            if team[:guid] == event[:game][:home_guid]
              home_or_away = 1 # home
            elsif team[:guid] == event[:game][:visitor_guid]
              home_or_away = 2 # away
            else
              logger.debug "Wat? Couldn't match home/away guid."
            end

            result = Teamsnap::Game.create_or_update({
              token: @token,
              team_id: team_id,
              roster_id: roster_id,
              game: {
                id: event_id,
                event_date_start: date_start,
                location_id: location_id,
                opponent_attributes: {
                  opponent_name: opponent[:name],
                  team_id: opponent_team_id
                },
                home_or_away: home_or_away,
              }
            })

            event_id = result['game']['id']
            event[:metadata].set(:teamsnap, event_id_ns => event_id)
            pushed[:games]["#{event_id_ns}_#{event_id}"] = true

            logger.info "Push game start_time=#{event[:start_time]}"
          else
            logger.info "Skipped push game start_time=#{event[:start_time]}"
          end
        end
      end
    end

    now = Time.now
    pushes = league[:metadata].get(:teamsnap, 'pushes') || []
    pushes << {
      'created_at' => now.to_s,
      'created_at_timestamp' => now.to_i
    }
    league[:metadata].set(:teamsnap, pushes: pushes)

    logger.info '=> push complete'

    league.to_json
  end
end

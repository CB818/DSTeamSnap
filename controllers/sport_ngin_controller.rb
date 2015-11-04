class SportNginController < BabelController
  def authenticate!

    # email    = params[:email] || ENV['SPORT_NGIN_REDIRECT_URL_FOR_OAUTH_SUCCESS']
    # password = params[:password] || ENV['SPORT_NGIN_KEY']
    # @org     = params[:org] || ENV['SPORT_NGIN_ORG']
    #
    # digest = Digest::SHA256.hexdigest("#{email}#{password}#{@org}")
    #
    # @session_id = tokens.fetch(digest) do
    #   SportNgin::Login.session_id(
    #     email: email,
    #     password: password,
    #     org: @org,
    #   )
    # end
  end

  before '*' do
    content_type 'application/json'
    # if %w[
    #     seasons
    #     pull
    #     test
    #   ].include? request.path_info.split('/').last
    #   authenticate!
    # end
    # logger.info "=====================success1============"
  end

  get '/auth' do
    logger.info "=====================oAuth2 authenticating============"
    opts = {
        email: "email",
        password: "pwd",
    }
    # logger.info ENV
    SportNgin::Login.auth_code(opts)

    {"state" => "success"}.to_json
  end
  get '/facilities' do
    opts = {
        facility_id: @facility_id,
        org: @org,
    }

    facilities = []
    LeagueAthletics::Facility.all(opts).each do |facility|
      s = {}
      facility.each_pair do |key, value|
        s[key.underscore] = value
      end
      facilities << s
    end

    facilities.to_json

  end

  get '/pull' do
    if params[:season_id].blank?
      halt 400, {
        error: "Parameter `season_id` is required"
      }.to_json
    end

    seasons = LeagueAthletics::Season.all(session_id: @session_id, org: @org)

    season_found = false
    seasons.each do |season|
      if season['ID'].to_s == params[:season_id].to_s
        season_found = true
        break
      end
    end

    if seasons.size == 0
      halt 400, {
        error: "League Athletics account has 0 seasons"
      }.to_json
    end

    if !season_found
      halt 400, {
        error: "Season with id `#{params[:season_id]}` not found"
      }.to_json
    end

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
    if body["email"].blank?
      halt 400, {
          error: "Parameter `email` is required"
      }.to_json
    end
    if body["password"].blank?
      halt 400, {
          error: "Parameter `password` is required"
      }.to_json
    end
    # halt 200, league_data['league']['games'].to_json


    response = nil
    timeout = 0


    job = -> {
      do_push({
                  body: body,
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
        out << response.to_json
      end
    end
  end

  def do_pull
    mapping = {
      divisions: {},
      teams:     {},
    }

    opts = {
      session_id: @session_id,
      org: @org,
    }

    facilities = LeagueAthletics::Facility.all(opts)
    ds_venues = []

    facilities.each do |facility|
      venue = DiamondScheduler::Venue.new
      venue['name'] = facility['name']
      venue['url'] = facility['url']
      venue['map_url'] = facility['map']
      venue['address_1'] = facility['address']
      venue['city'] = facility['city']
      venue['state'] = facility['state']
      venue['zip'] = facility['zip']
      venue['phone'] = facility['phone']
      venue['metadata'].set(:league_athletics, id: facility['id'])

      ds_venues << venue
    end

    opts[:season_id] = params[:season_id]

    divisions = LeagueAthletics::Division.all(opts)
    teams = LeagueAthletics::Team.all(opts)

    divisions.each do |division|
      ds_division = DiamondScheduler::Division.new
      ds_division['name'] = division['Name']
      ds_division['metadata'].set(:league_athletics, id: division['ID'])

      mapping[:divisions][division['ID']] = ds_division
    end

    teams.each do |team|
      ds_team = DiamondScheduler::Team.new
      ds_team['name'] = team['Name']
      ds_team['custom_code'] = team['Alias']
      ds_team['division_id'] = team['DivisionID']
      ds_team['metadata'].set(:league_athletics, id: team['ID'])

      mapping[:teams][team['id']] = ds_team

      if team['DivisionID']
        if division = mapping[:divisions][team['DivisionID']]
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
      'venues' => ds_venues,
    })

    now = Time.now
    pulls = league[:metadata].get(:league_athletics, 'pulls') || []
    pulls << {
      'created_at' => now.to_s,
      'created_at_timestamp' => now.to_i
    }
    league[:metadata].set(:league_athletics, pulls: pulls)

    league.to_json
  end
  def do_push(options={})
    pushed = {
        games:     []
    }

    body = JSON.parse(options[:body])

    email = body["email"]
    password = body["password"]
    results = []
    body["league"]["games"].each do |game|
      if game["action"] == "delete"
        ds_game = DiamondScheduler::Game.new
        ds_game["GameID"] = game["ID"]
        ds_game["org"] = game["org"]
        ds_game["user"] = email
        ds_game["key"] = password
        resp = LeagueAthletics::Game.delete({game:ds_game})
        resp = JSON.parse(resp.body)
        response = {"error"=>resp['error'],
                    "result" => {
                        "status" => resp['result'],
                        "action" => "DELETE",
                        "change" => "",
                        "game" => {"ID" => game["ID"]}
                    }
        }

        results << response
      else
        ds_game = DiamondScheduler::Game.new
        ds_game["ID"] = game["ID"]
        ds_game["PlayDate"] = game["StartDate"]
        ds_game["Start"] = game["Start"]
        ds_game["Finish"] = game["Finish"]
        ds_game["Location"] = game["Facility"]["ID"]
        ds_game["teamid"] = game["teamid"]
        ds_game["opponentid"] = game["opponentid"]
        ds_game["Cancelled"] = ""
        ds_game["OtherOpponent"] = game["OtherOpponent"]
        ds_game["TravelOpponent"] = ""
        ds_game["Tournament"] = game["Tournament"]
        ds_game["SchedNote"] = ""
        ds_game["Confirmed"] = ""
        ds_game["NotifyOfficials"] = ""
        ds_game["NotifyMembers"] = ""
        ds_game["NotifyManagers"] = ""
        ds_game["org"] = game["org"]
        ds_game["user"] = email
        ds_game["key"] = password
        resp = LeagueAthletics::Game.create_or_update({game:ds_game})
        if !resp.instance_of? Nestful::Response
          resp = JSON.parse(resp)
          response = {"error"=>resp['Error'],
                      "result" => {
                          "status" => "error",
                          "action" => "",
                          "change" => "",
                          "game" => {"ID" => game["ID"]}
                      }
          }
          resp = response
        else
          resp = JSON.parse(resp.body)
          if resp['result']['status'] == "Success"
            playDate = resp['result']['game']['PLAY_DATE'][0..9]
            start = playDate + resp['result']['game']['START'][10..(resp['result']['game']['START'].length - 1)]
            finish = playDate + resp['result']['game']['FINISH'][10..(resp['result']['game']['FINISH'].length - 1)]
            resp['result']['game']['START'] = start
            resp['result']['game']['FINISH'] = finish
            resp['result']['game']['GUID'] = game['sessionID']

          end
        end

        results << resp
      end
    end
    results
  end
end

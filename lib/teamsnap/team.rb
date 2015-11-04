module Teamsnap
  class Team < Resource
    endpoint 'https://api.teamsnap.com/v2/teams'

    def self.all(opts)
      log 'all'

      authenticate!(opts)

      per = 5
      page = 1
      collect_teams = []

      begin
        response = get '', { per: per, page: page }
        log "response (page #{page}): #{response.size}"
        response.each do |team|
          collect_teams << team
        end
        page += 1
      end until response.size < per

      cache(opts).write "fetched", true

      collect_teams.each do |team|
        cache(opts).write team['team']['id'], team
      end

      collect_teams
    end

    def self.exist?(opts)
      team = opts[:team]

      all(opts) unless cache(opts).read("fetched")

      cache(opts).exist?(team[:id])
    end

    def self.find(opts)
      authenticate!(opts)

      team = opts[:team]

      return {} if team[:id].nil?
      get team[:id]
    rescue
      {}
    end

    def self.create(opts)
      authenticate!(opts)

      team = opts[:team]

      post '', { team: team }
    end

    def self.update(opts)
      authenticate!(opts)

      team = opts[:team]

      put team[:id], { team: team }
    end

    def self.create_or_update(opts)
      authenticate!(opts)

      if exist?(opts)
        update(opts)
      else
        create(opts)
      end
    end
  end
end

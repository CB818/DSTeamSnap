module LeagueAthletics
  class Facility < Resource
    endpoint 'https://api.leagueathletics.com/api/facilities'

    def self.all(opts)
      authenticate!(opts)
      resp = get
      resp["facilities"]
    end
  end
end

module LeagueAthletics
  class Season < Resource
    endpoint 'https://api.leagueathletics.com/api/seasons'

    def self.all(opts)
      authenticate!(opts)
      get
    end
  end
end

require 'nestful'
require 'json'

module LeagueAthletics
  class Login < Nestful::Resource
    endpoint 'https://api.leagueathletics.com/api/login'

    def self.session_id(opts={})
      if opts[:session_id]
        opts[:session_id]
      else
        options params: {
          :user => opts[:email],
          :key => opts[:password],
          :org => opts[:org]
        }, format: :json

        response = get

        if response.status == 200
          response['sessionID']
        end
      end
    end
  end
end

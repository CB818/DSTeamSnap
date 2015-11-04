require 'nestful'
require 'json'

module Teamsnap
  class Auth < Nestful::Resource
    endpoint 'https://api.teamsnap.com/v2/authentication/login'

    def self.token(opts={})
      if opts[:token]
        opts[:token]
      else
        options params: {
          :user => opts[:user],
          :password => opts[:password]
        }, format: :json

        response = post

        if response.status == 204
          response.headers['x-teamsnap-token']
        end
      end
    end
  end
end

require 'nestful'
require 'json'

module Teamsnap
  class User < Nestful::Resource
    endpoint 'https://api.teamsnap.com/v2/user'

    def self.all(opts)
      options headers: {
        'x-teamsnap-token' => Auth.token(opts)
      }, format: :json

      get
    end
  end
end

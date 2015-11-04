module Teamsnap
  class Sport < Nestful::Resource
    endpoint 'https://api.teamsnap.com/v2/sports'

    def self.all
      get
    end
  end
end

module Teamsnap
  class TimeZone < Nestful::Resource
    endpoint 'https://api.teamsnap.com/v2/time_zones'

    def self.all
      get
    end
  end
end

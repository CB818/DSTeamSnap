require_relative 'logging'
require 'nestful'

module SportNgin
  class BaseResource < Nestful::Resource
    include Logging
  end
end
#
require_relative 'sport_ngin/version'

require_relative 'sport_ngin/resource'
# require_relative 'sport_ngin/facility'
# require_relative 'sport_ngin/season'
# require_relative 'sport_ngin/division'
require_relative 'sport_ngin/team'
require_relative 'sport_ngin/game'
require_relative 'sport_ngin/login'

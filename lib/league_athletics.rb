require_relative 'logging'
require 'nestful'

module LeagueAthletics
  class BaseResource < Nestful::Resource
    include Logging
  end
end

require_relative 'league_athletics/version'
require_relative 'league_athletics/login'
require_relative 'league_athletics/resource'
require_relative 'league_athletics/facility'
require_relative 'league_athletics/season'
require_relative 'league_athletics/division'
require_relative 'league_athletics/team'
require_relative 'league_athletics/game'

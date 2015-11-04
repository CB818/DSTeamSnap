require_relative 'logging'
require 'nestful'

module Teamsnap
  class BaseResource < Nestful::Resource
    include Logging
  end
end

require_relative 'teamsnap/version'
require_relative 'teamsnap/exceptions'
require_relative 'teamsnap/auth'
require_relative 'teamsnap/resource'
require_relative 'teamsnap/team_resource'
require_relative 'teamsnap/division_resource'
require_relative 'teamsnap/division'
require_relative 'teamsnap/sport'
require_relative 'teamsnap/team'
require_relative 'teamsnap/roster'
require_relative 'teamsnap/opponent'
require_relative 'teamsnap/location'
require_relative 'teamsnap/timezone'
require_relative 'teamsnap/user'
require_relative 'teamsnap/game'
require_relative 'teamsnap/practice'

require_relative 'logging'
require 'nestful'

module OAuth
  class BaseResource < Nestful::Resource
    include Logging
  end
end

require_relative '../lib/logging'
require_relative '../lib/league_athletics'

require 'logger'

Logging.logger.level = Logger::WARN

RSpec.configure do |config|
  config.expect_with(:rspec) do |c|
    c.syntax = :should
  end
end

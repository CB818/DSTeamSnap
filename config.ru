$:.unshift File.expand_path("../", __FILE__)

$stdout.sync = true

require 'bundler'
require 'pp'
require 'json'
require 'digest'
require 'time'
require 'sinatra'
require 'sinatra/reloader'
require 'sinatra/async'
require 'oauth2'
require 'lib/teamsnap'
require 'lib/league_athletics'
require 'lib/ds'
require 'lib/sport_ngin'
require 'controllers/babel_controller'
require 'controllers/league_athletics_controller'
require 'controllers/teamsnap_controller'
require 'controllers/sport_ngin_controller'
require 'controllers/oauth_controller'
require 'dotenv'
Dotenv.load
map('/teamsnap') { run TeamsnapController }
map('/sportngin') { run SportNginController }
map('/oauth2') { run OAuthController }
map('/league_athletics') { run LeagueAthleticsController }
map('/') { run BabelController }

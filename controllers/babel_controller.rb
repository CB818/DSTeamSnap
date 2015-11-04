require 'open-uri'

class BabelController < Sinatra::Base
  TIME_OUT_LIMIT = 600

  register Sinatra::Async

  set :root, File.dirname(__FILE__)
  set :logging, true
  set :docs_folder, 'docs'

  configure :development do
    register Sinatra::Reloader
  end

  def cache
    @@cache ||= ActiveSupport::Cache::MemoryStore.new(
      expires_in: 60.minutes
    )
  end

  def tokens
    @@tokens ||= ActiveSupport::Cache::MemoryStore.new(
      expires_in: 10.minutes
    )
  end

  def converted_time(timestamp)
    Time.at(timestamp.to_i * 0.001).iso8601
  rescue
    nil
  end

  not_found do
    content_type 'application/json'
    { error: "Not found" }.to_json
  end

  error do
    content_type 'application/json'
    { error: env['sinatra.error'].message }.to_json
  end

  get '/docs' do
    send_file File.join(settings.docs_folder, 'index.html')
  end

  get '/uptime' do
    response = open("https://nosnch.in/aa3725e9f8") if ENV['RACK_ENV'] == 'production'
    content_type 'application/json'
    {
      since: cache.fetch(:uptime) { Time.now }
    }.to_json
  end

  get '/version' do
    content_type 'application/json'
    {
      time: Time.now.to_s,
      versions: [
        teamsnap: Teamsnap::VERSION,
        league_athletics: LeagueAthletics::VERSION,
        diamond_scheduler: DiamondScheduler::VERSION,
      ]
    }.to_json
  end

  get '/count' do
    response = nil
    timeout = 0

    job = -> {
      sleep params[:time].to_i || 1
    }

    result = -> (val) { response = val }

    EventMachine::defer job, result

    stream do |out|
      until response || timeout >= TIME_OUT_LIMIT
        sleep 1
        timeout += 1
        out << "#{timeout}, "
      end

      if timeout >= TIME_OUT_LIMIT
        out << { error: "Timeout error" }.to_json
        sleep 0.1
        EventMachine.stop
        Kernel.exit(false)
      else
        out << response
      end
    end
  end
end

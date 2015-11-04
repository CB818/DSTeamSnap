require 'nestful'
require 'json'
require 'nokogiri'
module SportNgin
  class Login < Resource
    endpoint 'https://api-user.ngin.com/oauth/authorize'

    def self.auth_code(opts={})
      client_id    = ENV['SPORT_NGIN_CLIENT_ID']
      client_secret    = ENV['SPORT_NGIN_CLIENT_SECRET']
      redirect_url    = ENV['SPORT_NGIN_REDIRECT_URL_FOR_OAUTH_SUCCESS']
      website_url    = ENV['SPORT_NGIN_WEBSITE']
      app_name    = ENV['SPORT_NGIN_APP_NAME']
      opts = {:response_type=>"code", :client_id=>client_id, :redirect_url=>redirect_url}
      client = OAuth2::Client.new(client_id, client_secret, {:site =>'https://api-user.ngin.com'})
      authorize_url = client.auth_code.authorize_url(:redirect_uri => redirect_url,:response_type => 'code')
      logger.info client.auth_code
      # endpoint authorize_url
      # response = get '', {:user=>{:login=>"diamondschedulerapi", :password=>"3e95d3f042b8cf356c84"}}
      # logger.info response.body


      # logger.info response
      # token = client.auth_code.get_token('authorization_code_value', :redirect_uri => redirect_url, :headers => {'Authorization' => 'Basic some_password'})
      # token = client.auth_code.get_token('authorization_code_value', :redirect_uri => redirect_url, :headers => {'NGIN-API-VERSION' => '0.1'})
      # logger.info token
      # # authorize_url = client.auth_code.authorize_url(:redirect_uri => redirect_url, :response_type => 'code')
      #
      # # client = OAuth2::Client.new(client_id, client_secret, :site => "https://api-user.ngin.com")
      # # client.auth_code.authorize_url(:redirect_uri => redirect_url)
      #
      # # token = client.auth_code.get_token('authorization_code_value', :redirect_uri => redirect_url, :headers => {'NGIN-API-VERSION' => '0.1'})
      #
      # logger.info "================authorize_url==============="
      # logger.info token
      # endpoint "https://api-user.ngin.com/oauth/authorize?response_type=code&client_id="+client_id+"&redirect_uri="+redirect_url



      # endpoint 'https://api-user.ngin.com/oauth/authorize'
      # response = get '', opts
      # logger.info "============Going authorize_url"
      # logger.info response.body
      # page = Nokogiri::HTML(response[0].body)
      #
      # authenticity_token = page.at('input[@name="authenticity_token"]')['value']
      #
      # endpoint 'https://api-user.ngin.com/oauth/token'
      # # token
      # # grant_type=authorization_code&client_id=[CLIENT_ID]&client_secret=[CLIENT_SECRET]&code=[AUTHORIZATION CODE FROM STEP 1]
      # opts = {:grant_type=>"authorization_code", :client_id=>client_id, :client_secret=>client_secret, :code=>authenticity_token}
      # response = post '', opts
      # # logger.info page.at('input[@name="authenticity_token"]')['value']
      # logger.info response[0].body
    end


    def self.session_id(opts={})
      if opts[:session_id]
        opts[:session_id]
      else
        options params: {
          :user => opts[:email],
          :key => opts[:password],
          :org => opts[:org]
        }, format: :json

        response = get

        if response.status == 200
          response['sessionID']
        end
      end
    end
  end
end

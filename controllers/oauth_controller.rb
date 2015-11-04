class OAuthController < BabelController
  before '*' do
    content_type 'application/json'
    # if %w[
    #     seasons
    #     pull
    #     test
    #   ].include? request.path_info.split('/').last
    #   authenticate!
    # end
  end
  get '/sportngin/callback' do
    logger.info "=====================oAuth2 callback============"
  end

end

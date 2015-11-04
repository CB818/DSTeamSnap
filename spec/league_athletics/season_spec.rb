require_relative '../spec_helper.rb'

describe 'Seasons' do
  before(:all) do
    @org = ENV['LEAGUE_ATHLETICS_ORG']
    @session_id = LeagueAthletics::Login.session_id(
      email: ENV['LEAGUE_ATHLETICS_USER'],
      password: ENV['LEAGUE_ATHLETICS_KEY'],
      org: @org,
    )
  end

  it "should retrieve a list of seasons" do
    seasons = LeagueAthletics::Season.all(
      session_id: @session_id,
      org: @org,
    )

    seasons.should_not be_nil
    seasons.size.should > 0
    seasons.each do |season|
      season['ID'].should_not be_nil
    end
  end
end

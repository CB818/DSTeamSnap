require_relative '../spec_helper.rb'

describe 'Team' do
  before(:all) do
    @org = ENV['LEAGUE_ATHLETICS_ORG']

    @session_id = LeagueAthletics::Login.session_id(
      email: ENV['LEAGUE_ATHLETICS_USER'],
      password: ENV['LEAGUE_ATHLETICS_KEY'],
      org: @org,
    )

    seasons = LeagueAthletics::Season.all(
      session_id: @session_id,
      org: @org,
    )

    @season_id = seasons.first['ID']
  end

  it "should retrieve a list of teams" do
    opts = {
      season_id: @season_id,
      session_id: @session_id,
      org: @org,
    }

    teams = LeagueAthletics::Team.all(opts)

    teams.should_not be_nil
    teams.size.should > 0

    teams.each do |team|
      team['nodeType'].should eq 'team'
      team['DivisionID'].should_not be_nil
    end
  end
end

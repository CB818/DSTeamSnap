require_relative '../spec_helper.rb'

describe 'Division' do
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

  it "should retrieve a list of divisions" do
    opts = {
      season_id: @season_id,
      session_id: @session_id,
      org: @org,
    }

    divisions = LeagueAthletics::Division.all(opts)

    divisions.should_not be_nil
    divisions.size.should > 0

    divisions.each do |division|
      division['nodeType'].should eq 'division'
    end
  end
end

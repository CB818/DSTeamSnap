require_relative '../spec_helper.rb'

describe 'Facility' do
  before(:all) do
    @org = ENV['LEAGUE_ATHLETICS_ORG']
    @session_id = LeagueAthletics::Login.session_id(
      email: ENV['LEAGUE_ATHLETICS_USER'],
      password: ENV['LEAGUE_ATHLETICS_KEY'],
      org: @org,
    )
  end

  it "should retrieve a list of facilities" do
    facilities = LeagueAthletics::Facility.all(
      session_id: @session_id,
      org: @org,
    )

    facilities.should_not be_nil
    facilities.size.should > 0

    facilities.each do |facility|
      facility['id'].should_not be_nil
    end
  end
end

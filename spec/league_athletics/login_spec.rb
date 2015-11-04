require_relative '../spec_helper.rb'

describe 'Login' do
  it "should login and return the session_id" do
    session_id = LeagueAthletics::Login.session_id(
      email: ENV['LEAGUE_ATHLETICS_USER'],
      password: ENV['LEAGUE_ATHLETICS_KEY'],
      org: ENV['LEAGUE_ATHLETICS_ORG'],
    )

    session_id.is_a?(String).should eq true
    session_id.should_not be_nil
    session_id.should_not == ''
  end
end

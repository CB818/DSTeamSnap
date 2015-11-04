module SportNgin
  class Team < Resource
    endpoint 'https://api.leagueathletics.com/api/divisions'

    def self.all(opts)
      authenticate!(opts)
      resp = get '', 'season' => opts[:season_id]

      root = resp.first

      teams = root['Teams']
      teams.map! do |team|
        team['DivisionID'] = root['ID']
        team
      end

      root['SubDivisions'].each do |d|
        teams += extract_teams(d)
      end

      teams
    end

  private

    def self.extract_teams(division)
      teams = division['Teams']
      teams.map! do |team|
        team['DivisionID'] = division['ID']
        team
      end
      division['SubDivisions'].each do |d|
        teams += extract_teams(d)
      end
      teams
    end
  end
end

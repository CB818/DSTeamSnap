module LeagueAthletics
  class Division < Resource
    endpoint 'https://api.leagueathletics.com/api/divisions'

    def self.all(opts)
      authenticate!(opts)
      resp = get '', 'season' => opts[:season_id]

      root = resp.first
      divisions = []

      root['SubDivisions'].each do |d|
        d['metadata'] = DiamondScheduler::Metadata.new
        divisions << d
        divisions += extract_divisions(d)
      end

      divisions
    end

    def self.all_nested(opts)
      authenticate!(opts)
      resp = get '', 'season' => opts[:season_id]

      root = resp.first
      divisions = []

      root['SubDivisions'].each do |d|
        d['metadata'] = DiamondScheduler::Metadata.new


        # d['subdivisions'] = traverse_divisions(d)
        divisions << d
      end

      divisions
    end

  private

    def self.extract_divisions(division)
      # logger.info division['ID']
      # logger.info division['Name']
      # logger.info division['metadata']
      divisions = []
      division['SubDivisions'].each do |d|
        d['metadata'] = DiamondScheduler::Metadata.new
        d['metadata'].set(:league_athletics, parent_division:{
            id: division['ID'],
            name: division['Name'],
            parent_division: division['metadata'].get(:league_athletics, "parent_division")
        })
        # logger.info d['metadata']
        divisions << d
        divisions += extract_divisions(d)
      end
      divisions
    end
    def self.traverse_divisions(division)
      # logger.info division['ID']
      # logger.info division['Name']
      # logger.info division['metadata']
      divisions = []
      division['SubDivisions'].each do |d|
        d['metadata'] = DiamondScheduler::Metadata.new
        d['metadata'].set(:league_athletics, parent_division:{
            id: division['ID'],
            name: division['Name'],
            parent_division: division['metadata'].get(:league_athletics, "parent_division")
        })
        # logger.info d['metadata']
        d['sub_divisions'] = traverse_divisions(d)
        divisions << d

      end
      divisions
    end
  end
end

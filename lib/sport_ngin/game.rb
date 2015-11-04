module SportNgin
  class Game < Resource
    endpoint 'https://api.leagueathletics.com/api/schedules/update'
    options :timeout => 3
    def self.delete(opts)
      endpoint 'https://api.leagueathletics.com/api/schedules/delete'
      authenticate!(opts)

      game = opts[:game]
      response = post '', game
      response
    end
    def self.create_or_update(opts)
      endpoint 'https://api.leagueathletics.com/api/schedules/update'
      authenticate!(opts)

      begin
      game = opts[:game]
      response = post '', game, {:timeout => 2}
      logger.info "=====================success============"
      rescue Exception => e
        logger.info "=====================no response============"
        response = {"error"=>"No response"}.to_json
      end
      response
    end

  private

    def self.extract_divisions(division)
      divisions = []
      division['SubDivisions'].each do |d|
        divisions << d
        divisions += extract_divisions(d)
      end
      divisions
    end
  end
end

module DiamondScheduler
  class Division < Base
    # required :guid, :name, :is_across_division, :is_out_of_league, :abbreviation

    def after_init
      self[:teams] ||= []
      self[:teams] = self[:teams].map { |team| Team.new(team) }
    end

    def teams
      self[:teams] || []
    end
  end
end

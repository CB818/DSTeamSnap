module DiamondScheduler
  class Team < Base
    def after_init
      self[:players] ||= []
      self[:coaches] ||= []

      self[:players].map! { |player| Player.new(player) }
      self[:coaches].map! { |coach| Coach.new(coach) }
    end

    def coach_name
      if coach = self[:coaches].first
        "#{coach[:first_name]} #{coach[:last_name]}"
      else
        ""
      end
    end
  end
end

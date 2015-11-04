module DiamondScheduler
  class Event < Base
    def after_init
      self[:game] = Game.new(self[:game])
    end
  end
end

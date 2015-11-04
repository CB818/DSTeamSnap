module DiamondScheduler
  class Metadata < ActiveSupport::HashWithIndifferentAccess
    def initialize(constructor={})
      if constructor.is_a? String
        begin
          constructor = JSON.load constructor
        rescue
          constructor = {}
        end
      end

      super constructor
    end

    def set(namespace, *extras)
      self[namespace] = self[namespace] || ActiveSupport::HashWithIndifferentAccess.new

      extras.each do |hash|
        hash.each_pair do |key, value|
          self[namespace][key] = value
        end
      end
    end

    def get(namespace, key)
      return nil unless self[namespace]
      self[namespace][key]
    end

    def as_json(options={})
      JSON.dump super(options)
    end
  end
end

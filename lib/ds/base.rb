require 'securerandom'

module DiamondScheduler
  class Base < ActiveSupport::HashWithIndifferentAccess
    def initialize(constructor = {})
      super constructor

      unless self[:guid]
        self[:guid] = SecureRandom.uuid.upcase
      end

      metadata_init
      after_init
    end

    def required(fields)
      @required_fields = [fields].flatten
    end

    def metadata_init
      self[:metadata] = Metadata.new(self[:metadata])
    end

    def after_init

    end
  end
end

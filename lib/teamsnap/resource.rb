require 'json'

module Teamsnap
  class Resource < BaseResource
    class << self
      def log(msg)
        logger.info "[#{Time.now.to_s[0,19]}] LOG   #{resource_name} -- #{msg}"
      end

      def cache_namespace(opts)
        Auth.token(opts)
      end

      def resource_name
        self.to_s.downcase.split('::').last
      end

      def authenticate!(opts)
        log 'authenticate!'

        if token = Auth.token(opts)
          options headers: {
            'x-teamsnap-token' => token
          }, format: :json
          log "x-teamsnap-token: #{token}"
        else
          log 'authentication problem'
        end
      end

      def cache(opts)
        @cache ||= begin
          log "creating cache for #{resource_name}"
          ActiveSupport::Cache::MemoryStore.new(
            expires_in: 3.minutes
          )
        end

        if namespace = cache_namespace(opts)
          if @cache.options[:namespace] != namespace
            log "switching cache namespace = #{namespace}"
          end
          @cache.options[:namespace] = namespace
        end

        @cache
      end
    end
  end
end

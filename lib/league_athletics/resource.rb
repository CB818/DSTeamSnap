require 'json'

module LeagueAthletics
  class Resource < BaseResource
    class << self
      def log(msg)
        logger.info "[#{Time.now.to_s[0,19]}] LOG   #{resource_name} -- #{msg}"
      end

      def cache_namespace(opts)
        Login.session_id(opts)
      end

      def resource_name
        self.to_s.downcase.split('::').last
      end

      def authenticate!(opts)
        log 'authenticate!'
        params = {}

        if opts[:session_id]
          if session_id = Login.session_id(opts)
            params.merge! 'sessionID' => session_id
          end
        end

        params.merge!('org' => opts[:org]) if opts[:org]

        options params: params
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

module Teamsnap
  class DivisionResource < Resource
    endpoint 'https://api.teamsnap.com/v2/divisions'

    def self.cache_namespace(opts)
      "#{Auth.token(opts)}_#{build_url(:cache, opts)}"
    end

    def self.build_url(type, opts)
      division_id   = opts[:division_id]

      if [:update, :find].include? type
        id = opts[resource_name.to_sym][:id]
        log "build_url: #{division_id}/#{resource_name.pluralize}/#{id}"
        "#{division_id}/#{resource_name.pluralize}/#{id}"
      else
        log "build_url: #{division_id}/#{resource_name.pluralize}"
        "#{division_id}/#{resource_name.pluralize}"
      end
    end

    def self.build_obj(opts)
      obj = opts[resource_name.to_sym]

      { resource_name.to_sym => obj }
    end

    def self.all(opts)
      log "all"

      authenticate!(opts)

      response = get build_url(:all, opts)

      cache(opts).write "fetched", true

      response.each do |obj|
        # log "fetched: #{obj.inspect}"
        log "write: #{obj[resource_name]['id']}"
        cache(opts).write obj[resource_name]['id'], obj
      end

      response
    end

    def self.exist?(opts)
      log "exist?"

      all(opts) unless cache(opts).read("fetched")

      log "read: #{build_obj(opts)[resource_name.to_sym][:id]}"

      cache(opts).exist?(build_obj(opts)[resource_name.to_sym][:id])
    end

    def self.different?(opts)
      log "different?"

      update_obj = build_obj(opts)[resource_name.to_sym]
      curr_obj   = cache(opts).read(update_obj[:id])[resource_name]

      update_obj.each_pair do |key, value|
        if curr_obj.has_key?(key)
          if value != curr_obj[key]
            log "difference found"
            log "update: ", { key => value }
            log "curr: ", { key => curr_obj[key] }

            return true
          end
        end
      end

      false
    end

    def self.find(opts)
      authenticate!(opts)

      get build_url(:find, opts)
    rescue
      {}
    end

    def self.create(opts)
      log "create"
      authenticate!(opts)

      post build_url(:create, opts), build_obj(opts)
    end

    def self.update(opts)
      log "update"
      authenticate!(opts)

      location  = opts[:location]

      put build_url(:update, opts), build_obj(opts)
    end

    def self.create_or_update(opts)
      log "create_or_update"

      authenticate!(opts)

      if exist?(opts)
        if different?(opts)
          update(opts)
        else
          log "not different"
          cache(opts).read(build_obj(opts)[resource_name.to_sym][:id])
        end
      else
        create(opts)
      end
    end
  end
end

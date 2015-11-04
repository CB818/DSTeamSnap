module Teamsnap
  class Division < Resource
    endpoint 'https://api.teamsnap.com/v2/divisions'

    def self.all(opts, flatten=true)
      log 'all'

      authenticate!(opts)

      response = get

      cache(opts).write "fetched", true

      response.each do |division|
        _cache_division opts, division['division']
      end

      if flatten
        response.map do |division|
          _extract_divisions division['division'], nil
        end.flatten
      else
        response
      end
    end

    def self._extract_divisions(division, parent_name=nil, depth=0)
      divisions = division['divisions'] || []
      if parent_name && depth > 2
        division['name'] = "#{parent_name} > #{division['name']}"
      end
      division.delete 'divisions'
      [division] + divisions.map { |d| _extract_divisions(d, division['name'], depth + 1) }
    end

    def self._cache_division(opts, division)
      log "cache division: #{division['id']} / #{division['name']}"
      cache(opts).write division['id'], division
      division['divisions'].each do |d|
        _cache_division(opts, d)
      end
    end

    def self.exist?(opts)
      division = opts[:division]

      all(opts) unless cache(opts).read("fetched")

      cache(opts).exist?(division[:id])
    end

    def self.find(opts)
      authenticate!(opts)

      division = opts[:division]

      return {} if division[:id].nil?
      get division[:id]
    rescue
      {}
    end

    def self.create(opts)
      authenticate!(opts)

      division = opts[:division]

      post '', { division: division }
    end

    def self.update(opts)
      authenticate!(opts)

      division = opts[:division]

      put division[:id], { division: division }
    end

    def self.create_or_update(opts)
      authenticate!(opts)

      if exist?(opts)
        update(opts)
      else
        create(opts)
      end
    end
  end
end

module DiamondScheduler
  class League < ActiveSupport::HashWithIndifferentAccess
    def initialize(constructor={})
      super constructor

      now = Time.now

      self[:league]               ||= {}
      self[:created_at]           ||= now.to_s
      self[:created_at_timestamp] ||= now.to_i
      self[:version_number]       ||= APP_VERSION
      self[:build_number]         ||= APP_BUILD
      self[:league_external_id]   ||= '-1'

      self[:metadata] = Metadata.new(self[:metadata])

      divisions = self[:league]['divisions'] || []
      calendars = self[:league]['calendars'] || []
      venues    = self[:league]['venues'] || []
      persons   = self[:league]['persons'] || []
      events    = self[:league]['events'] || []

      self[:league] = {
        divisions: divisions.map { |d| Division.new(d) },
        calendars: calendars.map { |c| Calendar.new(c) },
        venues: venues.map { |v| Venue.new(v) },
        persons: persons.map { |p| Person.new(p) },
        events: events.map { |e| Event.new(e) }
      }
    end

    def create_or_update(type, attributes)
      self[:league][type] ||= []
      division = Division.new(attributes)
      self[:league][type] << division
      division
    end

    def find_by(items, prop, value)
      items.each do |item|
        if item[prop] == value
          return item
        end
      end
      nil
    end

    def find_team_by(prop, value); find_by(teams, prop, value); end
    def find_venue_by(prop, value); find_by(venues, prop, value); end

    def divisions
      self[:league][:divisions] || []
    end

    def teams
      divisions.inject([]) do |collect, division|
        collect += division[:teams]
      end
    end

    def players
      teams.inject([]) do |collect, team|
        collect += team[:players]
      end
    end

    def venues
      self[:league][:venues] || []
    end

    def calendars
      self[:league][:calendars] || []
    end

    def persons
      self[:league][:persons] || []
    end

    def events
      self[:league][:events] || []
    end
  end
end

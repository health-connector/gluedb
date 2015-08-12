module ActiveSupport
  class TimeZone
    def parse(str, now=now())
      parts = Date._parse(str, false)
      return if parts.empty?

      time = Time.utc(
        parts.fetch(:year, now.year),
        parts.fetch(:mon, now.month),
        parts.fetch(:mday, now.day),
        parts.fetch(:hour, 0),
        parts.fetch(:min, 0),
        parts.fetch(:sec, 0),
        parts.fetch(:sec_fraction, 0) * 1000000
      )

      if parts[:offset]
        TimeWithZone.new(time - parts[:offset], self)
      else
        TimeWithZone.new(nil, self, time)
      end
    end
  end
end

module Mongoid
  module Persistence
    module Atomic
      module Operation
        def path(field = field())
          position = document.atomic_position
          position.blank? ? field : "#{position}.#{field}"
        end
      end
    end
  end
end

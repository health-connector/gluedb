module Caches
  module Mongoid
    class SinglePropertyLookup
      def initialize(kls, projected_property)
        map = kls.collection.aggregate(
          {"$project" => {selected_property: "$#{projected_property}"}}
        )
        @records = map.inject({}) do |accum, c|
          accum[c["_id"]] = c['selected_property']
          accum
        end
      end

      def lookup(m_id)
        @records[m_id]
      end
    end
  end
end

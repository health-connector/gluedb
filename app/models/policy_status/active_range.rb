module PolicyStatus
  class ActiveRange
    def initialize(start_d, end_d)
      @start_date = start_d
      @end_date = end_d
    end

    def query
      pol_ids = Policy.collection.raw_aggregate([
        {"$match" => {
          :eg_id => { "$not" => /DC0.{32}/ }
        }},
        {"$unwind" => "$enrollees"},
        {"$match" => {"enrollees.rel_code" => "self", "enrollees.coverage_start" => {"$gt" => convert_date(@start_date), "$lt" => convert_date(@end_date)}}},
        {"$project" => {"cancelled" => {"$eq" => ["$enrollees.coverage_start", "$enrollees.coverage_end"]}}},
        {"$match" => {"cancelled" => false}}
      ]).map { |pol| pol['_id'] }.uniq
      {"id" => {"$in" => pol_ids}}
    end

    def results
      Policy.where(query)
    end

    def convert_date(d)
      Time.new(d.year, d.month, d.day, 0,0,0)
    end
  end
end

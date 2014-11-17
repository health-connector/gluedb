module PolicyStatus
  class Active

    def initialize(as_of_date, other_params = {})
      @as_of_date = as_of_date
      @other_params = other_params
    end

    def query
      active_as_of_expression.merge(@other_params)
    end

    def active_as_of_expression
      target_date = @as_of_date
      {
        "$or" => [
          { :aasm_state => { "$ne" => "canceled"},
            :eg_id => { "$not" => /DC0.{32}/ },
            :enrollees => {"$elemMatch" => {
              :rel_code => "self",
              :coverage_start => {"$lte" => target_date},
              :coverage_end => {"$gt" => target_date}
            }}},
            { :aasm_state => { "$ne" => "canceled"},
              :eg_id => { "$not" => /DC0.{32}/ },
              :enrollees => {"$elemMatch" => {
                :rel_code => "self",
                :coverage_start => {"$lte" => target_date},
                :coverage_end => {"$exists" => false}
              }}},
              { :aasm_state => { "$ne" => "canceled"},
                :eg_id => { "$not" => /DC0.{32}/ },
                :enrollees => {"$elemMatch" => {
                  :rel_code => "self",
                  :coverage_start => {"$lte" => target_date},
                  :coverage_end => nil
                }}}
        ]
      }
    end

    def self.as_of(this_date, options = {})
      self.new(this_date, options)
    end

    def self.today(options = {})
      self.new(Date.today, options) 
    end
  end
end

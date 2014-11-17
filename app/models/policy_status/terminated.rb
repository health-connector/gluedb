module PolicyStatus
  class Terminated

    def initialize(s_date, e_date, other_params = {})
      @start_date = s_date
      @end_date = e_date
      @other_params = other_params
    end

    def query
      expression.merge(@other_params)
    end

    def expression
      {
        :aasm_state => { "$ne" => "canceled" },
        :enrollees => { "$elemMatch" => {
          :rel_code => "self",
          :coverage_start => { "$ne" => nil },
          :coverage_end => {"$lte" => @end_date, "$gte" => @start_date}
        }
        }
      }
    end

    def self.during(start_date, end_date, options = {})
      self.new(start_date, end_date, options)
    end
  end
end

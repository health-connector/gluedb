module BulkCancelTerms
  class Csv
    attr_reader :errors

    def initialize(req, out_csv)
      @request = req
      @errors = []
      @csv = out_csv
    end

    def no_subscriber_id(details = {})
      @errors << "No subscriber_id found #{details[:subscriber]} does not exist"
    end

    def no_such_policy(details = {})
      @errors << "Policy #{details[:policy_id]} does not exist"
    end

    def policy_inactive(details = {})
      @errors << "Policy #{details[:policy_id]} was already inactive"
    end

    def end_date_invalid(details = {})
      @errors <<  "End date of #{details[:end_date]} is invalid"
    end

    def fail(details = {})
      @csv << (@request.to_a + ["#{details[:subscriber]}"] + ["error", @errors.join])
    end

    def success(details = {})
      @csv << (@request.to_a + ["#{details[:subscriber]}"] + ["success"])
    end
  end
end

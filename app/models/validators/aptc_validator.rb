module Validators
  class AptcValidator
    def initialize(change_request, plan, listener)
      @change_request = change_request
      @plan = plan
      @listener = listener
    end

    def validate
      return true if @change_request.respond_to?(:employer)
      credit = @change_request.credit.round(2)
      pre_tot = @change_request.premium_amount_total.round(2)
      expected_max = (pre_tot * @plan.ehb).round(2)
      if credit > expected_max
        @listener.aptc_too_large({:expected => expected_max, :provided => credit})
        return false
      end
      true
    end
  end
end

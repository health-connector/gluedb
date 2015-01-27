module Parsers::Xml::Enrollment
  class ShopEnrollee < ::Parsers::Xml::Enrollment::Enrollee
    def initialize(parser, employer)
      @employer = employer
      super(parser)
      @benefit_begin_date = benefit_begin_date
    end

    class BeginDateOutsidePlanYearsError < StandardError

    end

    def rate_period_date
      raise BeginDateOutsidePlanYearsError, "Benefit begin date of #{@benefit_begin_date} does not fall into any plan years of #{@employer.name} (fein: #{@employer.fein})" if @employer.plan_year_of(@benefit_begin_date).nil?
      @employer.plan_year_of(@benefit_begin_date).start_date
    end
  end
end

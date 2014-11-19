module Parsers::Xml::Enrollment
  class ShopEnrollee < Enrollee
    def initialize(parser, employer)
      @employer = employer
      super(parser)
    end

    def rate_period_date
      @employer.plan_year_start ||= @employer.plan_years.last.start_date
    end
  end
end

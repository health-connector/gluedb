module Parsers::Xml::Enrollment
  class ShopEnrollee < ::Parsers::Xml::Enrollment::Enrollee
    def initialize(parser, employer)
      @employer = employer
      super(parser)
      @benefit_begin_date = benefit_begin_date
    end

    def rate_period_date
      @employer.plan_year_of(@benefit_begin_date).start_date
    end
  end
end

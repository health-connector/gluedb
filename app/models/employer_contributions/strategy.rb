module EmployerContributions
  class Strategy
    include Mongoid::Document

    belongs_to :plan_year
  end
end

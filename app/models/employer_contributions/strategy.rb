module EmployerContributions
  class Strategy
    include Mongoid::Document

    belongs_to :plan_year

    validates_presence_of :plan_year_id
  end
end

module HandleEnrollmentEvent
  class PlanDetails
    include Virtus.model

    attribute :hios_id, String
    attribute :active_year, String


    def found_plan
      @found_plan ||= Plan.where(:hios_plan_id => hios_id, :year => active_year.to_i).first
    end
  end
end

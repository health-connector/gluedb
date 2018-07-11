require "rails_helper"

describe EmployerEvents::EventNames, :dbclean => :after_each do

  context "for events" do
    let(:constant_white_list) { EmployerEvents::EventNames::EVENT_WHITELIST }
    let(:renewal_successful_event) { EmployerEvents::EventNames::RENEWAL_SUCCESSFUL_EVENT }
    let(:mid_plan_year_event_name) { "benefit_coverage_mid_plan_year_initial_eligible" }
    let(:renewal_carrier_dropped_event_name) { "benefit_coverage_renewal_carrier_dropped" }
    let(:benefit_coverage_period_terminated_voluntary) { "benefit_coverage_period_terminated_voluntary" }
    let(:benefit_coverage_renewal_application_eligible) { "benefit_coverage_renewal_application_eligible" }

    it "should have a EVENT_WHITELIST as a constant" do
      expect(EmployerEvents::EventNames.constants).to include(:EVENT_WHITELIST)
    end

    it "should have a EXCLUDED_FOR_NOW as a constant" do
      expect(EmployerEvents::EventNames.constants).to include(:EXCLUDED_FOR_NOW)
    end

    it "includes event for mid_plan_year" do
      expect(constant_white_list).to include(mid_plan_year_event_name)
    end

    it "includes event for renewal_carrier_dropped" do
      expect(constant_white_list).to include(renewal_carrier_dropped_event_name)
    end

    it "should have renewal_successful_event" do
      expect(renewal_successful_event).to eq benefit_coverage_renewal_application_eligible
    end

    it "should not include benefit_coverage_period_terminated_voluntary as an event under white_list" do
      expect(constant_white_list).not_to include(benefit_coverage_period_terminated_voluntary)
    end
  end
end

require "rails_helper"

describe EmployerEvents::EnrollmentEventTrigger, "given:
- an employer event for Employer 1 that is benefit_coverage_initial_application_eligible
- an employer event for Employer 2 that is benefit_coverage_renewal_application_eligible
- an employer event for Employer 3 that is benefit_coverage_renewal_carrier_dropped
" do

  let(:employer_1_id) { "321938741238974" }
  let(:employer_2_id) { "23874782897397243" }
  let(:employer_3_id) { "98789779234" }
  let(:employer_1_event_name) { "benefit_coverage_initial_application_eligible" }
  let(:employer_2_event_name) { "benefit_coverage_renewal_application_eligible" }
  let(:employer_3_event_name) { "benefit_coverage_renewal_carrier_dropped" }

  let(:event_1) { instance_double(EmployerEvent, :employer_id => employer_1_id, :event_name => employer_1_event_name) }
  let(:event_2) { instance_double(EmployerEvent, :employer_id => employer_2_id, :event_name => employer_2_event_name) }
  let(:event_3) { instance_double(EmployerEvent, :employer_id => employer_3_id, :event_name => employer_3_event_name) }

  before :each do
    subject.add(event_1)
    subject.add(event_2)
    subject.add(event_3)
  end

  it "includes employer 1 in the list of initial employer ids" do
    expect(subject.initial_employer_ids).to include(employer_1_id)
  end
  it "includes employer 2 in the list of renewal employer ids" do
    expect(subject.renewal_employer_ids).to include(employer_2_id)
  end
  it "includes employer 3 in the list of renewal employer ids" do
    expect(subject.renewal_employer_ids).to include(employer_3_id)
  end
end

describe EmployerEvents::EnrollmentEventTrigger, "which excludes all events except:
- benefit_coverage_initial_application_eligible
- benefit_coverage_renewal_application_eligible
- benefit_coverage_renewal_carrier_dropped
" do

  ((EmployerEvents::EventNames::EVENT_WHITELIST + EmployerEvents::EventNames::EXCLUDED_FOR_NOW) -
    [EmployerEvents::EventNames::FIRST_TIME_EMPLOYER_EVENT_NAME] -
    [EmployerEvents::EventNames::RENEWAL_SUCCESSFUL_EVENT] -
    [EmployerEvents::EventNames::RENEWAL_CARRIER_CHANGE_EVENT]
  ).each do |employer_event_name|
    describe "given an employer event with name #{employer_event_name}" do
      let(:employer_id) { "1348987234" }
      let(:employer_event) { instance_double(EmployerEvent, :employer_id => employer_id, :event_name => employer_event_name) }

      before :each do
        subject.add(employer_event)
      end

      it "does not include the initial id for that employer" do
        expect(subject.initial_employer_ids).not_to include(employer_id)
      end

      it "does not include the renewal id for that employer" do
        expect(subject.renewal_employer_ids).not_to include(employer_id)
      end
    end
  end
end

describe EmployerEvents::EnrollmentEventTrigger, "given:
- an employer event for Employer 1 that is benefit_coverage_initial_application_eligible
- an employer event for Employer 2 that is benefit_coverage_renewal_application_eligible
" do

  let(:employer_1_id) { "321938741238974" }
  let(:employer_2_id) { "23874782897397243" }
  let(:employer_1_fein) { "321938741" }
  let(:employer_2_fein) { "238747828" }
  let(:employer_1_event_name) { "benefit_coverage_initial_application_eligible" }
  let(:employer_2_event_name) { "benefit_coverage_renewal_application_eligible" }

  let(:event_1) { instance_double(EmployerEvent, :employer_id => employer_1_id, :event_name => employer_1_event_name) }
  let(:event_2) { instance_double(EmployerEvent, :employer_id => employer_2_id, :event_name => employer_2_event_name) }
  let(:connection) { double }
  let(:channel) { double }
  let(:exchange) { double }
  let(:exchange_name) { "blah" }
  let(:initial_plan_year_start) { Date.today.beginning_of_month }
  let(:renewal_plan_year_start) { Date.today.beginning_of_month }
  let(:old_plan_year_start) { (Date.today - 1.year).beginning_of_month }
  let(:initial_plan_year) { instance_double(PlanYear, :start_date => initial_plan_year_start) }
  let(:old_plan_year) { instance_double(PlanYear, :start_date => old_plan_year_start) }
  let(:renewal_plan_year) { instance_double(PlanYear, :start_date => renewal_plan_year_start) }
  let(:employer_1) { instance_double(Employer, :plan_years => [initial_plan_year], :fein => employer_1_fein) }
  let(:employer_2) { instance_double(Employer, :plan_years => [old_plan_year, renewal_plan_year], :fein => employer_2_fein) }

  before :each do
    subject.add(event_1)
    subject.add(event_2)
    allow(Amqp::ConfirmedPublisher).to receive(:with_confirmed_channel).with(connection).and_yield(channel)
    allow(Employer).to receive(:by_hbx_id).with(employer_1_id).and_return([employer_1])
    allow(Employer).to receive(:by_hbx_id).with(employer_2_id).and_return([employer_2])
    allow(ExchangeInformation).to receive(:event_publish_exchange).and_return(exchange_name)
    allow(channel).to receive(:fanout).with(exchange_name, {:durable => true}).and_return(exchange)
    allow(exchange).to receive(:publish).with("", {
      routing_key: "info.events.employer.binder_enrollments_transmission_authorized",
      headers: {
        "fein" => employer_1_fein,
        "effective_on" => initial_plan_year_start.strftime("%Y-%m-%d")
      }
    })
    allow(exchange).to receive(:publish).with("", {
      routing_key: "info.events.employer.renewal_transmission_authorized",
      headers: {
        "fein" => employer_2_fein,
        "effective_on" => renewal_plan_year_start.strftime("%Y-%m-%d")
      }
    })
  end

  it "transmits using the start date of the initial plan year for employer 1" do
    expect(exchange).to receive(:publish).with("", {
      routing_key: "info.events.employer.binder_enrollments_transmission_authorized",
      headers: {
        "fein" => employer_1_fein,
        "effective_on" => initial_plan_year_start.strftime("%Y-%m-%d")
      }
    })
    subject.publish(connection) 
  end

  it "transmits using the start date of the renewal plan year for employer 2" do
    expect(exchange).to receive(:publish).with("", {
      routing_key: "info.events.employer.renewal_transmission_authorized",
      headers: {
        "fein" => employer_2_fein,
        "effective_on" => renewal_plan_year_start.strftime("%Y-%m-%d")
      }
    })
    subject.publish(connection) 
  end
end

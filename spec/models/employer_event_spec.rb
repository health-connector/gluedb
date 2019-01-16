require "rails_helper"

# TODO: Refactor the EmployerEvent class - this spec demonstrates how
#       EmployerEvent has far too many responsibilties
describe EmployerEvent, "generating carrier files using .with_digest_payloads", dbclean: :after_each do
  let(:employer_id_1) { "some employer id" }
  let(:employer_id_2) { "some other employer id" }

  let(:connection) { double }
  let(:the_time) { double }
  let(:carrier_1) { instance_double(Carrier) }
  let(:carrier_2) { instance_double(Carrier) }
  let(:carrier_file_1) { instance_double(EmployerEvents::CarrierFile, rendered_employers: [employer_id_1], empty?: false) }
  let(:carrier_file_2) { instance_double(EmployerEvents::CarrierFile, rendered_employers: [employer_id_2], empty?: false) }
  let(:event_1) { EmployerEvent.new(:employer_id => employer_id_1) }
  let(:event_2) { EmployerEvent.new(:employer_id => employer_id_2) }
  let(:event_renderer_1) { instance_double(EmployerEvents::Renderer) }
  let(:event_renderer_2) { instance_double(EmployerEvents::Renderer) }
  let(:edi_notifier) { instance_double(EmployerEvents::EmployerEdiContactInfoNotificationSet) }
  let(:carrier_1_render_xml) { double }
  let(:carrier_2_render_xml) { double }
  let(:carrier_1_render_result) { ["carrier_1_file_name", carrier_1_render_xml] }
  let(:carrier_2_render_result) { ["carrier_2_file_name", carrier_2_render_xml] }

  before(:each) do
    allow(Carrier).to receive(:all).and_return([carrier_1, carrier_2])
    allow(EmployerEvents::CarrierFile).to receive(:new).
      with(carrier_1).and_return(carrier_file_1)
    allow(EmployerEvents::CarrierFile).to receive(:new).
      with(carrier_2).and_return(carrier_file_2)
    allow(EmployerEvent).to receive(:ordered_events_since_time).and_return([event_1, event_2])
    allow(EmployerEvents::Renderer).to receive(:new).with(event_1).and_return(event_renderer_1)
    allow(EmployerEvents::Renderer).to receive(:new).with(event_2).and_return(event_renderer_2)
    allow(carrier_file_1).to receive(:render_event_using).with(event_renderer_1, event_1)
    allow(carrier_file_2).to receive(:render_event_using).with(event_renderer_1, event_1)
    allow(carrier_file_1).to receive(:render_event_using).with(event_renderer_2, event_2)
    allow(carrier_file_2).to receive(:render_event_using).with(event_renderer_2, event_2)
    allow(EmployerEvents::EmployerEdiContactInfoNotificationSet).to receive(:new).
      with(connection).and_return(edi_notifier)
    allow(carrier_file_1).to receive(:result).and_return(carrier_1_render_result)
    allow(carrier_file_2).to receive(:result).and_return(carrier_2_render_result)
    allow(edi_notifier).to receive(:notify_for_outstanding_employers_from_list).with([employer_id_1])
    allow(edi_notifier).to receive(:notify_for_outstanding_employers_from_list).with([employer_id_2])
  end

  it "sends a set of edi update notifications only for employers which had events rendered for a carrier" do
    expect(edi_notifier).to receive(:notify_for_outstanding_employers_from_list).with([employer_id_1])
    expect(edi_notifier).to receive(:notify_for_outstanding_employers_from_list).with([employer_id_2])
    EmployerEvent.with_digest_payloads(connection, the_time) do |a_carrier_payload|
    end
  end

  it "yields the rendered carrier xmls" do
    carrier_payloads = []
    EmployerEvent.with_digest_payloads(connection, the_time) do |a_carrier_payload|
      carrier_payloads << a_carrier_payload
    end
    expect(carrier_payloads).to include(carrier_1_render_xml)
    expect(carrier_payloads).to include(carrier_2_render_xml)
  end

  describe 'Employer event with trading partner publishable flag' do

    let!(:plan_year_start_date) { Date.new(2017, 4, 1) }
    let!(:new_plan_year_end_date) { Date.new(2017, 12, 31) }
    let!(:plan_year_end_date) {Date.new(2018, 03, 31)}
    let(:event_name) { "benefit_coverage_period_terminated_voluntary" }
    let(:event_time) { Time.now }
    let(:event) { double}
    let!(:employer) { FactoryGirl.create(:employer)}
    let!(:plan_year) { FactoryGirl.create(:plan_year, start_date: plan_year_start_date, end_date: plan_year_end_date, employer_id: employer.id)}

    let(:employer_event_xml) do
      <<-XML_CODE
       <organization xmlns="http://openhbx.org/api/terms/1.0">
       <id>
       <id>#{employer.hbx_id}</id>
       </id>
       <name>#{employer.name}</name>
       <dba>#{employer.dba}</name>
       <fein>#{employer.fein}</fein>
       <employer_profile>
         <plan_years>
           <plan_year>
             <plan_year_start>#{plan_year_start_date.strftime("%Y%m%d")}</plan_year_start>
             <plan_year_end>#{new_plan_year_end_date.strftime("%Y%m%d")}</plan_year_end>
           </plan_year>
         </plan_years>
       </employer_profile>
       </organization>
      XML_CODE
    end

    before do
      employer.plan_years << plan_year
      EmployerEvent.store_and_yield_deleted(employer.hbx_id, event_name, event_time, employer_event_xml, trading_partner_publishable) do |event |
      end
    end

    context "with trading_partner_publishable = true" do

      let(:trading_partner_publishable) { true }

      it "should create employer event"  do
        expect(EmployerEvent.all.count).to eq 1
      end

      it "should update employer plan year end date." do
        plan_year.reload
        expect(plan_year.end_date).to eql new_plan_year_end_date
      end
    end

    context "with trading_partner_publishable = false" do

      let(:trading_partner_publishable) { false }

      it "should not create employer event."  do
        expect(EmployerEvent.all.count).to eq 0
      end

      it "should update employer plan year end date"  do
        plan_year.reload
        expect(plan_year.end_date).to eql new_plan_year_end_date
      end
    end
  end
end
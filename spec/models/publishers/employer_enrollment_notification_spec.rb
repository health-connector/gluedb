require "rails_helper"

describe Publishers::EmployerEnrollmentNotification do
  let(:xml_ns) do
    { :cv => "http://openhbx.org/api/terms/1.0" }
  end

  describe "#publish_edi" do

    let!(:amqp_connection) { double(close: true) }
    let!(:event_xml) { double }
    let(:trading_partner_edi_publisher) { Publishers::TradingPartnerEdi.new(amqp_connection, event_xml) }
    let(:event_xml) { double }
    let(:hbx_enrollment_id) { double }
    let(:employer) { double(hbx_id: '123') }
    let(:cv_publish_errors) { {:error_message => "errors_message"} }
    let!(:policy) { FactoryGirl.create(:policy) }
    let!(:publish_error){ Publishers::EmployerEnrollmentNotification::PublishError.new("EDI Codec CV2 Publish Failed", {:error_message => cv_publish_errors[:error_message]})}
    let!(:edi_publish_sucess){ Publishers::EmployerEnrollmentNotification::PublishError.new("EDI Codec CV2/Leagcy CV1 Published Sucessfully", {:error_message => cv_publish_errors[:error_message]})}
    subject { Publishers::EmployerEnrollmentNotification.new(employer) }

    before :each do
      allow(subject).to receive(:employer_policies).and_return([policy])
      allow(subject).to receive(:render_cv).with(policy).and_return(event_xml)
      allow(Publishers::TradingPartnerEdi).to receive(:new).with(amqp_connection, event_xml).and_return(trading_partner_edi_publisher)
      allow(AmqpConnectionProvider).to receive(:start_connection).and_return(amqp_connection)
      allow(trading_partner_edi_publisher).to receive(:errors).and_return(cv_publish_errors)
    end

    describe "which fails to publish trading partner edi" do

      before :each do
        allow(trading_partner_edi_publisher).to receive(:publish).and_return(false)
      end

      it "returns false" do
        publish_status, publish_errors = subject.publish_edi(amqp_connection, event_xml, policy)
        expect(publish_status).to be_falsey
      end

      it "returns the publishing errors" do
        publish_status, publish_errors = subject.publish_edi(amqp_connection, event_xml, policy)
        expect(publish_errors).to eq publish_error
      end
    end

    describe "which publishes trading partner edi" , dbclean: :after_each do

      let(:legacy_cv_publisher) { double }
      let(:legacy_cv_errors) { {:error_message => "errors_message"} }
      let!(:cv_publish_error){ Publishers::EmployerEnrollmentNotification::PublishError.new("CV1 Publish Failed", {:error_message => legacy_cv_errors[:error_message]})}

      before :each do
        allow(trading_partner_edi_publisher).to receive(:publish).and_return(true)
        allow(Publishers::TradingPartnerLegacyCv).to receive(:new).with(amqp_connection, event_xml, policy.eg_id, employer.hbx_id).and_return(legacy_cv_publisher)
      end

      describe "but fails to publish the legacy cv", dbclean: :after_each do
        before :each do
          allow(legacy_cv_publisher).to receive(:publish).and_return(false)
          allow(legacy_cv_publisher).to receive(:errors).and_return(legacy_cv_errors)
        end

        it "returns false" do
          publish_status, _publish_errors = subject.publish_edi(amqp_connection, event_xml, policy)
          expect(publish_status).to be_falsey
        end

        it "returns the publishing errors" do
          _publish_status, publish_errors = subject.publish_edi(amqp_connection, event_xml, policy)
          expect(publish_errors).to eq cv_publish_error
        end
      end

      describe "and publishes the legacy cv" do
        before :each do
          allow(legacy_cv_publisher).to receive(:publish).and_return(true)
          allow(legacy_cv_publisher).to receive(:errors).and_return(legacy_cv_errors)
        end

        it "returns true" do
          publish_status, _publish_errors = subject.publish_edi(amqp_connection, event_xml, policy)
          expect(publish_status).to be_truthy
        end
      end
    end

    describe "#process_enrollments_for_edi", dbclean: :after_each do

      context "edi_publish success",dbclean: :after_each do

        before :each do
          allow(subject).to receive(:publish_edi).with(amqp_connection, event_xml, policy).and_return([true, edi_publish_sucess])
        end

        it "when sucessfully published edi should create sucess record in enrollemt action" do
          subject.process_enrollments_for_edi
          expect(EnrollmentAction::EnrollmentActionIssue.all.count).to eq 1
          expect(EnrollmentAction::EnrollmentActionIssue.all.first.error_message).to eq "EDI Codec CV2/Leagcy CV1 Published Sucessfully"
        end
      end

      context "edi_publish fail", dbclean: :after_each do

        before :each do
          allow(subject).to receive(:publish_edi).with(amqp_connection, event_xml, policy).and_return([true, publish_error])
        end

        it "when fail to publish edi should create failure record in enrollemt action" do
          subject.process_enrollments_for_edi
          expect(EnrollmentAction::EnrollmentActionIssue.all.count).to eq 1
          expect(EnrollmentAction::EnrollmentActionIssue.all.first.error_message).to eq "EDI Codec CV2 Publish Failed"
        end
      end
    end
  end

  describe "#employer_policies", dbclean: :after_each do
    let!(:employer) { FactoryGirl.create(:employer) }
    let!(:enrollees) { policy.enrollees.update_all(coverage_start:Date.today.beginning_of_month, coverage_end:nil) }
    let!(:update_enrollees) { united_health_care_policy.enrollees.update_all(coverage_end:nil) }
    let(:united_carrier_profile) {CarrierProfile.new(fein: '12222', profile_name: "UHIC_SHP",requires_employer_updates_on_enrollments:false)}
    let(:carrier_profile) {CarrierProfile.new(fein: '12222', profile_name: "THPP_SHP")}
    let(:carrier) { FactoryGirl.create(:carrier, requires_employer_updates_on_enrollments:true, carrier_profiles:[carrier_profile]) }
    let(:united_health_carrier) { FactoryGirl.create(:carrier, carrier_profiles:[united_carrier_profile]) }
    let!(:policy) { FactoryGirl.create(:policy, employer: employer, aasm_state: "submitted",carrier:carrier) }
    let!(:united_health_care_policy) { FactoryGirl.create(:policy, employer: employer, aasm_state: "submitted",carrier:united_health_carrier) }
    let!(:person) {FactoryGirl.create(:person)}
    let!(:first_enrollee) { policy.enrollees[0] }
    let!(:second_enrollee) { policy.enrollees[1] }
    let(:subscriber_enrollee_id) { policy.subscriber.m_id }

    subject { Publishers::EmployerEnrollmentNotification.new(employer) }

    context "should return tufts policies for employer" do

      it "returns false" do
        expect(subject.employer_policies.count).to eq 1
        expect(subject.employer_policies.first).to eq policy
      end
    end

    context "#render_cv" do
      context "should render CV for policy" do
        let(:subscriber_member_id) { person.authority_member_id }

        before :each do
          allow(first_enrollee).to receive(:person).and_return(person)
          allow(second_enrollee).to receive(:person).and_return(person)
          render_result = subject.render_cv(policy)
          @doc = Nokogiri::XML(render_result.gsub("\n", ""))
        end

        it "includes only one affected member" do
          expect(@doc.xpath('//cv:affected_members/cv:affected_member', xml_ns).count).to eq(1)
        end

        it "includes the subscriber in the list of affected members" do
          affected_member_ids = @doc.xpath('//cv:affected_members/cv:affected_member/cv:member/cv:id/cv:id', xml_ns).map do |node|
            node.content.split("#").last
          end
          expect(affected_member_ids).to include(subscriber_member_id)
        end

        it "includes market type" do
          expect(@doc.at_xpath('//cv:market', xml_ns).text).to eq "urn:openhbx:terms:v1:aca_marketplace#shop"
        end

        it "includes type of enrollment" do
          expect(@doc.at_xpath('//cv:type', xml_ns).text,).to eq "urn:openhbx:terms:v1:enrollment#change_member_communication_numbers"
        end
      end
    end
  end
end

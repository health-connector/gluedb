require "rails_helper"

describe Publishers::EmployerEnrollmentNotification do
  describe "#publish_edi" do

    let!(:amqp_connection) { double }
    let!(:event_xml) { double }
    let(:trading_partner_edi_publisher) { Publishers::TradingPartnerEdi.new(amqp_connection, event_xml) }
    let(:event_xml) { double }
    let(:hbx_enrollment_id) { double }
    let(:employer) { double(hbx_id: '123') }
    let(:cv_publish_errors_hash) { double }
    let(:cv_publish_errors) { double(:to_hash => cv_publish_errors_hash) }
    let(:policy) { FactoryGirl.create(:policy) }

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
        expect(publish_errors).to eq cv_publish_errors_hash
      end
    end

    describe "which publishes trading partner edi" do
      let(:legacy_cv_publisher) { double }

      before :each do
        allow(trading_partner_edi_publisher).to receive(:publish).and_return(true)
        allow(Publishers::TradingPartnerLegacyCv).to receive(:new).with(amqp_connection, event_xml, policy.eg_id, employer.hbx_id).and_return(legacy_cv_publisher)
      end

      describe "but fails to publish the legacy cv" do
        let(:legacy_cv_errors_hash) { double }
        let(:legacy_cv_errors) { double(:to_hash => legacy_cv_errors_hash) }


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
          expect(publish_errors).to eq legacy_cv_errors_hash
        end
      end

      describe "and publishes the legacy cv" do
        before :each do
          allow(legacy_cv_publisher).to receive(:publish).and_return(true)
        end

        it "returns true" do
          publish_status, _publish_errors = subject.publish_edi(amqp_connection, event_xml, policy)
          expect(publish_status).to be_truthy
        end
      end
    end
  end

  describe "#employer_policies", dbclean: :after_each do
    let!(:employer) { FactoryGirl.create(:employer) }
    let!(:enrollees) { policy.enrollees.update_all(coverage_end:nil) }
    let!(:update_enrollees) { united_health_care_policy.enrollees.update_all(coverage_end:nil) }
    let(:united_carrier_profile) {CarrierProfile.new(fein: '12222', profile_name: "UHIC_SHP",requires_employer_updates_on_enrollments:false)}
    let(:carrier_profile) {CarrierProfile.new(fein: '12222', profile_name: "THPP_SHP",requires_employer_updates_on_enrollments:true)}
    let(:carrier) { FactoryGirl.create(:carrier, carrier_profiles:[carrier_profile]) }
    let(:united_health_carrier) { FactoryGirl.create(:carrier, carrier_profiles:[united_carrier_profile]) }
    let!(:policy) { FactoryGirl.create(:policy, employer: employer, aasm_state: "submitted",carrier:carrier) }
    let!(:united_health_care_policy) { FactoryGirl.create(:policy, employer: employer, aasm_state: "submitted",carrier:united_health_carrier) }
    let!(:person) {FactoryGirl.create(:person)}
    let!(:first_enrollee) {policy.enrollees[0]}
    let!(:second_enrollee) {policy.enrollees[1]}

    subject { Publishers::EmployerEnrollmentNotification.new(employer) }

    context "should return tufts policies for employer" do

      it "returns false" do
        expect(subject.employer_policies.count).to eq 1
        expect(subject.employer_policies.first).to eq policy
      end
    end

    context "#render_cv", dbclean: :after_each do
      context "should render CV for policy" do
        before :each do
          allow(first_enrollee).to receive(:person).and_return(person)
          allow(second_enrollee).to receive(:person).and_return(person)
          render_result = subject.render_cv(policy)
          @doc = Nokogiri::HTML(render_result.gsub("\n", ""))
        end

        it "should include market type" do
          expect(@doc.at_xpath('//market').text).to eq "urn:openhbx:terms:v1:aca_marketplace#shop"
        end

        it "should include type of enrollment" do
          expect(@doc.at_xpath('//type').text).to eq "urn:openhbx:terms:v1:enrollment#initial"
        end
      end
    end
  end
end
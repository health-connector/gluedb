require "rails_helper"

describe ChangeSets::PersonDobChangeSet do

  describe "with an updated dob" do
    let(:member) { instance_double("::Member", :dob => old_dob) }
    let(:person_resource) { instance_double("::RemoteResources::IndividualResource", :hbx_member_id => hbx_member_id, :dob => new_dob) }
    let(:policies_to_notify) { [policy_to_notify] }
    let(:policy_to_notify) { instance_double("Policy", :eg_id => policy_hbx_id, :active_member_ids => hbx_member_ids, :is_shop? => true, :enrollees => []) }
    let(:hbx_member_ids) { [hbx_member_id, hbx_member_id_2] }
    let(:policy_hbx_id) { "some randome_policy id whatevers" }
    let(:hbx_member_id) { "some random member id wahtever" }
    let(:hbx_member_id_2) { "some other, differently random member id wahtever" }
    let(:policy_cv) { "some policy cv data" }
    let(:policy_serializer) { instance_double("::CanonicalVocabulary::MaintenanceSerializer") }
    let(:cv_publisher) { instance_double(::Services::NfpPublisher) }
    let(:identity_change_transmitter) { instance_double(::ChangeSets::IdentityChangeTransmitter, :publish => nil) }
    let(:affected_member) { instance_double(::BusinessProcesses::AffectedMember) }

    let(:old_dob) { "01/01/1960" }

    let(:new_dob) { "01/01/1970" }

    let(:old_dob_values) {
      {"member_id"=>"some random member id wahtever", "dob" => old_dob}
    }
    subject { ChangeSets::PersonDobChangeSet.new }

    before :each do
      allow(::BusinessProcesses::AffectedMember).to receive(:new).with(
       { :policy => policy_to_notify, "member_id" => hbx_member_id, "dob" => old_dob }
      ).and_return(affected_member)
      allow(::ChangeSets::IdentityChangeTransmitter).to receive(:new).with(
        affected_member,
        policy_to_notify,
        "urn:openhbx:terms:v1:enrollment#change_member_name_or_demographic"
      ).and_return(identity_change_transmitter)
      allow(member).to receive(:update_attributes).with({"dob" => new_dob}).and_return(update_result)
      allow(subject).to receive(:update_enrollments_for).and_return true
    end

    describe "with an invalid new dob" do
      let(:update_result) { false }
      it "should fail to process the update" do
        expect(subject.perform_update(member, person_resource, policies_to_notify)).to eq false
      end
    end

    describe "with a valid new dob" do
      let(:update_result) { true }
      before :each do
        allow(::CanonicalVocabulary::IdInfoSerializer).to receive(:new).with(
          policy_to_notify, "change", "change_in_identifying_data_elements", [hbx_member_id], hbx_member_ids, [old_dob_values]
        ).and_return(policy_serializer)
        allow(policy_serializer).to receive(:serialize).and_return(policy_cv)
        allow(::Services::NfpPublisher).to receive(:new).and_return(cv_publisher)
      end

      it "should update the person" do
        allow(cv_publisher).to receive(:publish).with(true, "#{policy_hbx_id}.xml", policy_cv)
        expect(subject.perform_update(member, person_resource, policies_to_notify)).to eq true
      end

      it "should send out policy notifications" do
        expect(cv_publisher).to receive(:publish).with(true, "#{policy_hbx_id}.xml", policy_cv)
        subject.perform_update(member, person_resource, policies_to_notify)
      end
    end
  end

  describe 'test' do
    let(:member) { FactoryGirl.build :member }
    let(:person) { FactoryGirl.create :person, members: [ member ] }

    let(:example_data) {
      o_file = File.open(File.join(Rails.root, "spec/data/remote_resources/individual.xml"))
      data = o_file.read
      o_file.close
      data
    }

    let(:remote_resource) { RemoteResources::IndividualResource.parse(example_data, :single => true) }
    let(:changeset) { ::ChangeSets::IndividualChangeSet.new(remote_resource) }

    before :each do
      allow(person).to receive(:members).and_return(double(detect: member))
      allow(::Queries::PersonByHbxIdQuery).to receive(:new).with("18941339").and_return(double(execute: person))
      allow(changeset).to receive(:home_address_changed?).and_return(false)
      allow(changeset).to receive(:mailing_address_changed?).and_return(false)
      allow(changeset).to receive(:names_changed?).and_return(false)
      allow(changeset).to receive(:ssn_changed?).and_return(false)
      allow(changeset).to receive(:gender_changed?).and_return(false)
      allow(changeset).to receive(:home_email_changed?).and_return(false)
      allow(changeset).to receive(:work_email_changed?).and_return(false)
      allow(changeset).to receive(:home_phone_changed?).and_return(false)
      allow(changeset).to receive(:work_phone_changed?).and_return(false)
      allow(changeset).to receive(:mobile_phone_changed?).and_return(false)
      allow(Amqp::Requestor).to receive(:default).and_return(instance_double(Amqp::Requestor))
    end

    it 'should work' do
      expect(changeset.dob_changed?).to be_truthy
    end

    it 'should work too' do
      expect(changeset.process_first_edi_change).to be_truthy
    end
  end

  describe '#update_enrollments_for' do

      let(:policy) { instance_double(Policy, :enrollees => [enrollee], :hbx_enrollment_ids => [policy_id]) }
      let(:enrollee) { instance_double(Enrollee, :m_id => member.hbx_member_id) }
      let(:dob_changeset) { ::ChangeSets::PersonDobChangeSet.new }
      let(:member) { FactoryGirl.build :member }
      let(:person) { FactoryGirl.create :person, members: [ member ] }
      let(:requestor) { instance_double(Amqp::Requestor) }
      let(:policy_id) { "SOME POLICY ID" }
      let(:enrollment_event_resource) { instance_double(RemoteResources::EnrollmentEventResource, :body => enrollment_xml_string) }
      let(:enrollment_xml_string) { double }
      let(:enrollment_event) { instance_double(::Openhbx::Cv2::EnrollmentEvent, :header => enrollment_event_header) }
      let(:enrollment_event_header) { instance_double(::Openhbx::Cv2::EnrollmentEventHeader, :submitted_timestamp => 1) }
      let(:policy_cv) { instance_double(::Openhbx::Cv2::Policy, :enrollees => [xml_enrollee], :policy_enrollment => policy_enrollment) }
      let(:policy_enrollment) { instance_double(::Openhbx::Cv2::PolicyEnrollment, policy_enrollment_properties) }
      let(:xml_enrollee) { instance_double(::Openhbx::Cv2::Enrollee, :member => xml_member, :benefit => xml_benefit) }
      let(:xml_member) { instance_double(Openhbx::Cv2::EnrolleeMember, :id => member.hbx_member_id) }
      let(:xml_benefit) { instance_double(Openhbx::Cv2::EnrolleeBenefit, :premium_amount => new_enrollee_premium) }
      let(:new_enrollee_premium_string) { "123.45" }
      let(:new_enrollee_premium) { BigDecimal.new("123.45") }
      let(:new_pre_amt_tot) { double }
      let(:new_tot_res_amt) { double }

      before :each do
        allow(Amqp::Requestor).to receive(:default).and_return(requestor)
        allow(dob_changeset).to receive(:enrollment_event_cv_for).with(enrollment_xml_string).and_return(enrollment_event)
        allow(dob_changeset).to receive(:extract_policy).with(enrollment_event).and_return(policy_cv)
        allow(RemoteResources::EnrollmentEventResource).to receive(:retrieve).with(requestor, policy_id).and_return(["200", enrollment_event_resource])
        allow(enrollee).to receive(:update_attributes!).with({pre_amt: new_enrollee_premium})
        allow(policy).to receive(:pre_amt_tot=).with(new_pre_amt_tot)
        allow(policy).to receive(:tot_res_amt=).with(new_tot_res_amt)
        allow(policy).to receive(:save!)
      end

    describe "for a shop policy" do
      let(:shop_policy_enrollment) { instance_double(Openhbx::Cv2::PolicyEnrollmentShopMarket, total_employer_responsible_amount: tot_emp_res_amt) } 
      let(:tot_emp_res_amt) { "62.78" }

      let(:policy_enrollment_properties) do
        {
          shop_market: shop_policy_enrollment,
          total_responsible_amount: new_tot_res_amt,
          premium_total_amount: new_pre_amt_tot
        }
      end

      before :each do
        allow(policy).to receive(:tot_emp_res_amt=).with(tot_emp_res_amt)
      end

      it "updates the shop-based totals of the policy" do
        expect(policy).to receive(:tot_emp_res_amt=).with(tot_emp_res_amt)
        dob_changeset.update_enrollments_for([policy])
      end

      it "updates the totals of the policy" do
        expect(policy).to receive(:pre_amt_tot=).with(new_pre_amt_tot)
        expect(policy).to receive(:tot_res_amt=).with(new_tot_res_amt)
        dob_changeset.update_enrollments_for([policy])
      end

      it "updates the premium amount of the enrollee" do
        expect(enrollee).to receive(:update_attributes!).with({pre_amt: new_enrollee_premium})
        dob_changeset.update_enrollments_for([policy])
      end

      it 'updates policies' do
        expect(dob_changeset.update_enrollments_for([policy])).to be_truthy
      end
    end

    describe "for an ivl policy" do
      let(:individual_policy_enrollment) { instance_double(Openhbx::Cv2::PolicyEnrollmentIndividualMarket, :applied_aptc_amount => applied_aptc) }
      let(:applied_aptc) { "56.23" }

      let(:policy_enrollment_properties) do
        {
          shop_market: nil,
          individual_market: individual_policy_enrollment,
          total_responsible_amount: new_tot_res_amt,
          premium_total_amount: new_pre_amt_tot
        }
      end

      before :each do
        allow(policy).to receive(:applied_aptc=).with(applied_aptc)
      end

      it "updates the ivl-based totals of the policy" do
        expect(policy).to receive(:applied_aptc=).with(applied_aptc)
        dob_changeset.update_enrollments_for([policy])
      end

      it "updates the totals of the policy" do
        expect(policy).to receive(:pre_amt_tot=).with(new_pre_amt_tot)
        expect(policy).to receive(:tot_res_amt=).with(new_tot_res_amt)
        dob_changeset.update_enrollments_for([policy])
      end

      it "updates the premium amount of the enrollee" do
        expect(enrollee).to receive(:update_attributes!).with({pre_amt: new_enrollee_premium})
        dob_changeset.update_enrollments_for([policy])
      end

      it 'updates policies' do
        expect(dob_changeset.update_enrollments_for([policy])).to be_truthy
      end
    end
  end
end

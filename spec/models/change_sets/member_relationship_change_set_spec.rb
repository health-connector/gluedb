require "rails_helper"

describe ChangeSets::MemberRelationshipChangeSet, "given:
- an IVL policy which has no matching relationships
- an IVL policy which has matching relationships" do
  let(:member) { instance_double(Member, :hbx_member_id => hbx_member_id) }
  let(:person_resource) { instance_double(::RemoteResources::IndividualResource, :hbx_member_id => hbx_member_id, :relationships => [relationship_1, relationship_2]) }
  let(:possible_policies) { [matching_policy, non_matching_policy] }
  let(:matching_policy) { instance_double(Policy, :active_member_ids => hbx_member_ids, :is_shop? => false, :enrollees => [subscriber_enrollee, dependent_enrollee], :subscriber => subscriber_enrollee) }
  let(:non_matching_policy) { instance_double(Policy, :active_member_ids => [hbx_member_id, hbx_member_id_2, hbx_member_id_3], :is_shop? => false, :enrollees => [subscriber_enrollee, non_matching_dependent_enrollee, other_unrelated_enrollee], :subscriber => subscriber_enrollee ) }
  let(:hbx_member_ids) { [hbx_member_id, hbx_member_id_2] }
  let(:hbx_member_id) { "some random member id wahtever" }
  let(:hbx_member_id_2) { "some other, differently random member id wahtever" }
  let(:hbx_member_id_3) { "some third, unrelated person" }
  let(:subscriber_enrollee) { instance_double(Enrollee, :m_id => hbx_member_id, :rel_code => "self", :subscriber? => true) }
  let(:dependent_enrollee) { instance_double(Enrollee, :m_id => hbx_member_id_2, :rel_code => "child", :subscriber? => false) }
  let(:non_matching_dependent_enrollee) { instance_double(Enrollee, :m_id => hbx_member_id_2, :rel_code => "spouse", :subscriber? => false) }
  let(:other_unrelated_enrollee) { instance_double(Enrollee, :m_id => hbx_member_id_3, :rel_code => "ward", :subscriber? => false) }
  let(:relationship_1) do
    instance_double(
      ::RemoteResources::PersonRelationship,
      :subject_individual_member_id => hbx_member_id_2,
      :object_individual_member_id => hbx_member_id,
      :glue_relationship => "spouse"
    )
  end

  let(:relationship_2) do
    instance_double(
      ::RemoteResources::PersonRelationship,
      :subject_individual_member_id => hbx_member_id_3,
      :object_individual_member_id => hbx_member_id_2,
      :glue_relationship => "child"
    )
  end

  subject { ChangeSets::MemberRelationshipChangeSet.new }

  it "is applicable" do
    expect(subject.applicable?(member, person_resource, possible_policies)).to be_truthy
  end

  it "has the correct policies in the list of applicable policies" do
    expect(subject.select_applicable_policies(member, person_resource, possible_policies)).to include(matching_policy)
    expect(subject.select_applicable_policies(member, person_resource, possible_policies)).not_to include(non_matching_policy)
  end
end

describe ChangeSets::MemberRelationshipChangeSet, "given:
- an applicable policy where ONLY the spouse has the wrong relatiohship
- an applicable policy where ONLY the child has the wrong relatiohship
" do

  let(:member) { instance_double(Member, :hbx_member_id => hbx_member_id) }
  let(:person_resource) { instance_double(::RemoteResources::IndividualResource, :hbx_member_id => hbx_member_id, :relationships => [relationship_1, relationship_2]) }
  let(:wrong_spouse_policy) { instance_double(Policy, :active_member_ids => hbx_member_ids, :is_shop? => false, :enrollees => [subscriber_enrollee, wrong_spouse_enrollee, correct_child_enrollee], :subscriber => subscriber_enrollee) }
  let(:wrong_child_policy) { instance_double(Policy, :active_member_ids => hbx_member_ids, :is_shop? => false, :enrollees => [subscriber_enrollee, correct_spouse_enrollee, wrong_child_enrollee], :subscriber => subscriber_enrollee ) }
  let(:applicable_policies) { [wrong_spouse_policy, wrong_child_policy] }
  let(:hbx_member_ids) { [hbx_member_id, hbx_member_id_2, hbx_member_id_3] }
  let(:hbx_member_id) { "some random member id wahtever" }
  let(:hbx_member_id_2) { "some spouse id" }
  let(:hbx_member_id_3) { "some child id" }
  let(:subscriber_enrollee) { instance_double(Enrollee, :m_id => hbx_member_id, :rel_code => "self", :subscriber? => true) }
  let(:correct_spouse_enrollee) { instance_double(Enrollee, :m_id => hbx_member_id_2, :rel_code => "spouse", :subscriber? => false) }
  let(:wrong_spouse_enrollee) { instance_double(Enrollee, :m_id => hbx_member_id_2, :rel_code => "child", :subscriber? => false) }
  let(:correct_child_enrollee) { instance_double(Enrollee, :m_id => hbx_member_id_3, :rel_code => "child", :subscriber? => false) }
  let(:wrong_child_enrollee) { instance_double(Enrollee, :m_id => hbx_member_id_3, :rel_code => "ward", :subscriber? => false) }
  let(:relationship_1) do
    instance_double(
      ::RemoteResources::PersonRelationship,
      :subject_individual_member_id => hbx_member_id_2,
      :object_individual_member_id => hbx_member_id,
      :glue_relationship => "spouse"
    )
  end

  let(:relationship_2) do
    instance_double(
      ::RemoteResources::PersonRelationship,
      :subject_individual_member_id => hbx_member_id_3,
      :object_individual_member_id => hbx_member_id,
      :glue_relationship => "child"
    )
  end

  let(:relationship_change_uri) { "urn:openhbx:terms:v1:enrollment#change_relationship" }

  subject { ChangeSets::MemberRelationshipChangeSet.new }

  before :each do
    subject.applicable_policies = applicable_policies
    allow(wrong_spouse_enrollee).to receive(:update_attributes!).with({:rel_code => "spouse"})
    allow(wrong_child_enrollee).to receive(:update_attributes!).with({:rel_code => "child"})
    allow(subject).to receive(:notify_policies).with("change", "personnel_data", hbx_member_id_2, [wrong_spouse_policy], relationship_change_uri)
    allow(subject).to receive(:notify_policies).with("change", "personnel_data", hbx_member_id_3, [wrong_child_policy], relationship_change_uri)
  end

  it "updates the incorrect spouse enrollee" do
    expect(wrong_spouse_enrollee).to receive(:update_attributes!).with({:rel_code => "spouse"})
    subject.perform_update(member, person_resource, applicable_policies)
  end

  it "updates the incorrect child enrollee" do
    expect(wrong_child_enrollee).to receive(:update_attributes!).with({:rel_code => "child"})
    subject.perform_update(member, person_resource, applicable_policies)
  end

  it "transmits the update spouse enrollment" do
    expect(subject).to receive(:notify_policies).with("change", "personnel_data", hbx_member_id_2, [wrong_spouse_policy], relationship_change_uri)
    subject.perform_update(member, person_resource, applicable_policies)
  end

  it "transmits the updated child enrollment" do
    expect(subject).to receive(:notify_policies).with("change", "personnel_data", hbx_member_id_3, [wrong_child_policy], relationship_change_uri)
    subject.perform_update(member, person_resource, applicable_policies)
  end

end

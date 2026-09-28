module TradingPartnerTransformsSpecHelpers
  # The enrollment_event partial looks up a real Person per enrollee by
  # m_id. FactoryGirl's :policy does not create one, so every policy used
  # to render a real CV needs this bridge, matching the existing pattern
  # in spec/data_migrations/transform_xmls_spec.rb.
  def bridge_person_for(policy)
    # A shop policy needs distinct relationship codes, the cv1 schema
    # rejects two members both marked self.
    policy.enrollees.each_with_index do |en, index|
      en.update_attributes!(:rel_code => "spouse") if index > 0 && en.rel_code == "self"
    end
    policy.enrollees.each do |en|
      person = FactoryGirl.create(:person)
      # :person's default members can coincidentally share an
      # hbx_member_id with this enrollee, since both sequences start
      # at 1. Clear them so authority_member unambiguously resolves
      # to the one member that actually matches this enrollee.
      person.members.destroy_all
      person.members.create!(:hbx_member_id => en.m_id, :gender => "female", :dob => Date.new(1980, 1, 1), :ssn => "123456789")
      person.update_attributes!(:authority_member_id => en.m_id)
    end
    policy.reload
  end
end

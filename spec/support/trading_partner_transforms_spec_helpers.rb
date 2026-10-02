module TradingPartnerTransformsSpecHelpers
  # Creates a Person for each enrollee so the enrollment event CV can render.
  def bridge_person_for(policy)
    # The CV1 schema rejects two members with rel_code self.
    policy.enrollees.each_with_index do |en, index|
      en.update_attributes!(:rel_code => "spouse") if index > 0 && en.rel_code == "self"
    end
    policy.enrollees.each do |en|
      person = FactoryGirl.create(:person)
      # Drop the factory's default members so authority_member resolves to this enrollee.
      person.members.destroy_all
      person.members.create!(:hbx_member_id => en.m_id, :gender => "female", :dob => Date.new(1980, 1, 1), :ssn => "123456789")
      person.update_attributes!(:authority_member_id => en.m_id)
    end
    policy.reload
  end
end

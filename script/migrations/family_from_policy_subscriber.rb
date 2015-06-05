class FamilyFromPolicySubscriber
  def initialize(person, policies)
    @person = person
    @policies = policies
    @family_builder = FamilyBuilder.new(nil, nil)
  end

  def create
    persons = @policies.flat_map(&:enrollees).map(&:person).uniq #persons across all policies

    persons.each do |person|

      family_member_hash = {
          is_coverage_applicant: true,
          is_consent_applicant: true,
          person: person
      }

      family_member_hash[:is_primary_applicant] = true if person.id.eql?(@person.id)
      @family_builder.add_family_member(family_member_hash)
    end

    @policies.each do |policy|
      @family_builder.add_hbx_enrollment(policy)
    end

    @family_builder.add_coverage_household
    @family_builder.family
  end

  def save
    @family_builder.save
    @family_builder.add_irsgroups
    @family_builder.save
    @family_builder.family
  end
end
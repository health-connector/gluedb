#This class will create a family for a policy which does not belong to any any family
class FamilyForPolicyCreator

  def initialize(policy)
    @family_builder = FamilyBuilder.new(nil, nil)
    @policy = policy
  end

  def create
    @policy.enrollees.each do |enrollee|

      family_member_hash = {
          is_coverage_applicant: true,
          is_consent_applicant: true,
          person: enrollee.person
      }

      family_member_hash[:is_primary_applicant] = true if enrollee.subscriber?
      @family_builder.add_family_member(family_member_hash)
    end

    @family_builder.add_coverage_household
    @family_builder.add_hbx_enrollment(@policy)
    @family_builder.family
  end

  def save
    @family_builder.save
    @family_builder.add_irsgroups
    @family_builder.save
    @family_builder
  end
end
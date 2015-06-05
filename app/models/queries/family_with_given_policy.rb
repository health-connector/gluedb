class FamilyWithGivenPolicy
  def initialize(policy_id)
    @policy_id = policy_id
  end

  def execute
    family = Family.all.to_a.detect do |family|
      family.primary_applicant.person.policies.map(&:id).include? @policy_id
    end
  end
end
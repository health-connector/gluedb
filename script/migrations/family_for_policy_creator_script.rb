require File.join(Rails.root, "script", "migrations", "family_for_policy_creator")
require File.join(Rails.root, "app", "models", "queries", "policies_with_no_hbx_enrollment")

policies = Queries::PoliciesWithNoHbxEnrollments.new.execute

policies = policies.select do |policy|
  policy.enrollees.length > 2
end

family_for_policy_creator = FamilyForPolicyCreator.new(policies.first)
family_for_policy_creator.create
puts family_for_policy_creator.save.inspect
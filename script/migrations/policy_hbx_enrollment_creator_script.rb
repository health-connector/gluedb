require File.join(Rails.root, "script", "migrations", "policy_hbx_enrollment_creator")
require File.join(Rails.root, "app", "models", "queries", "policies_with_no_hbx_enrollment")
require File.join(Rails.root, "app", "models", "queries", "family_with_given_policy")

@@logger = Logger.new("#{Rails.root}/log/policy_hbx_enrollment_creator_#{Time.now.to_s.gsub(' ','')}.log")

policies = Queries::PoliciesWithNoFamilies.new.execute

policies.each do |policy|
  begin
    family = FamilyWithGivenPolicy.new(policy.id).execute

    if family.nil?
      @@logger.info "#{DateTime.now.to_s} policy.id:#{policy.id} has no family to belong to"
      next
    end

    family = PolicyHbxEnrollmentCreator.new(policy, family).create

  rescue Exception=>e
    @@logger.info "#{DateTime.now.to_s} policy.id:#{policy.id} error message:#{e.message}"
  end
end


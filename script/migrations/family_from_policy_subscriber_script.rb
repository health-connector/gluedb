require File.join(Rails.root, "script", "migrations", "family_from_policy_subscriber")
require File.join(Rails.root, "app", "models", "queries", "policies_with_no_families")

$logger = Logger.new("#{Rails.root}/log/family_for_orphan_policies_#{Time.now.to_s.gsub(' ', '')}.log")
$error_dir = File.join(Rails.root, "log", "errors_family_for_orphan_policies_#{Time.now.to_s.gsub(' ', '')}")

policies_with_no_families = Queries::PoliciesWithNoFamilies.new.execute

$logger.info "policies_with_no_families: #{policies_with_no_families.length}"

policies_2014_with_no_families = policies_with_no_families.select do |policy|
  next if policy.subscriber.nil?
  policy.subscriber.coverage_start > Date.new(2013, 12, 31) && policy.subscriber.coverage_start < Date.new(2014, 12, 31)
end

$logger.info "policies_2014_with_no_families: #{policies_2014_with_no_families.length}"

policy_groups = policies_2014_with_no_families.group_by do |policy| policy.subscriber.person.id end

$logger.info "policy_groups: #{policy_groups.length}"

policy_groups.each do |person_id, policies|
  begin
  person = Person.find(person_id)
  family_from_policy_subscriber = FamilyFromPolicySubscriber.new(person, policies)
  family_from_policy_subscriber.create
  family_from_policy_subscriber.save
  rescue Exception=>e
    $logger.info "ERROR: #{e.message}"
  end
end

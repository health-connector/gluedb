require File.join(Rails.root, "script", "migrations", "family_for_policy_creator")
require File.join(Rails.root, "app", "models", "queries", "policies_with_no_families")

$logger = Logger.new("#{Rails.root}/log/family_for_orphan_policies_#{Time.now.to_s.gsub(' ', '')}.log")
$error_dir = File.join(Rails.root, "log", "errros_family_for_orphan_policies_#{Time.now.to_s.gsub(' ', '')}")


plans = Plan.where({:metal_level => {"$not" => /catastrophic/i}, :coverage_type => /health/i}).map(&:id)
policies_2014 = PolicyStatus::Active.between(Date.new(2013, 12, 31), Date.new(2014, 12, 31)).results.where({:plan_id => {"$in" => plans}, :employer_id => nil});

$logger.info "policies_2014 (before rejecting canceled) #{policies_2014.length}"

policies_2014 = policies_2014.reject!(&:canceled?)

$logger.info "policies_2014 (after rejecting canceled) #{policies_2014.length}"

policies_with_no_families = Queries::PoliciesWithNoFamilies.new.execute

policies_with_no_families = policies_with_no_families.reject!(&:canceled?)

$logger.info "policies_with_no_families #{policies_with_no_families.length}"

policies_2014_with_no_families = policies_2014 & policies_with_no_families

$logger.info "policies_2014_with_no_families #{policies_2014_with_no_families.length}"

subscriber_policy_hash = policies_2014_with_no_families.group_by do |policy|
  policy.subscriber
end

policies_2014_with_no_families.each do |policy|
  begin
    family_for_policy_creator = FamilyForPolicyCreator.new(policy)
    family_for_policy_creator.create
    family_for_policy_creator.save
  rescue Exception=>e
    $logger.info "Error: #{e.message}"
  end
end

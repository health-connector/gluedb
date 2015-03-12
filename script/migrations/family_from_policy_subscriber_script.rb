require File.join(Rails.root, "script", "migrations", "family_from_policy_subscriber")
require File.join(Rails.root, "app", "models", "queries", "policies_with_no_families")

$logger = Logger.new("#{Rails.root}/log/family_for_orphan_policies_#{Time.now.to_s.gsub(' ', '')}.log")

def add_hbx_enrollment(family, policy)

  return if family.active_household.nil?

  hbx_enrollement = family.active_household.hbx_enrollments.build
  hbx_enrollement.policy = policy
  hbx_enrollement.elected_aptc_in_dollars = policy.elected_aptc
  hbx_enrollement.applied_aptc_in_dollars = policy.applied_aptc
  hbx_enrollement.submitted_at = family.submitted_at

  hbx_enrollement.kind = "employer_sponsored" unless policy.employer_id.blank?
  hbx_enrollement.kind = "unassisted_qhp" if (hbx_enrollement.applied_aptc_in_cents == 0 && policy.employer.blank?)
  hbx_enrollement.kind = "insurance_assisted_qhp" if (hbx_enrollement.applied_aptc_in_cents > 0 && policy.employer.blank?)

  policy.enrollees.each do |enrollee|
    begin
      person = Person.find_for_member_id(enrollee.m_id)
      family.family_members.build({person: person}) unless family.person_is_family_member?(person)
      family_member = family.find_family_member_by_person(person)
      hbx_enrollement_member = hbx_enrollement.hbx_enrollment_members.build({family_member: family_member,
                                                                             premium_amount_in_cents: enrollee.pre_amt})
      hbx_enrollement_member.is_subscriber = true if (enrollee.rel_code == "self")

    rescue FloatDomainError
      next
    end
  end
end


$logger.info "Starting to attach non primary-applicants' policies to families"
$logger.info "Family_count_start: #{Family.count}"
$logger.info "Total policies count: #{Policy.count}"
$logger.info "Persons count: #{Person.count}"

policies_with_no_families = Queries::PoliciesWithNoFamilies.new.execute

$logger.info "policies_with_no_families: #{policies_with_no_families.length}"

policies_2014_with_no_families = policies_with_no_families.select do |policy|
  next if policy.subscriber.nil?
  policy.subscriber.coverage_start > Date.new(2013, 12, 31) && policy.subscriber.coverage_start < Date.new(2014, 12, 31)
end

$logger.info "policies_2014_with_no_families: #{policies_2014_with_no_families.length}"

policy_groups = policies_2014_with_no_families.group_by do |policy| policy.subscriber.person.id end

people_with_multiple_families = []
$logger.info "policy_groups: #{policy_groups.length}"


policy_groups.each do |person_id, policies|
  begin
    person = Person.find(person_id)
    families = Family.where({:family_members => {"$elemMatch" => {:person_id => Moped::BSON::ObjectId(person_id)}}})
    next if families.empty?

    if families.length > 1
      people_with_multiple_families << person_id
      raise("Person belongs to multiple families. Person id #{person.id} Family e_case_ids: #{families.map(&:e_case_id)}")
    end

    family = families.first
    policies.each do |policy|
      add_hbx_enrollment(family, policy)
      family.save!
      $logger.info "Saved family : #{family.e_case_id}"
    end
  rescue Exception=>e
    $logger.info "ERROR: #{e.message}"
  end
end

$logger.info "people_with_multiple_families #{people_with_multiple_families.inspect}"
$logger.info "family_count after attaching non primary applicant policies: #{Family.count}"
$logger.info "people_with_multiple_families: #{people_with_multiple_families.length}"


$logger.info "Starting to create families for policies without families"

policy_groups.each do |person_id, policies|
  next if people_with_multiple_families.include?(person_id)
  begin
  person = Person.find(person_id)
  family_from_policy_subscriber = FamilyFromPolicySubscriber.new(person, policies)
  family_from_policy_subscriber.create
  family_from_policy_subscriber.save
  rescue Exception=>e
    $logger.info "ERROR: #{e.message}"
  end
end

$logger.info "Family_count_start: #{Family.count}"
$logger.info "Total policies count: #{Policy.count}"
$logger.info "Persons count: #{Person.count}"

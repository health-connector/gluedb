#Usage
#rails r script/migrations/family_from_policy_subscriber_script.rb BEGIN-DATE END-DATE
#BEGIN-DATE, END-DATE  format = MMDDYYYY
#E.g. rails r script/migrations/family_from_policy_subscriber_script.rb 01012017 01122017

require File.join(Rails.root, "script", "migrations", "family_from_policy_subscriber")
require File.join(Rails.root, "app", "models", "queries", "policies_with_no_families")

begin
  @begin_date = Date.strptime(ARGV[0], "%m%d%Y")
  @end_date = Date.strptime(ARGV[1], "%m%d%Y")
  puts "begin_date #{@begin_date} end_date #{@end_date}"
rescue Exception => e
  puts "Error #{e.message}"
  puts "Usage:"
  puts "rails r script/migrations/family_from_policy_subscriber_script.rb BEGIN-DATE END-DATE"
  puts "rails r script/migrations/family_from_policy_subscriber_script.rb 01012017 01122017"
  exit
end


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

puts "Starting to attach non primary-applicant's policies to families"
puts "Total Families at start: #{Family.count}"
puts "Total policies count: #{Policy.count}"
puts "Persons count: #{Person.count}"

all_policies_with_no_families = Queries::PoliciesWithNoFamilies.new.execute

puts "Total policies_with_no_families: #{all_policies_with_no_families.length}"

policies_with_no_families = all_policies_with_no_families.select do |policy_id|
  policy = Policy.find(policy_id)
  next if policy.subscriber.nil?
  next if policy.plan.nil?
  policy.subscriber.coverage_start >= @begin_date && policy.subscriber.coverage_start <= @end_date
end

puts "In given daterange: policies_with_no_families: #{policies_with_no_families.length}"


policy_groups = policies_with_no_families.group_by do |policy_id|
  policy = Policy.find(policy_id)
  next if policy.subscriber.person.nil?
  policy.subscriber.person.id
end

people_with_multiple_families = []
puts "policy_groups: #{policy_groups.length}"


policy_groups.each do |person_id, policy_ids|
  policy_ids.uniq!
  begin
    person = Person.find(person_id)
    families = Family.where({:family_members => {"$elemMatch" => {:person_id => Moped::BSON::ObjectId(person_id)}}})
    next if families.empty?

    if families.length > 1
      people_with_multiple_families << person_id
      raise("Person belongs to multiple families. Person.authority_member_id #{person.authority_member_id} Family e_case_ids: #{families.map(&:e_case_id)}")
    end

    family = families.first
    policy_ids.each do |policy_id|
      policy = Policy.find(policy_id)
      add_hbx_enrollment(family, policy)
      family.save!
      policy_groups[person_id].delete(policy) #delete the policy as it is processed
      #puts "Saved family : #{family.e_case_id}"
    end

    policy_groups.delete(person_id) #delete the subscriber as we have processed him/her
  rescue Exception => e
    puts "ERROR: #{e.message}"
  end
end

puts "people_with_multiple_families #{people_with_multiple_families.inspect}"
puts "family_count after attaching non primary applicant policies: #{Family.count}"
puts "people_with_multiple_families: #{people_with_multiple_families.length}"


puts "Starting to create families for policies without families"


policy_groups.each do |person_id, policy_ids|
  next if people_with_multiple_families.include?(person_id)
  begin
    person = Person.find(person_id)
    policies = Policy.find(policy_ids).to_a
    family_from_policy_subscriber = FamilyFromPolicySubscriber.new(person, policies)
    family_from_policy_subscriber.create
    family_from_policy_subscriber.save
  rescue Exception => e
    puts "ERROR: #{e.message} " + e.backtrace.join(' ')
  end
end

puts "Total Families at end: #{Family.count}"
puts "Total policies count: #{Policy.count}"
puts "Persons count: #{Person.count}"
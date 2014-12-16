
application_group_list = ApplicationGroup.limit(100)
# application_group_list = ApplicationGroup.where("updated_by" => {"$ne" => "renewal_migration_service"}).no_timeout

# Move person_relationships from ApplicationGroup to Person model
def migrate_relationships(app_group)
  app_group.person_relationships.each do |rel|

    # Use relationships to construct AG membership and move relationships to Person model
    subject   = Person.find(rel["subject_person"])
    relative  = Person.find(rel["object_person"])
    relationship = rel["relationship_kind"]

    subject.person_relationships << PersonRelationship.new(
        relative: relative,
        kind: relationship
      )
    subject.updated_by = "renewal_migration_service"
    subject.save!

    unless relationship == "self" || relationship.blank?
      # Create the other person's self-relective relationship 
      relative.person_relationships << PersonRelationship.new(
          relative: relative,
          kind: "self"
        )

      # Add relationship to 'subject individual'
      pr = PersonRelationship.new(
          relative: subject,
          kind: relationship
        )

      # Flip the relationship
      relative.person_relationships << pr.invert_relationship

      relative.updated_by = "renewal_migration_service"
      relative.save!
    end
  end
end

def build_applicant_list(app_group)
  app_group.applicants = []

  # Distinct applicants may be found in both person_relationships and enrollments
  app_group.person_relationships.each do |rel|
    p0 = Person.find(rel["subject_person"])
    p1 = Person.find(rel["object_person"])
    relationship = rel["relationship_kind"]

    appl = nil
    if relationship == "self"
      unless app_group.person_is_applicant?(p0)
        appl = Applicant.new(person: p0, is_primary_applicant: true, is_consent_applicant: true)
      end
    else
      appl = Applicant.new(person: p1) unless app_group.person_is_applicant?(p1)
    end
    app_group.applicants << appl unless appl.blank?
  end

  app_group
end

def build_enrollments(app_group)
  enrollments = []

  primary_appl = app_group.primary_applicant
  if primary_appl.blank?
    puts "ApplicationGroup missing primary applicant: #{app_group.inspect}"
    return
  end

  primary_appl.person.policies.collect do |policy|

    if policy.blank?
      puts "No Policies found for primary applicant: #{primary_appl.inspect}"
      next
    end

    he = HbxEnrollment.new()

    # he.plan = Plan.find(policy.plan_id)
    # he.primary_applicant = alpha_person
    # he.allocated_aptc_in_dollars = policy.allocated_aptc

    he.policy = policy
    he.enrollment_group_id = policy.eg_id
    he.elected_aptc_in_dollars = policy.elected_aptc
    he.applied_aptc_in_dollars = policy.applied_aptc
    he.submitted_at = policy.enrollees.first.coverage_start

    if policy.is_shop?
      he.kind = "employer_sponsored"
    else
      he.applied_aptc_in_cents > 0 ? he.kind = "insurance_assisted_qhp" : he.kind = "unassisted_qhp"
    end

    policy.enrollees.each do |enrollee|
      begin
        person = Person.find_for_member_id(enrollee.m_id)
        app_group.applicants << Applicant.new(person: person) unless app_group.person_is_applicant?(person)
        appl = app_group.find_applicant_by_person(person)

        em = he.hbx_enrollment_members.build(
            applicant: appl,
            premium_amount_in_dollars: enrollee.pre_amt,
            start_date: Date.today,
            eligibility_date: Date.today
          )

        em.is_subscriber = true if (enrollee.rel_code == "self")

      rescue FloatDomainError
        puts "Error: invalid premium amount for enrollee: #{enrollee.inspect}"
        next
      end
    end

    # Assign broker if known
    primary_appl.broker = Broker.find(policy.broker_id) unless policy.broker_id.blank?

    unless policy.employer_id.blank?
      employer = Employer.find(policy.employer_id)
      puts "Employer: #{employer.inspect}"
      puts "PrimaryApplicant: #{primary_appl.inspect}"
      # ea = primary_appl.employee_applicants.build(employer: employer, start_date: )
      # puts "EmployeeApplicant: #{ea.inspect}"
    end

    enrollments << he
  end
  enrollments
end

application_group_list.each do |ag|


  # Move the ApplicationGroup relationships to repsective Person models
  migrate_relationships(ag)

  build_applicant_list(ag)

  # Build hbx_enrollments
  hh = ag.households.build(submitted_at: Time.now)
  ch = hh.coverage_households.build(submitted_at: Time.now)
  
  hh.hbx_enrollments = build_enrollments(ag)

  ag.applicants.each do |applicant|
    ch.coverage_household_members << applicant 
  end

  ag.application_type = hh.hbx_enrollments.first.kind
  ag.renewal_consent_through_year = 2014
  ag.submitted_at = Time.now
  ag.updated_by = "renewal_migration_service"

  puts ag.errors.full_messages
  puts ag.valid?
  puts "Applicants: #{ag.applicants.inspect}" unless ag.valid? 
  ag.save!
  # Build tax_households

  # build irs_groups

  # build financial_statements

  # build eligibility_determinations

end

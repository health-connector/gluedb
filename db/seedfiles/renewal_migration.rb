application_group = ApplicationGroup.limit(10)
application_group = ApplicationGroup.first.to_a
# application_group = ApplicationGroup.where("updated_by" => {"$ne" => "renewal_migration_service"}).no_timeout

# Move person_relationships from ApplicationGroup to Person model
def migrate_relationships(app_group)
  app_group.person_relationships.each do |rel|

    # Use relationships to construct AG membership and move relationships to Person model
    subject = Person.find(rel["subject_person"])
    relative = Person.find(rel["object_person"])
    relationship = rel["relationship_kind"]

    subject.person_relationships << PersonRelationship.new(
        relative: relative,
        kind: relationship
    )
    subject.updated_by = "renewal_migration_service"
    subject.save!

    unless relationship == "self"
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
  applicants = []

  # Distinct applicants may be found in both person_relationships and enrollments
  app_group.person_relationships.each do |rel|
    p0 = Person.find(rel["subject_person"])
    p1 = Person.find(rel["object_person"])
    relationship = rel["relationship_kind"]

    if relationship == "self"
      appl = Applicant.new(person: p0, is_primary_applicant: true, is_consent_applicant: true)
      primary_appl = appl
    else
      appl = Applicant.new(person: p1)
    end
    applicants << appl
  end

  # Find enrollees from all polocies associated with Primary Applicant
  # primary_appl.person.policies.collect do |policy|
  # end

  applicants
end

def build_enrollments(app_group)
  enrollments = []
  enrollment_list = app_group.primary_applicant.person.policies.collect { |policy|
    he = HbxEnrollment.new()

    # he.plan = Plan.find(policy.plan_id)
    # he.employer = Employer.find(policy.employer_id) unless policy.employer_id.blank?
    # he.broker   = Broker.find(policy.broker_id) unless policy.broker_id.blank?
    # he.primary_applicant = alpha_person
    # he.allocated_aptc_in_dollars = policy.allocated_aptc

    he.policy = policy
    he.enrollment_group_id = policy.eg_id
    he.elected_aptc_in_dollars = policy.elected_aptc
    he.applied_aptc_in_dollars = policy.applied_aptc
    he.submitted_date = Time.now

    he.kind = "employer_sponsored" unless policy.employer_id.blank?
    he.kind = "unassisted_qhp" if (he.applied_aptc_in_cents == 0 && policy.employer.blank?)
    he.kind = "insurance_assisted_qhp" if (he.applied_aptc_in_cents > 0 && policy.employer.blank?)

    policy.enrollees.each do |enrollee|
      begin
        person = Person.find_for_member_id(enrollee.m_id)
        # puts "Person: #{person.inspect}"
        app_group.applicants << Applicant.new(person: person) unless app_group.person_is_applicant?(person)
        appl = app_group.find_applicant_by_person(person)
        # puts "Applicant: #{appl}"

        em = HbxEnrollmentMember.new(
            applicant: appl,
            premium_amount_in_cents: enrollee.pre_amt
        )

        em.is_subscriber = true if (enrollee.rel_code == "self")
        he.hbx_enrollment_members << em

      rescue FloatDomainError
        puts "Error: invalid premium amount for enrollee: #{enrollee.inspect}"
        next
      end
    end

    enrollments << he
  }
  enrollments
end

application_group.each do |ag|

  hh = Household.new(
      application_group: ag,
      submitted_at: Time.now
  )
  ch = CoverageHousehold.new(
      household: hh,
      submitted_at: Time.now
  )

  # Move the ApplicationGroup relationships to repsective Person models
  migrate_relationships(ag)

  ag.applicants = build_applicant_list(ag)

  # Build hbx_enrollments
  hh.hbx_enrollments = build_enrollments(ag)

  ag.applicants.each do |applicant|
    ch.coverage_household_members << applicant if applicant.is_coverage_applicant
  end

  ag.renewal_consent_through_year = 2014
  ag.submitted_at = Time.now
  ag.updated_by = "renewal_migration_service"

  ag.save!
  # Build tax_households

  # build irs_groups

  # build financial_statements

  # build eligibility_determinations
end

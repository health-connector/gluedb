
application_group = ApplicationGroup.limit(100)
application_group = ApplicationGroup.where("updated_by" => {"$ne" => "renewal_migration_service"}).no_timeout

application_group.each do |ag|

  ag.renewal_consent_through_year = 2014
  ag.submitted_date = Date.today
  ag.updated_by = "renewal_migration_service"

  # Move the application relationships to Person model
  ag.person_relationships.each do |rel|

    # Use relationships to construct AG membership and move relationships to Person model
    subject   = Person.find(rel["subject_person"])
    relative  = Person.find(rel["object_person"])
    relationship = rel["relationship_kind"]

    if !subject.application_group.blank? && (subject.application_group.id != ag.id)
      raise "Cannot assign Person #{subject.id} in ApplicationGroup #{subject.application_group.id} to second ApplicationGroup #{ag.id}"
    end 

    subject.person_relationships << PersonRelationship.new(
        relative: relative,
        kind: relationship
      )
    subject.application_group = ag
    subject.updated_by = "renewal_migration_service"
    subject.save!

    # Now add the relative's Person model
    unless relationship == "self"
      if !relative.application_group.blank? && (relative.application_group.id != ag.id)
        raise "Cannot assign Person #{relative.id} in ApplicationGroup #{relative.application_group.id} to second ApplicationGroup #{ag.id}"
      end 

      relative.application_group = ag

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

  # ag.person_relationships.delete_all

  alpha_person_hash = ag.person_relationships.detect { |r| r["relationship_kind"] == "self" }
  if alpha_person_hash.blank?
    puts "Error: no 'self' person relationship found on ApplicationGroup ID: #{ag.id}"
    next
  end
  alpha_person = Person.find(alpha_person_hash["subject_person"])

  ag.primary_applicant = alpha_person
  ag.consent_applicant = alpha_person

  # Person.where({ :'assistance_eligibilities.1' => true })

  # Build hbx_enrollment_policies
  enrollment_list = alpha_person.policies.collect do |policy|
    he = HbxEnrollment.new
    he.application_group = ag

    he.policy = policy
    he.plan = Plan.find(policy.plan_id)
    he.employer = Employer.find(policy.employer_id) unless policy.employer_id.blank?
    he.broker   = Broker.find(policy.broker_id) unless policy.broker_id.blank?
    he.primary_applicant = alpha_person
    he.enrollment_group_id = policy.eg_id
    he.allocated_aptc_in_dollars = policy.allocated_aptc
    he.elected_aptc_in_dollars = policy.elected_aptc
    he.applied_aptc_in_dollars = policy.applied_aptc

    he.kind = "employer_sponsored" unless he.employer.blank?
    he.kind = "unassisted_qhp" if (he.applied_aptc_in_cents == 0 && he.employer.blank?)
    he.kind = "insurance_assisted_qhp" if (he.applied_aptc_in_cents > 0 && he.employer.blank?)

    policy.enrollees.each do |enrollee|
     begin
        al = ApplicantLink.new(
          person: Person.find_for_member_id(enrollee.m_id),
          premium_amount_in_dollars: enrollee.pre_amt
          )
        al.is_primary_applicant = true if (al.person == alpha_person)
        he.applicant_links << al
      rescue FloatDomainError
        puts "Error: invalid premium amount for enrollee: #{enrollee.inspect}"
        next
      end
    end

    he
  end

  ag.hbx_enrollments = enrollment_list
  ag.save!
  # Build tax_households

  # build irs_groups

  # build financial_statements

  # build eligibility_determinations

end

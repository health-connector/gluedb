class PolicyHbxEnrollmentCreator

  def initialize(policy, family)
    @policy = policy
    @family = family
  end

  def create
      hbx_enrollement = @family.active_household.hbx_enrollments.build
      hbx_enrollement.policy = @policy
      @family.primary_applicant.broker_id = Broker.find(@policy.broker_id).id unless @policy.broker_id.blank?

      hbx_enrollement.enrollment_group_id = @policy.eg_id
      hbx_enrollement.elected_aptc_in_dollars = @policy.elected_aptc
      hbx_enrollement.applied_aptc_in_dollars = @policy.applied_aptc
      hbx_enrollement.submitted_at = Time.now

      hbx_enrollement.kind = "employer_sponsored" unless @policy.employer_id.blank?
      hbx_enrollement.kind = "unassisted_qhp" if (hbx_enrollement.applied_aptc_in_cents == 0 && @policy.employer.blank?)
      hbx_enrollement.kind = "insurance_assisted_qhp" if (hbx_enrollement.applied_aptc_in_cents > 0 && @policy.employer.blank?)

      @policy.enrollees.each do |enrollee|
        begin
          person = Person.find_for_member_id(enrollee.m_id)

          @family.family_members << FamilyMember.new(person: person) unless @family.person_is_family_member?(person)
          family_member = @family.find_family_member_by_person(person)

          hbx_enrollement_member = hbx_enrollement.hbx_enrollment_members.build({family_member: family_member,
                                                                                 premium_amount_in_cents: enrollee.pre_amt})
          hbx_enrollement_member.is_subscriber = true if (enrollee.rel_code == "self")

        rescue FloatDomainError
          # puts "Error: invalid premium amount for enrollee: #{enrollee.inspect}"
          next
        end
      end

      @family.save
      @family

  end
end
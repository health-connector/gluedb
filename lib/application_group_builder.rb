class ApplicationGroupBuilder

  attr_reader :application_group

  def initialize(param, person_mapper)
    param = param.slice(:e_case_id, :submitted_at, :e_status_code, :application_type)
    @person_mapper = person_mapper
    #@application_group = ApplicationGroup.where(e_case_id:param[:e_case_id]).first
    @application_group ||= ApplicationGroup.new(param)
    @application_group.updated_by = "curam_system_service"
    @household = self.application_group.households.build
  end

  def add_applicant(applicant_params)
    applicant = @application_group.applicants.build(applicant_params.slice(:applicant_id,
                                                                           :is_primary_applicant,
                                                                           :is_coverage_applicant,
                                                                           :is_head_of_household,
                                                                           :person_demographics,
                                                                           :person))
  end

  def add_coverage_household(household=@application_group.households.first)

    coverage_household = household.coverage_households.build({submitted_at: Time.now})

    @application_group.applicants.each do |applicant|
      coverage_household.coverage_household_members << applicant if applicant.is_coverage_applicant
    end

  end

  def add_hbx_enrollment(household=@application_group.households.first)


    puts "#{@application_group.id} #{@application_group.primary_applicant.person.id} #{@application_group.primary_applicant.person.policies.size}"
    @application_group.primary_applicant.person.policies.each do |policy|

      hbx_enrollement = household.hbx_enrollments.build
      hbx_enrollement.policy = policy
      hbx_enrollement.enrollment_group_id = policy.eg_id
      hbx_enrollement.elected_aptc_in_dollars = policy.elected_aptc
      hbx_enrollement.applied_aptc_in_dollars = policy.applied_aptc
      hbx_enrollement.submitted_at = Time.now

      hbx_enrollement.kind = "employer_sponsored" unless policy.employer_id.blank?
      hbx_enrollement.kind = "unassisted_qhp" if (hbx_enrollement.applied_aptc_in_cents == 0 && policy.employer.blank?)
      hbx_enrollement.kind = "insurance_assisted_qhp" if (hbx_enrollement.applied_aptc_in_cents > 0 && policy.employer.blank?)

      policy.enrollees.each do |enrollee|
        begin
          person = Person.find_for_member_id(enrollee.m_id)

          @application_group.applicants << Applicant.new(person: person) unless @application_group.person_is_applicant?(person)
          application_group = @application_group.find_applicant_by_person(person)

          hbx_enrollement_member = hbx_enrollement.hbx_enrollment_members.build({applicant: application_group,
                                                         premium_amount_in_dollars: enrollee.pre_amt})
          hbx_enrollement_member.is_subscriber = true if (enrollee.rel_code == "self")

        rescue FloatDomainError
          puts "Error: invalid premium amount for enrollee: #{enrollee.inspect}"
          next
        end
      end

    end

  end

  #TODO - method not implemented properly using .build(params)
  def add_irsgroups(irs_groups_params)
    irs_groups = irs_groups_params.map do |irs_group_params|
      IrsGroup.new(irs_group_params)
    end

    @application_group.irs_groups = irs_groups

  end

  def add_tax_households(tax_households_params, eligibility_determinations_params)

    tax_households_params.map do |tax_household_params|

      tax_household = @household.tax_households.build(tax_household_params.slice(:id, :primary_applicant_id,
                                                                                 :total_count, :total_incomes_by_year))

      tax_household_params[:tax_household_members].map do |tax_household_member_params|
        tax_household_member = tax_household.tax_household_members.build(tax_household_member_params)
        person_uri = @person_mapper.alias_map[tax_household_member_params[:id]]
        person_obj = @person_mapper.people_map[person_uri].first
        new_applicant = get_applicant(person_obj)
        tax_household_member.applicant_id = new_applicant.id
        tax_household_member.applicant = new_applicant

      end

    end


    eligibility_determinations_params.each do |eligibility_determination_params|
      #TODO assuming only 1tax_household. needs to be corrected later
      @household.tax_households.first.eligibility_determinations.build(eligibility_determination_params)
    end

  end

  def get_applicant(person_obj)

    new_applicant = self.application_group.applicants.find do |applicant|
      applicant.id == @person_mapper.applicant_map[person_obj.id].id
    end
    new_applicant = @person_mapper.applicant_map[person_obj.id] unless new_applicant
  end

  def add_financial_statements(applicants_params)
    applicants_params.map do |applicant_params|
      applicant_params[:financial_statements].each do |financial_statement_params|
        tax_household_member = find_tax_household_member(@person_mapper.applicant_map[applicant_params[:person].id])
        financial_statement = tax_household_member.financial_statements.build(financial_statement_params.slice(:type, :is_tax_filing_together, :tax_filing_status))
        financial_statement_params[:incomes].each do |income_params|
          financial_statement.incomes.build(income_params)
        end
        financial_statement_params[:deductions].each do |deduction_params|
          financial_statement.deductions.build(deduction_params)
        end
        financial_statement_params[:alternative_benefits].each do |alternative_benefit_params|
          financial_statement.alternative_benefits.build(alternative_benefit_params)
        end
      end
    end
  end

  def find_tax_household_member(applicant)
    tax_household_members = self.application_group.households.flat_map(&:tax_households).flat_map(&:tax_household_members)

    tax_household_member = tax_household_members.find do |tax_household_member|

      tax_household_member.applicant_id == applicant.id
    end

    tax_household_member
  end

end
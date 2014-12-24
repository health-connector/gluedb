class ApplicationGroupBuilder

  attr_reader :application_group

  attr_reader :save_list

  def initialize(param, person_mapper)
    @save_list = []
    @is_update = true # we assume that this is a update existing application group workflow
    @applicants_params = param[:applicants]
    param = param.slice(:e_case_id, :submitted_at, :e_status_code, :application_type)
    @person_mapper = person_mapper
    @application_group = ApplicationGroup.where(e_case_id:param[:e_case_id]).first

    if @application_group.nil?
      @application_group = ApplicationGroup.new(param) #we create a new application group from the xml
      @is_update = false # means this is a create
      add_irsgroup # we need a atleast 1 irsgroup hence adding a blank one
    end

    @application_group.updated_by = "curam_system_service"

    get_household
  end

  def add_applicant(applicant_params)

    puts applicant_params[:is_primary_applicant]

    if @application_group.applicants.map(&:person_id).include? applicant_params[:person].id
      puts "Added already existing applicant"
      applicant = @application_group.applicants.where(person_id:applicant_params[:person].id).first
    else
      puts "Added a new applicant"
      applicant = @application_group.applicants.build(filter_applicant_params(applicant_params))
      member = applicant.person.members.select do |m| m.authority? end.first
      set_person_demographics(member, applicant_params[:person_demographics])
      @save_list << member
      @save_list << applicant
    end

    applicant
  end

  def reset_exisiting_primary_applicant
    @application_group.applicants.each do |applicant|
        applicant.is_primary_applicant = false
        applicant.save
    end
  end

  def set_person_demographics(member, person_demographics_params)
    member.dob = person_demographics_params["dob"] if person_demographics_params["dob"]
    member.death_date = person_demographics_params["death_date"] if person_demographics_params["death_date"]
    member.ssn = person_demographics_params["ssn"] if person_demographics_params["ssn"]
    member.gender = person_demographics_params["gender"] if person_demographics_params["gender"]
    member.ethnicity = person_demographics_params["ethnicity"] if person_demographics_params["ethnicity"]
    member.race = person_demographics_params["race"] if person_demographics_params["race"]
    member.marital_status = person_demographics_params["marital_status"] if person_demographics_params["marital_status"]
  end

  def filter_applicant_params(applicant_params)
    applicant_params = applicant_params.slice(
        :is_primary_applicant,
        :is_coverage_applicant,
        :person)
    applicant_params.delete_if do |k, v|
      v.nil?
    end
  end

  def get_household

    return @household if @household

    if !@is_update
      puts "New Application Group Case"
      @household = self.application_group.households.build #if new application group then create new household
      @save_list << @household
    elsif have_applicants_changed?
      puts "Update Application Group Case - Applicants have changed. Creating new household"
      @household = self.application_group.households.build #if applicants have changed then create new household
      @save_list << @household
    else
      puts "Update Application Group Case. Using latest household."
      #TODO to use .is_active household instead of .last
      @household = self.application_group.households.last #if update and applicants haven't changed then use the latest household in use
    end

    return @household

  end

  def have_applicants_changed?
    current_list = @application_group.applicants.map do |applicant| applicant.person_id end.sort
    new_list = @applicants_params.map do |applicants_param| applicants_param[:person].id end.sort

    #puts current_list.inspect
    #puts new_list.inspect

    if current_list == new_list
      return false
    else
      return true
    end
  end

  def add_coverage_household

    coverage_household = @household.coverage_households.build({submitted_at: Time.now})

    @application_group.applicants.each do |applicant|
      if applicant.is_coverage_applicant
        coverage_household_member = coverage_household.coverage_household_members.build
        coverage_household_member.applicant_id = applicant.id
      end
    end

  end

  def add_hbx_enrollment

    @application_group.primary_applicant.person.policies.each do |policy|

      hbx_enrollement = @household.hbx_enrollments.build
      hbx_enrollement.policy = policy
      #hbx_enrollement.employer = Employer.find(policy.employer_id) unless policy.employer_id.blank?
      #hbx_enrollement.broker   = Broker.find(policy.broker_id) unless policy.broker_id.blank?
      #hbx_enrollement.primary_applicant = alpha_person
      #hbx_enrollement.allocated_aptc_in_dollars = policy.allocated_aptc
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
          applicant = @application_group.find_applicant_by_person(person)

          hbx_enrollement_member = hbx_enrollement.hbx_enrollment_members.build({applicant: applicant,
                                                         premium_amount_in_cents: enrollee.pre_amt})
          hbx_enrollement_member.is_subscriber = true if (enrollee.rel_code == "self")

        rescue FloatDomainError
          puts "Error: invalid premium amount for enrollee: #{enrollee.inspect}"
          next
        end
      end

    end

  end

  def add_irsgroup
    @application_group.irs_groups.build()
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

      #tax_household = @household.tax_households.build(tax_household_params.slice(:id, :primary_applicant_id,
                                                                                # :total_count, :total_incomes_by_year))

      tax_household = @household.tax_households.build(filter_tax_household_params(tax_household_params))

      tax_household_params[:tax_household_members].map do |tax_household_member_params|
        tax_household_member = tax_household.tax_household_members.build(filter_tax_household_member_params(tax_household_member_params))
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

  def filter_tax_household_member_params(tax_household_member_params)
    tax_household_member_params.delete_if do |k, v|
      v.nil?
    end
  end

  def filter_tax_household_params(tax_household_params)
    tax_household_params = tax_household_params.slice(:id, :primary_applicant_id, :total_count, :total_incomes_by_year)
    tax_household_params.delete_if do |k, v|
      v.nil?
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
        financial_statement = tax_household_member.financial_statements.build(filter_financial_statement_params(financial_statement_params))
        financial_statement_params[:incomes].each do |income_params|
          financial_statement.incomes.build(income_params)
        end
        financial_statement_params[:deductions].each do |deduction_params|
          financial_statement.deductions.build(deduction_params)
        end
        financial_statement_params[:alternative_benefits].each do |alternative_benefit_params|
          financial_statement.alternate_benefits.build(alternative_benefit_params)
        end
      end
    end
  end

  def filter_financial_statement_params(financial_statement_params)
    financial_statement_params.delete_if do |k, v|
      v.nil?
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
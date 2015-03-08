require "irs_groups/irs_group_builder"

class FamilyBuilder

  attr_reader :family

  attr_reader :save_list

  def initialize(param, person_mapper)
    $logger ||= Logger.new("#{Rails.root}/log/family_#{Time.now.to_s.gsub(' ', '')}.log")
    $error_dir ||= File.join(Rails.root, "log", "error_xmls_from_curam_#{Time.now.to_s.gsub(' ', '')}")

    @save_list = [] # it is observed that some embedded objects are not saved. We add all embedded/associated objects to this list and save them explicitly
    @new_family_members = [] #this will include all the new applicants objects we create. In case of update application_group will have old applicants

    if param.nil? || person_mapper.nil?
      initialize_with_nil_params
      return
    end

    @is_update = true # true = we update an existing application group, false = we create a new application group
    @family_members_params = param[:family_members]
    @params = param
    filtered_param = param.slice(:e_case_id, :submitted_at, :e_status_code, :application_type)
    @person_mapper = person_mapper
    @family = Family.where(e_case_id: filtered_param[:e_case_id]).first
    if @family.nil?
      @family = Family.new(filtered_param) #we create a new application group from the xml
      @is_update = false # means this is a create
    end

    @family.submitted_at = filtered_param[:submitted_at]
    @family.updated_by = "curam_system_service"
    get_household
  end

  def initialize_with_nil_params
    @is_update = false
    @family = Family.new
    @family.e_case_id = (0...12).map { (65 + rand(26)).chr }.join
    @family.submitted_at = DateTime.now
    @family.updated_by = "curam_system_service"
    get_household
  end


  def build
    add_hbx_enrollments
    add_tax_households(@params.to_hash[:tax_households])
    add_financial_statements(@params[:family_members])
    add_coverage_household
    handle_empty_coverage_households
    return_obj = save
    add_irsgroups
    return_obj
  end

  def handle_empty_coverage_households
    return if @household.nil?

    coverage_household = @household.coverage_households.detect do |coverage_household|
      coverage_household.coverage_household_members.blank?
    end

    return if coverage_household.nil?

    policies = []
    if @family.primary_applicant.nil?
      policies = @family.family_members.flat_map(&:person).flat_map(&:policies)
    else
      policies = @family.primary_applicant.person.policies
    end

    policies.flat_map(&:enrollees).each do |enrollee|
      person = Person.find_for_member_id(enrollee.m_id)

      @family.family_members.build({person: person}) unless @family.person_is_family_member?(person)

      family_member = @family.find_family_member_by_person(person)
      unless coverage_household.is_existing_member?(person)
        coverage_household_member = coverage_household.coverage_household_members.build({:applicant_id => family_member.id, :is_subscriber => true})
        $logger.info "Family e_case_id: #{@family.e_case_id} Person #{person.id} Enrollee m_id #{enrollee.m_id}  added to coverage household #{coverage_household.id}"
      end
    end
  end

  def add_family_member(family_member_params)

    if @family.family_members.map(&:person_id).include? family_member_params[:person].id
      #puts "Added already existing family_member"
      family_member = @family.family_members.where(person_id: family_member_params[:person].id).first
    else
      #puts "Added a new family_member"
      if family_member_params[:is_primary_applicant] == "true"
        is_primary_applicant_unique?(family_member_params)
        reset_exisiting_primary_applicant
      end

      family_member = @family.family_members.build(filter_family_member_params(family_member_params))

      @new_family_members << family_member

      member = family_member.person.members.select do |m|
        m.authority?
      end.first

      member = family_member.person.authority_member if member.nil?

      set_person_demographics(member, family_member_params[:person_demographics]) if family_member_params[:person_demographics]
      set_alias_ids(member, family_member_params[:alias_ids]) if family_member_params[:alias_ids]
      @save_list << member
      @save_list << family_member
    end

    family_member
  end

  def is_primary_applicant_unique?(family_member_params)

    person = family_member_params[:person]

    families = Family.where({:family_members => {"$elemMatch" => {:person_id => Moped::BSON::ObjectId(person.id)}}})

    return true if families.length == 0

    family = families.find do |f|
      next if f.primary_applicant.nil?
      f.primary_applicant.person.id.eql? person.id
    end

    if family.present?
      raise("Family e_case_id: #{@family.e_case_id} Duplicate Primary Applicant person_id : #{person.id}. existing family #{family.e_case_id}" )
    else
      return true
    end
  end

  def set_alias_ids(member, alias_ids_params)

    alias_ids_params.each do |alias_id_params|
      alias_id = alias_id_params.split('#').last
      return if alias_id.nil?

      if alias_id_params.include? "aceds"
        member.aceds_id = alias_id
      elsif alias_id_params.include? "concern_role"
        member.e_concern_role_id = alias_id
      elsif alias_id_params.include? "person"
        member.e_person_id = alias_id
      end
    end
  end

  def reset_exisiting_primary_applicant
    @family.family_members.each do |family_member|
      family_member.is_primary_applicant = false
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

  def filter_family_member_params(family_member_params)
    family_member_params = family_member_params.slice(
        :is_primary_applicant,
        :is_coverage_applicant,
        :person)

    family_member_params.delete_if do |k, v|
      v.nil?
    end

    family_member_params
  end

  def get_household

    return @household if @household
    if !@is_update
      #puts "New Application Group Case"
      @household = self.family.households.build #if new application group then create new household
      @save_list << @household
    elsif have_family_members_changed?
      #puts "Update Application Group Case - Applicants have changed. Creating new household"
      @household = self.family.households.build #if applicants have changed then create new household
      @save_list << @household
    else
      #puts "Update Application Group Case - @household = self.family.active_household"
      @household = self.family.active_household #if update and applicants haven't changed then use the active household
    end

    return @household

  end

  def have_family_members_changed?

    current_list = @family.family_members.map do |family_member|
      family_member.person_id
    end.sort

    new_list = @family_members_params.map do |family_member_params|
      family_member_params[:person].id
    end.sort

    #puts "current_list #{current_list.inspect}"
    #puts "new_list #{new_list.inspect}"

    if current_list == new_list
      return false
    else
      return true
    end
  end

  def add_coverage_household

    return if @new_family_members.length == 0

    #TODO decide where to get submitted_at from
    coverage_household = @household.coverage_households.build({submitted_at: @family.submitted_at})

    @new_family_members.each do |family_member|
      if family_member.is_coverage_applicant
        if valid_relationship?(family_member)
          coverage_household_member = coverage_household.coverage_household_members.build
          coverage_household_member.applicant_id = family_member.id
        else
          $logger.warn "WARNING: Family e_case_id: #{@family.e_case_id} Relationship #{@family.primary_applicant.person.find_relationship_with(family_member.person)} not valid for a coverage household between primary applicant person #{@family.primary_applicant.person.id} and #{family_member.person.id}"
        end
      end
    end
  end

  def valid_relationship?(family_member)
    return true if @family.primary_applicant.nil? #responsible party case
    return true if @family.primary_applicant.person.id == family_member.person.id

    valid_relationships = %w{self spouse life_partner child ward foster_child adopted_child stepson_or_stepdaughter}

    if valid_relationships.include? @family.primary_applicant.person.find_relationship_with(family_member.person)
      return true
    else
      return false
    end
  end

  def add_hbx_enrollments

    return if @family.primary_applicant.nil?

    @household.hbx_enrollments.delete_all #clear any existing

    @family.primary_applicant.person.policies.each do |policy|
      add_hbx_enrollment(policy)
    end
  end

  def add_hbx_enrollment(policy)

    return if @family.primary_applicant.nil?

    hbx_enrollement = @household.hbx_enrollments.build
    hbx_enrollement.policy = policy
    @family.primary_applicant.broker_id = Broker.find(policy.broker_id).id unless policy.broker_id.blank?
    hbx_enrollement.elected_aptc_in_dollars = policy.elected_aptc
    hbx_enrollement.applied_aptc_in_dollars = policy.applied_aptc
    hbx_enrollement.submitted_at = @family.submitted_at

    hbx_enrollement.kind = "employer_sponsored" unless policy.employer_id.blank?
    hbx_enrollement.kind = "unassisted_qhp" if (hbx_enrollement.applied_aptc_in_cents == 0 && policy.employer.blank?)
    hbx_enrollement.kind = "insurance_assisted_qhp" if (hbx_enrollement.applied_aptc_in_cents > 0 && policy.employer.blank?)

    policy.enrollees.each do |enrollee|
      begin
        person = Person.find_for_member_id(enrollee.m_id)
        @family.family_members.build({person: person}) unless @family.person_is_family_member?(person)
        family_member = @family.find_family_member_by_person(person)
        hbx_enrollement_member = hbx_enrollement.hbx_enrollment_members.build({family_member: family_member,
                                                                               premium_amount_in_cents: enrollee.pre_amt})
        hbx_enrollement_member.is_subscriber = true if (enrollee.rel_code == "self")

      rescue FloatDomainError
        next
      end
    end
  end

  #TODO currently only handling case we create new application case, where 1 irs group is built with 1 coverage household.
  def add_irsgroups
    if @is_update
      irs_group_builder = IrsGroupBuilder.new(self.family.id)
      irs_group_builder.update
    else
      irs_group_builder = IrsGroupBuilder.new(self.family.id)
      irs_group_builder.build
      irs_group_builder.save
    end
  end

  def add_tax_households(tax_households_params)

    @household.tax_households.delete_all

    tax_households_params.map do |tax_household_params|

      tax_household = @household.tax_households.build(filter_tax_household_params(tax_household_params))

      eligibility_determinations_params = tax_household_params[:eligibility_determinations]

      eligibility_determinations_params.each do |eligibility_determination_params|
        tax_household.eligibility_determinations.build(eligibility_determination_params)
      end

      tax_household_params[:tax_household_members].map do |tax_household_member_params|
        tax_household_member = tax_household.tax_household_members.build(filter_tax_household_member_params(tax_household_member_params))
        person_uri = @person_mapper.alias_map[tax_household_member_params[:person_id]]
        person_obj = @person_mapper.people_map[person_uri].first
        new_family_member = get_family_member(person_obj)
        new_family_member = verify_person_id(new_family_member)
        tax_household_member.applicant_id = new_family_member.id
        tax_household_member.family_member = new_family_member
      end
    end
  end

  def verify_person_id(family_member)
    if family_member.id.to_s.include? "concern_role"

    end
    family_member
  end

  def filter_tax_household_member_params(tax_household_member_params)
    tax_household_member_params_clone = tax_household_member_params.clone

    tax_household_member_params_clone = tax_household_member_params_clone.slice(:is_ia_eligible, :is_medicaid_chip_eligible, :is_subscriber)
    tax_household_member_params_clone.delete_if do |k, v|
      v.nil?
    end
    tax_household_member_params_clone
  end

  def filter_tax_household_params(tax_household_params)
    tax_household_params = tax_household_params.slice(:id)
    tax_household_params.delete_if do |k, v|
      v.nil?
    end
  end

  ## Fetches the family_member object either from application_group or person_mapper
  def get_family_member(person_obj)
    new_family_member = self.family.family_members.find do |family_member|
      family_member.id == @person_mapper.applicant_map[person_obj.id].id
    end
    new_family_member = @person_mapper.applicant_map[person_obj.id] unless new_family_member
  end

  def add_financial_statements(family_members_params)
    family_members_params.map do |family_member_params|
      family_member_params[:financial_statements].each do |financial_statement_params|
        tax_household_members = find_tax_household_members(@person_mapper.applicant_map[family_member_params[:person].id])

        tax_household_members.each do |tax_household_member|
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
  end

=begin
  def add_financial_statements(family_members_params)
    family_members_params.map do |family_members_params|
      family_members_params[:financial_statements].each do |financial_statement_params|
        tax_household_member = find_tax_household_member(@person_mapper.applicant_map[family_members_params[:person].id])
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
=end

  def filter_financial_statement_params(financial_statement_params)

    financial_statement_params = financial_statement_params.slice(:type, :is_tax_filing_together, :tax_filing_status)

    financial_statement_params.delete_if do |k, v|
      v.nil?
    end
  end

  def find_tax_household_members(family_member)
    tax_household_members = self.family.households.flat_map(&:tax_households).flat_map(&:tax_household_members)

    tax_household_members= tax_household_members.select do |tax_household_member|
      tax_household_member.applicant_id == family_member.id
    end

    tax_household_members
  end

  def save
    id = @family.save!
    save_save_list
    @family #return the saved family
  end

  #save objects in save list
  def save_save_list
    save_list.each do |obj|
      obj.save! unless obj.nil?
    end
  end
end

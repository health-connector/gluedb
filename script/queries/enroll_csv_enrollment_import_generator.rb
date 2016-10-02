# Generates CSV for enrollment import into Enroll
require 'csv'

redmine_ticket = '8905' # You should only list one ticket number at a time. 

# You can use these settings if you want to use specific enrollment group IDs from Glue.
policy_egids = %w(214792 215013 214751 214705)
policies = Policy.where(:eg_id => {"$in" => policy_egids})

# You can use these settings instead if you need a large number of shop enrollments from a specific plan year.
# plan_year_date = Date.new(2015,11,1)
# plan_years = PlanYear.where(start_date: plan_year_date)
# employer_ids = Employer.where(:_id => {"$in" => plan_years.map(&:employer_id)}).map(&:id)
# plan_ids = Plan.where(year: plan_year_date.year).map(&:id)
# policies = Policy.where(:employer_id => {"$in" => employer_ids},:plan_id => {"$in" => plan_ids})

def select_enrollment_kind(policy)
	if policy.is_shop?
		return 'employer_sponsored'
	else
		return 'individual'
	end
end

def select_ivl_benefit_package(policy,policy_plan,year)
	if policy_plan.coverage_type == 'dental'
		if year == '2015'
			return 'individual_dental_benefits_2015'
		elsif year == '2016'
			return 'individual_dental_benefits_2016'
		end
	elsif policy_plan.coverage_type == 'health'
		if policy_plan.metal_level.downcase == 'catastrophic'
			if year == '2015'
				return 'catastrophic_health_benefits_2015'
			elsif year == '2016'
				return 'catastrophic_health_benefits_2016'
			end
		else
			plan_variant = is_variant_plan(policy_plan)
			if plan_variant == '-02'
				if year == '2015'
					return 'individual_health_benefits_csr_100_2015'
				elsif year == '2016'
					return 'individual_health_benefits_csr_100_2016'
				end
			elsif plan_variant == '-04'
				if year == '2015'
					return 'individual_health_benefits_csr_73_2015'
				elsif year == '2016'
					return 'individual_health_benefits_csr_73_2016'
				end				
			elsif plan_variant == '-05'
				if year == '2015'
					return 'individual_health_benefits_csr_87_2015'
				elsif year == '2016'
					return 'individual_health_benefits_csr_87_2016'
				end
			elsif plan_variant == '-06'
				if year == '2015'
					return 'individual_health_benefits_csr_94_2015'
				elsif year == '2016'
					return 'individual_health_benefits_csr_94_2016'
				end
			else
				if year == '2015'
					return 'individual_health_benefits_2015'
				elsif year == '2016'
					return 'individual_health_benefits_2016'
				end
			end
		end
	end
end

def is_variant_plan(plan)
	variants = ['-02','-04','-05','-06']
	hios_id = plan.hios_plan_id
	which_variant = nil
	variants.each do |variant|
		if hios_id.match(variant) != nil
			which_variant = variant
		end
	end
	return which_variant
end

def return_subscriber_data(policy)
	subscriber_hbx_id = policy.subscriber.m_id
	subscriber_person = policy.subscriber.person
	subscriber_first_name = subscriber_person.name_first
	subscriber_middle_name = subscriber_person.name_middle
	subscriber_last_name = subscriber_person.name_last
	subscriber_authority_member = subscriber_person.authority_member
	subscriber_ssn = subscriber_authority_member.ssn
	subscriber_dob = subscriber_authority_member.dob.strftime('%m/%d/%Y')
	subscriber_gender = subscriber_authority_member.gender
	address = subscriber_person.home_address
	unless address == nil
		address_kind = address.address_type
		address_1 = address.address_1
		address_2 = address.address_2
		city = address.city
		state = address.state
		zip  = address.zip
	end
	phone = subscriber_person.home_phone
	unless phone == nil
		phone_type = phone.phone_type
		phone_number = phone.phone_number
	end
	email = subscriber_person.home_email
	unless email == nil
		email_type = email.email_type
		email_address = email.email_address
	end
	return [subscriber_hbx_id,subscriber_first_name,subscriber_middle_name,subscriber_last_name,
			subscriber_ssn,subscriber_dob, subscriber_gender,
			address_kind,address_1,address_2,city,state,zip,phone_type,phone_number,
			email_type,email_address]
end

def enroll_census_relationship(enrollee,person)
	if enrollee.rel_code == "self"
		return "self"
	elsif enrollee.rel_code == "spouse"
		return "spouse"
	elsif enrollee.rel_code == "child"
		effective_date = enrollee.coverage_start
		dob = person.authority_member.dob
		age = ((effective_date - dob).to_f)/365.25
		if age < 26
			return "child_under_26"
		elsif age >= 26
			return "disabled_child_26_and_over"
		end
	end
end

def return_dependent_data(enrollee)
	hbx_id = enrollee.m_id
	person = enrollee.person
	first_name = person.name_first
	middle_name = person.name_middle
	last_name = person.name_last
	authority_member = person.authority_member
	ssn = authority_member.ssn
	dob = authority_member.dob.strftime('%m/%d/%Y')
	gender = authority_member.gender
	relationship = enrollee.rel_code
	end_date = enrollee.coverage_end
	return [hbx_id,first_name,middle_name,last_name,ssn,dob,gender,relationship,end_date]
end

CSV.open("Redmine-#{redmine_ticket}_enrollments.csv", "w") do |csv|
	csv << ["Redmine Ticket","Employer Name","Employer FEIN",
			"HBX ID","First Name","Middle Name","Last Name","SSN","DOB","Gender",
			"Address Kind","Address 1","Address 2","City","State","Zip",
			"Phone Type","Phone Number",
			"Email Kind","Email Address",
			"AASM State",
			"Enrollment Group ID","Enrollment Kind","Benefit Begin Date", "Benefit End Date",
			"Plan Year","HIOS ID","Benefit Package/Benefit Group","Date Plan Selected","Relationship",
			"HBX ID (Dep 1)","First Name (Dep 1)","Middle Name (Dep 1)","Last Name (Dep 1)",
			"SSN (Dep 1)","DOB (Dep 1)","Gender (Dep 1)","Relationship (Dep 1)","Enrollee End Date (Dep 1)",
			"HBX ID (Dep 2)","First Name (Dep 2)","Middle Name (Dep 2)","Last Name (Dep 2)",
			"SSN (Dep 2)","DOB (Dep 2)","Gender (Dep 2)","Relationship (Dep 2)","Enrollee End Date (Dep 2)",
			"HBX ID (Dep 3)","First Name (Dep 3)","Middle Name (Dep 3)","Last Name (Dep 3)",
			"SSN (Dep 3)","DOB (Dep 3)","Gender (Dep 3)","Relationship (Dep 3)","Enrollee End Date (Dep 3)",
			"HBX ID (Dep 4)","First Name (Dep 4)","Middle Name (Dep 4)","Last Name (Dep 4)",
			"SSN (Dep 4)","DOB (Dep 4)","Gender (Dep 4)","Relationship (Dep 4)","Enrollee End Date (Dep 4)",
			"HBX ID (Dep 5)","First Name (Dep 5)","Middle Name (Dep 5)","Last Name (Dep 5)",
			"SSN (Dep 5)","DOB (Dep 5)","Gender (Dep 5)","Relationship (Dep 5)","Enrollee End Date (Dep 5)",
			"HBX ID (Dep 6)","First Name (Dep 6)","Middle Name (Dep 6)","Last Name (Dep 6)",
			"SSN (Dep 6)","DOB (Dep 6)","Gender (Dep 6)","Relationship (Dep 6)","Enrollee End Date (Dep 6)",]
	policies.each do |policy|
		unless plan_year_date.blank?
			next if policy.policy_start < plan_year_date
		end
		next if policy.canceled?
		employer = policy.employer
		if employer != nil
			employer_name = employer.name
			employer_fein = employer.fein.to_s
		else
			employer_name = 'IVL'
			employer_fein = ''
		end
		eg_id = policy.eg_id
		enrollment_kind = select_enrollment_kind(policy)
		effective_date = policy.subscriber.coverage_start.strftime('%m/%d/%Y')
		if !policy.subscriber.coverage_end.blank?
			end_date = policy.subscriber.coverage_end.strftime('%m/%d/%Y')
		end
		plan = policy.plan
		plan_year = plan.year.to_s
		hios_id = plan.hios_plan_id
		if policy.is_shop?
			benefits_package_group = ''
		else
			benefits_package_group = select_ivl_benefit_package(policy,plan,plan_year)
		end
		plan_selection_date = policy.created_at.strftime('%m/%d/%Y')
		subscriber_data = return_subscriber_data(policy)
		aasm_state = policy.aasm_state
		row_data = [redmine_ticket,employer_name,employer_fein]+subscriber_data+[aasm_state,eg_id,enrollment_kind,effective_date,end_date,plan_year,hios_id,benefits_package_group,
					  plan_selection_date,"self"]
		policy.enrollees.each do |enrollee|
			next if enrollee.rel_code == "self"
			dep_data = return_dependent_data(enrollee)
			row_data += dep_data
		end
		csv << row_data
	end
end

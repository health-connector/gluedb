puts "Report started at #{Time.now}"
policies = Policy.no_timeout.where(
  {"eg_id" => {"$not" => /DC0.{32}/},
   :enrollees => {"$elemMatch" =>
      {:rel_code => "self",
            :coverage_start => {"$gt" => Date.new(2015,12,31)}}}}
)

policies = policies.reject{|pol| pol.market == 'individual' && !pol.subscriber.nil? &&(pol.subscriber.coverage_start.year == 2014||pol.subscriber.coverage_start.year == 2015) }

policies_list = []

policies.each do |pol|
  if pol.hbx_enrollment_ids.blank?
    id_list = [pol.eg_id]
  else
    id_list = ([pol.eg_id]+pol.hbx_enrollment_ids).uniq
  end
  id_list.each do |id|
    policies_list << id
  end
end

enroll_list = File.read("all_enroll_policies.txt").split("\n").map(&:strip)

missing_ids = (policies_list-enroll_list)

missing = Policy.or({:hbx_enrollment_ids => {"$in" => missing_ids}},{:eg_id => {"$in" => missing_ids}}).no_timeout

puts "Glue Total: #{policies_list.uniq.size}"
puts "Enroll Total: #{enroll_list.uniq.size}"
puts "Total Missing: #{missing.size}"


def bad_eg_id(eg_id)
  (eg_id =~ /\A000/) || (eg_id =~ /\+/)
end

timestamp = Time.now.strftime('%Y%m%d%H%M')

count = 0

Caches::MongoidCache.with_cache_for(Carrier, Plan, Employer) do
  CSV.open("enrollments_in_glue_but_not_in_enroll_#{timestamp}.csv","w") do |csv|
    csv << ["Subscriber HBX ID", "Enrollee HBX ID", "Enrollment HBX ID", "First Name","Last Name","SSN","DOB","Gender","Relationship to Subscriber",
            "Plan Name", "Plan HIOS ID", "Plan Metal Level", "Carrier Name",
            "Premium for Enrollee", "Premium Total for Policy","APTC/Employer Contribution",
            "Enrollee Coverage Start","Enrollee Coverage End",
            "Employer Name","Employer DBA","Employer FEIN","Employer HBX ID",
            "Home Address","Mailing Address","Home Email", "Work Email","Home Phone Number", "Work Phone Number", "Mobile Phone Number",
            "Broker Name", "Broker NPN",
            "AASM State"]
    puts "#{Time.now} - #{count}/#{missing.size}"
    missing.each do |pol|
      count += 1
      puts "#{Time.now} - #{count}/#{missing.size}" if count % 1000 == 0
      puts "#{Time.now} - #{count}/#{missing.size}" if count == missing.size
      unless bad_eg_id(pol.eg_id)
        subscriber_hbx_id = pol.subscriber.m_id rescue ""
        enrollment_id = pol.eg_id
        plan = Caches::MongoidCache.lookup(Plan, pol.plan_id) { pol.plan }
        plan_name = plan.name
        plan_hios = plan.hios_plan_id
        plan_metal = plan.metal_level
        carrier_name = plan.carrier.name
        premium_total = pol.pre_amt_tot
        if pol.is_shop?
          external_contribution = pol.tot_emp_res_amt
          employer = Caches::MongoidCache.lookup(Employer, pol.employer_id) { pol.employer }
          employer_name = employer.name
          employer_dba = employer.dba
          employer_fein = employer.fein
          employer_hbx_id = employer.hbx_id
        else
          external_contribution = pol.applied_aptc
        end
        if pol.broker
          broker_name = pol.broker.full_name rescue ""
          broker_npn = pol.broker.npn rescue ""
        end
        aasm_state = pol.aasm_state
        pol.enrollees.each do |enr|
          enrollee_hbx_id = enr.m_id
          person = enr.person
          member = person.members.detect{|m| m.hbx_member_id == enrollee_hbx_id}
          first_name = person.name_first
          last_name = person.name_last
          ssn = member.ssn
          dob = member.dob
          gender = member.gender
          relationship = enr.rel_code
          enr_premium = enr.pre_amt
          enr_coverage_start = enr.coverage_start
          enr_coverage_end = enr.coverage_end
          home_address = person.home_address.try(:full_address)
          mailing_address = person.mailing_address.try(:full_address)
          home_email = person.home_email.try(:email_address)
          work_email = person.work_email.try(:email_address)
          home_phone = person.home_phone.try(:phone_number)
          work_phone = person.work_phone.try(:phone_number)
          mobile_phone = person.mobile_phone.try(:phone_number)
          csv << [subscriber_hbx_id, enrollee_hbx_id, enrollment_id, first_name, last_name, ssn, dob, gender, relationship, plan_name, plan_hios, plan_metal, carrier_name, 
                  enr_premium, premium_total, external_contribution, enr_coverage_start, enr_coverage_end, employer_name, employer_dba, employer_fein, employer_hbx_id, 
                  home_address, mailing_address, home_email, work_email, home_phone, work_phone, mobile_phone, broker_name, broker_npn, aasm_state]
        end
      end
    end
  end
end

puts "Report finished at #{Time.now}"

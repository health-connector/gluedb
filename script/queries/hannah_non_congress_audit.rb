require 'csv'

congress_feins = %w{
}

emp_ids = Employer.where(:fein => { "$nin" => congress_feins }).map(&:id)

policies = Policy.where({
       :enrollees => {"$elemMatch" => {
              :rel_code => "self", 
                   :coverage_start => {"$gt" => Date.new(2014,4,30) }
       }}, :employer_id => { "$in" => emp_ids } })

plan_hash = Plan.all.inject({}) do |acc, p|
  acc[p.id] = p
  acc
end

carrier_hash = Carrier.all.inject({}) do |acc, c|
  acc[c.id] = c
  acc
end

Caches::MongoidCache.allocate(Employer)

CSV.open("hannah_non_congress_report.csv", 'w') do |csv|
  csv << ["First Name", "Middle Name", "Last Name", "DOB", "SSN", "Employer", "FEIN", "HIOS ID", "Plan Name", "Dependents", "Premium Total", "Employer Responsible", "Employee Responsible", "Start", "End"]
  policies.each do |pol|
    subscriber = pol.subscriber
    begin
      if !pol.canceled?
        if !(pol.coverage_period_end < Date.new(2015,4,1))
          sub_person = subscriber.person
          if (sub_person.authority_member.hbx_member_id == subscriber.m_id)
            deps = pol.enrollees.count - 1
            employer = Caches::MongoidCache.lookup(Employer, pol.employer_id)
            csv << [
              sub_person.name_first,
              sub_person.name_middle,
              sub_person.name_last,
              sub_person.authority_member.dob.strftime("%Y-%m-%d"),
              sub_person.authority_member.ssn,
              employer.name,
              employer.fein,
              plan_hash[pol.plan_id].hios_plan_id,
              plan_hash[pol.plan_id].name,
              deps,
              pol.pre_amt_tot,
              pol.tot_emp_res_amt,
              pol.tot_res_amt,
              subscriber.coverage_start.strftime("%Y-%m-%d"),
              (subscriber.coverage_end.blank? ? "" : subscriber.coverage_end.strftime("%Y-%m-%d"))
            ]
          end
        end
      end
    rescue
      raise subscriber.person.inspect
    end
  end
end

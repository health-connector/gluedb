require 'csv'

policies = Policy.no_timeout.where(
  {"eg_id" => {"$not" => /DC0.{32}/}}
)

def bad_eg_id(eg_id)
  (eg_id =~ /\A000/) || (eg_id =~ /\+/)
end

Caches::MongoidCache.with_cache_for(Carrier, Plan, Employer) do

  CSV.open("stephen_expected_effectuated_20140930.csv", 'w') do |csv|
    csv << ["Subscriber ID", "Member ID" , "Person ID", "Policy ID",
            "First Name", "Last Name", "DOB",
            "Plan Name", "HIOS ID", "Carrier Name",
            "Premium Amount", "Premium Total", "Policy APTC", "Policy Employer Contribution",
            "Coverage Start", "Coverage End",
            "Employer Name","Address"]
    policies.each do |pol|
      if !bad_eg_id(pol.eg_id)
        if !pol.subscriber.nil?
          if !pol.subscriber.canceled?
            subscriber_id = pol.subscriber.m_id
            subscriber_member = pol.subscriber.member
            auth_subscriber_id = subscriber_member.person.authority_member_id

            if !auth_subscriber_id.blank?
              if subscriber_id != auth_subscriber_id
                next
              end
            end
            plan = Caches::MongoidCache.lookup(Plan, pol.plan_id) {
              pol.plan
            }
            carrier = Caches::MongoidCache.lookup(Carrier, pol.carrier_id) {
              pol.carrier
            }
            employer = nil
            if !pol.employer_id.blank?
            employer = Caches::MongoidCache.lookup(Employer, pol.employer_id) {
              pol.employer
            }
            end
            pol.enrollees.each do |en|
              if !en.canceled?
                per = en.person
                csv << [
                  subscriber_id, en.m_id, per.id, pol.id,
                  per.name_first,
                  per.name_last,
                  en.member.dob.strftime("%Y%m%d"),
                  plan.hios_plan_id, plan.name, carrier.name,
                  en.pre_amt, pol.pre_amt_tot,pol.applied_aptc, pol.tot_emp_res_amt,
                  en.coverage_start.blank? ? nil : en.coverage_start.strftime("%Y%m%d"),
                  en.coverage_end.blank? ? nil : en.coverage_end.strftime("%Y%m%d"),
                  pol.employer_id.blank? ? nil : employer.name,
                  per.mailing_address.try(:full_address) || pol.subscriber.person.mailing_address.try(:full_address)
                ]
              end
            end
          end
        end
      end
    end
  end

end

require 'csv'

policies = Policy.no_timeout.where(
  {
    "eg_id" => {"$not" => /DC0.{32}/},
    employer: nil,
    "enrollees.coverage_start" => {"$gte" => Date.new(2015,1,1)}
  }
)

def bad_eg_id(eg_id)
  (eg_id =~ /\A000/) || (eg_id =~ /\+/)
end

Caches::MongoidCache.with_cache_for(Carrier, Plan, Broker) do

  CSV.open("hannah_broker_20150101.csv", 'w') do |csv|
    csv << ["Subscriber ID", "Member ID", "Enrollment Group ID",
            "First Name", "Last Name","SSN", "DOB",
            "Plan Name", "HIOS ID", "Carrier Name",
            "Premium Amount", "Premium Total", "Policy APTC", "Policy Employer Contribution",
            "Coverage Start", "Coverage End", "Broker Name", "Broker NPN"]
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
            broker = OpenStruct.new(:name_full => nil, :npn => nil)
            if !pol.broker_id.blank?
              broker = Caches::MongoidCache.lookup(Broker, pol.broker_id) {
                pol.broker
              }
            end
            pol.enrollees.each do |en|
              if !en.canceled?
                per = en.person
                csv << [
                  subscriber_id, en.m_id, pol.eg_id,
                  per.name_first,
                  per.name_last,
                  en.member.ssn,
                  en.member.dob.strftime("%Y%m%d"),
                  plan.hios_plan_id, plan.name, carrier.name,
                  en.pre_amt, pol.pre_amt_tot,pol.applied_aptc, pol.tot_emp_res_amt,
                  en.coverage_start.blank? ? nil : en.coverage_start.strftime("%Y%m%d"),
                  en.coverage_end.blank? ? nil : en.coverage_end.strftime("%Y%m%d"),
                  broker.nil? ? nil : broker.name_full,
                  broker.nil? ? nil : broker.npn
                ]
              end
            end
          end
        end
      end
    end
  end

end

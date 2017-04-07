require 'csv'

field_names= %w(
                Subscriber_name,
                Subscriber_policy_id,
                Subscriber_enrollment_start,
                Subscriber_enrollment_end,
                Employer_legal_name,
                Employer_next_plan_year_start,
                Employer_next_plan_year_end
               )


CSV.open('report_of_ees_not_renewing.csv', 'w') do |csv|
  csv << field_names

end

## Loop through employers
new_plan_year_start_date = (Date.today.end_of_month) + 1.day

def find_current_plan_year(employer)
  check_date = Date.today
  correct_plan_year = employer.plan_years.where(:start_date => {"$lte" => check_date}, :end_date => {"$gte" => check_date})
  return correct_plan_year
end

def find_renewal_plan_year(employer)
  check_date = (Date.today.end_of_month)+1.day
  correct_plan_year employer.plan_years.where(:start_date => check_date).first
  return correct_plan_year
end

Employer.each do |employer|
  current_plan_year = find_current_plan_year(employer)
  renewal_plan_year = find_renewal_plan_year(employer)
  if renewal_plan_year.present?
    employer_policies = Policy.where(:employer_id => employer._id, :enrollees => {"$elemMatch" => {
                                                                                    :rel_code => "self",
                                                                                    :coverage_start => {"$gte" => current_plan_year.start_on,
                                                                                                        "$lte" => current_plan_year.end_on},
                                                                                    :coverage_end => nil
    }})
    people=employer_policies.map(&:subscriber).map(&:person).uniq
    people.each do |person|
      #check whether the person has non_terminated policy in current plan year
      #check whether the person has non_active policy in the next plan year
      #out put the person

      current_plan_year_effective_dates = (current_plan_year.start_date..current_plan_year.end_date)
      renewal_plan_year_effective_dates = (renewal_plan_year.start_date..renewal_plan_year.end_date)
      non_terminated_current_health_policy= person.policies.to_a.select{|pol| current_plan_year_effective_dates.include?(pol.policy_start) && 
                                                                         pol.employer_id == employer._id &&
                                                                         pol.coverage_type == 'health' &&
                                                                         !pol.canceled? &&
                                                                         !pol.terminated? 
                                                                         }.sort_by{|pol| pol.policy_start}.last
      active_renew_health_policy= person.policies.select{|pol| renewal_plan_year_effective_dates.include?(pol.policy_start) && 
                                                               pol.employer_id == employer._id &&
                                                               pol.coverage_type == 'health' && 
                                                               !pol.canceled? 
                                                                }.sort_by{|pol| pol.policy_start}.last

      non_terminated_current_dental_policy= person.policies.select{|pol| current_plan_year_effective_dates.include?(pol.policy_start) && 
                                                                         pol.employer_id == employer._id &&
                                                                         pol.coverage_type == 'dental' &&
                                                                         !pol.canceled? && 
                                                                         !pol.terminated?}.sort_by{|pol| pol.policy_start}.last
      active_renew_dental_policy= person.policies.select{|pol| renewal_plan_year_effective_dates.include?(pol.policy_start) && 
                                                               pol.employer_id == employer._id &&
                                                               pol.coverage_type == 'dental' &&
                                                               !pol.canceled?}.sort_by{|pol| pol.policy_start}.last

      if non_terminated_current_dental_policy && active_renew_dental_policy.nil? &&non_terminated_current_health_policy && active_renew_health_policy.nil?
        csv << [
            person.full_name
            non_terminated_current_dental_policy.eg_id
            non_terminated_current_dental_policy.policy_start
            non_terminated_current_dental_policy.policy_end
            employer.name
            employer.plan_year.start_on
            employer.plan_year.end_on
        ]
        csv << [
            person.full_name
        non_terminated_current_health_policy.eg_id
        non_terminated_current_health_policy.policy_start
        non_terminated_current_health_policy.policy_end
        employer.name
        employer.plan_year.start_on
        employer.plan_year.end_on
        ]
      elsif non_terminated_current_health_policy && active_renew_health_policy.nil?
        csv << [
            person.full_name
           non_terminated_current_health_policy.eg_id
           non_terminated_current_health_policy.policy_start
           non_terminated_current_health_policy.policy_end
           employer.name
          employer.plan_year.start_on
          employer.plan_year.end_on
        ]
      elsif  non_terminated_current_dental_policy && active_renew_dental_policy.nil?
        csv << [
            person.full_name
        non_terminated_current_dental_policy.eg_id
        non_terminated_current_dental_policy.policy_start
        non_terminated_current_dental_policy.policy_end
        employer.name
        employer.plan_year.start_on
        employer.plan_year.end_on
        ]

      end

    end

    end
  end
end

#get the employer with certain plan year
#get the policy using the employer_id and the start date



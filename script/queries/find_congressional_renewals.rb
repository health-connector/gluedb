
congressional_feins = %w()

congressional_employers = Employer.where(:fein => {"$in" => congressional_feins}).map(&:id)

plans_2017 = Plan.where(year: 2017).map(&:id)

congressional_policies_2017 = Policy.where(:employer_id => {"$in" => congressional_employers},
                                           :plan_id => {"$in" => plans_2017},
                                           :enrollees => {"$elemMatch" => {
                                              :rel_code => "self",
                                              :coverage_start => {"$gt" => Date.new(2016,12,31)}
                                            }})

def renewal_or_initial(policy)
  if policy.transaction_set_enrollments.any?{|tse| tse.transaction_kind == "initial_enrollment"}
    return "initial"
  else
    return "renewal"
  end
end

renewal_enrollments = []

initial_enrollments = []

congressional_policies_2017.each do |pol|
  result = renewal_or_initial(pol)
  if result == "initial"
    initial_enrollments << pol
  elsif result == "renewal"
    renewal_enrollments << pol
  end
end

initial_en = File.new("congressional_initial_enrollments.txt","w")

initial_enrollments.each do |ie|
  initial_en.puts(ie.eg_id)
end

renewal_en = File.new("congressional_renewals.txt","w")

renewal_enrollments.each do |re|
  renewal_en.puts(re.eg_id)
end
# Takes a list of enrollment group IDs in an array and filters them into initial and shop renewals.
eg_ids = %w()

policies = Policy.where(:eg_id => {"$in" => eg_ids})

found = policies.map(&:eg_id)

not_found = eg_ids - found

def renewal_or_initial(policy)
  if policy.transaction_set_enrollments.any?{|tse| tse.transaction_kind == "initial_enrollment"}
    return "initial"
  else
    return "renewal"
  end
end

renewal_enrollments = []

initial_enrollments = []

policies.each do |pol|
  result = renewal_or_initial(pol)
  if result == "initial"
    initial_enrollments << pol
  elsif result == "renewal"
    renewal_enrollments << pol
  end
end

initial_enrollments.sort!

renewal_enrollments.sort!

initial_en = File.new("initial_enrollments.txt","w")

initial_enrollments.each do |ie|
  initial_en.puts(ie.eg_id)
end

renewal_en = File.new("renewal_enrollments.txt","w")

renewal_enrollments.each do |re|
  renewal_en.puts(re.eg_id)
end

not_found_file = File.new("enrollment_not_found.txt","w")

not_found.each do |nf|
  not_found_file.puts(nf)
end
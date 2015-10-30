file = "/Users/CitadelFirm/Downloads/policies-for-aptc/matched_policies.csv"

def person_match(first_name, ssn, dob)
  dob = Date.strptime(dob, "%m/%d/%Y")
  people = Person.unscoped.where({"members.ssn" => ssn}).and({"members.dob" => dob}).and({"name_first" => first_name}).to_a
  puts "multiple matches" if people.length > 1
  return people
end

def get_policy(row)
  Policy.new #will plug in real policies later
end

def compute_aptc(premium, plan, max_aptc, percent)
  if max_aptc*percent > premium*plan.ehb
    return premium*plan.ehb
  else
    return max_aptc*percent
  end
end

def update_policy(policy, row)
  max_aptc = row[12].to_i || 0.0
  percent = row[16].to_f
  premium = row[7].to_f
  csr = row[13].to_i || nil
  #puts "#{max_aptc} #{percent} #{premium} #{csr}"
  policy.allocated_aptc = max_aptc
  policy.elected_aptc = policy.allocated_aptc * percent
  policy.applied_aptc = compute_aptc( premium, policy.plan, max_aptc, percent) #compute_aptc(premium, plan, max_aptc, percent)
  policy.csr_amt = csr
  policy.save
  puts "allocated_aptc #{policy.allocated_aptc} elected_aptc #{policy.elected_aptc} applied_aptc #{policy.applied_aptc} csr_amt #{policy.csr_amt}"
end

CSV.foreach(File.path(file), :headers=>true) do |row|
  people = person_match(row[0], row[3], row[2])
  policy = nil
  if people.present?
    person = people.first
    if row[17] == "No Valid Policies"
      #puts "#{row[0]} #{row[1]} multiple policies found"
      next
    else
      policy = Policy.where(id: row[17]).first
    end
    puts "#{row[0]} #{row[1]} #{row[2]} #{row[3]}"
    update_policy(policy, row)
  else
    puts "NOT FOUND #{row[0]} #{row[1]}"
  end
end
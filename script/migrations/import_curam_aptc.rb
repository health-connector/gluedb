file = "/Users/CitadelFirm/Downloads/enrollment_data_102815.csv"

def person_match(first_name, ssn, dob)
  dob = Date.strptime(dob, "%m/%d/%Y")
  people = Person.unscoped.where({"members.ssn" => @ssn}).and({"members.dob" => dob}).and({"name_first" => first_name})
  puts "multiple matches" if people.length > 1
  return people
end

def get_policy(person)
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
  policy.allocated_aptc = row[12]
  policy.elected_aptc = policy.allocated_aptc * row[16]
  policy.applied = compute_aptc( row[7], plan, row[12], row[16]) #compute_aptc(premium, plan, max_aptc, percent)
  policy.csr_amt = row[13] || nil
end

CSV.foreach(File.path(file), :headers=>true) do |row|
  persons = person_match(row[0], row[3], row[2])
  if persons
    person = persons.first
    update_policy(get_policy(person), row)
    puts "FOUND #{row[0]} #{row[1]} #{row[2]} #{row[3]}"
  else
    puts "NOT FOUND #{row[0]} #{row[1]} #{row[3]} #{row[2]}"
  end
end
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
  policy.aptc_maximums << AptcMaximum.new({start_on: Date.new(2016, 01, 01),
                                           max_aptc:row[12],
                                           aptc_percent:row[16]})

  policy.aptc_maximums << AptcMaximum.new({start_on: policy.policy_start,
                                           end_on: Date.new(2015, 12, 31),
                                           max_aptc:row[15],
                                           aptc_percent:row[16]})

  policy.cost_sharing_variants << CostSharingVariant.new(start_on: Date.new(2016, 01, 01),
                                                         percent: row[13])

  aptc_credit =  AptcCredit.new({start_on: Date.new(2016, 01, 01),
                                         aptc: compute_aptc( row[7], plan, row[12], row[16]),
                                         pre_amt_tot: row[7]
                                        })
  tot_res_amt = row[7] - aptc_credit.aptc
  aptc_credit.tot_res_amt = tot_res_amt < 0 ? 0 : tot_res_amt

  policy.aptc_credits << aptc_credit

  policy.save

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
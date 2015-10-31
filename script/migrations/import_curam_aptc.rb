file = "/Users/CitadelFirm/Downloads/policies-for-aptc/matched_policies.csv"
@logger = Logger.new("#{Rails.root}/log/curam_aptc_import#{Time.now.to_s.gsub(' ', '')}.log")

def person_match(first_name, ssn, dob)
  dob = Date.strptime(dob, "%m/%d/%Y")
  people = Person.unscoped.where({"members.ssn" => ssn}).and({"members.dob" => dob}).and({"name_first" => first_name}).to_a
  puts "multiple matches" if people.length > 1
  return people
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
  max_aptc_2015 = row[15].to_i || 0.0

  aptc_maximum_2016 = AptcMaximum.new({start_on: Date.new(2016, 01, 01),
                                       max_aptc:max_aptc,
                                       aptc_percent:percent})
  policy.aptc_maximums << aptc_maximum_2016

  aptc_maximum_2015 =  AptcMaximum.new({start_on: policy.policy_start,
                                        end_on: Date.new(2015, 12, 31),
                                        max_aptc:max_aptc_2015,
                                        aptc_percent:percent})
  policy.aptc_maximums << aptc_maximum_2015

  cost_sharing_variant = CostSharingVariant.new(start_on: Date.new(2016, 01, 01),
                                                percent: csr)
  policy.cost_sharing_variants << cost_sharing_variant

  aptc_credit =  AptcCredit.new({start_on: Date.new(2016, 01, 01),
                                         aptc: compute_aptc( premium, policy.plan, max_aptc, percent),
                                         pre_amt_tot: premium
                                        })

  tot_res_amt = premium - aptc_credit.aptc
  aptc_credit.tot_res_amt = tot_res_amt < 0 ? 0 : tot_res_amt

  policy.aptc_credits << aptc_credit

  @logger.info "#{row[0]},#{row[1]},#{row[2]},#{row[4]},#{aptc_maximum_2016.max_aptc},#{aptc_maximum_2016.aptc_percent},#{aptc_maximum_2015.max_aptc},#{aptc_maximum_2015.aptc_percent}"

  policy.save
end

CSV.foreach(File.path(file)) do |row|
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
    update_policy(policy, row)
  else
    puts "NOT FOUND #{row[0]} #{row[1]}"
  end
end
require 'pry'

## IVL

employer_ids = []

Employer.each do |emp|
	employer_ids.push(emp._id)
end

cf_pol = Policy.where(:employer_id.nin => employer_ids).where(:carrier_id => "")
kp_pol = Policy.where(:employer_id.nin => employer_ids).where(:carrier_id => "")
aetna_pol = Policy.where(:employer_id.nin => employer_ids).where(:carrier_id => "")

cf_count = cf_pol.count
kp_count = kp_pol.count
aetna_count = aetna_pol.count

aetna_2014 = []
aetna_2015 = []

aetna_pol.each do |pol|
	year = pol.plan.year
	if year == 2014
		aetna_2014.push(pol)
	elsif year==2015
		aetna_2015.push(pol)
	end
end

aetna_count_2014 = aetna_2014.count
aetna_count_2015 = aetna_2015.count

puts "CareFirst: #{cf_count}"
puts "Kaiser: #{kp_count}"
puts "Aetna Total: #{aetna_count}"
puts "Aetna 2014: #{aetna_count_2014}"
puts "Aetna 2015: #{aetna_count_2015}"
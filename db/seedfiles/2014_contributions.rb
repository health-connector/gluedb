require 'csv'

def clean_percentage(val)
  return 0.00 if val.blank?
  val.strip.gsub("%","").to_f / 100
end

missing = Employer.all.select do |e|
  plan_year = e.plan_year_of(Date.parse('2014-12-31'))
  plan_year.contribution_strategy.nil? unless plan_year.nil?
end

results = missing.map{ |e| [e.fein,nil,nil,nil,e.plan_years.first.start_date.strftime("%m/%d/%Y")]}

csv_loc = File.join(File.dirname(__FILE__), "shop_cont.csv")

CSV.foreach(File.open(csv_loc), headers: true) do |row|
  clean_fein = row["FEIN"].gsub("-","") if row["FEIN"].present?
  if results.any?{|array| array.include?(clean_fein)}
    result_row = results.select{|array| array.include?(clean_fein)}.first
    result_row[1] = clean_percentage(row["EE CONTRIBUTION"])
    result_row[2] = clean_percentage(row["DEP CONTRIBUTION"])
    result_row[3] = row["HIOS"]
  end
end

File.open("results.csv", "w") {|f| f.write(results.inject([]) { |csv, row|  csv << CSV.generate_line(row) }.join(""))}

# missing.each do |e|

# end

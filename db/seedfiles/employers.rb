puts "Loading Employers"

# Employer.collection.drop
require 'csv'

# PlanYear.delete_all
glob_pat = File.join(File.dirname(__FILE__), "employer_groups", "*.xml")

Dir.glob(glob_pat).each do |f|
  puts f
  f_in = File.open(f, 'r')
  import = ImportEmployerDemographics.new
  import.execute(f_in)
  f_in.close
  puts f
end

c_hash = Hash[(Carrier.all.map { |c| [c.abbrev, c]}) ]

gid_file = File.join(File.dirname(__FILE__), "employer_group_ids.csv")

CSV.foreach(gid_file, headers: true) do |row|
  record = row.to_hash
  hbx_id = record['HBX_ID']
  emp = Employer.where(:hbx_id => hbx_id).first
  if emp
    pys = emp.plan_years
    pys.each do |py|
      c_hash.each_pair do |k,v|
        if !record["#{k}_01"].blank?
          py.update_group_ids(c_hash[k]._id, record["#{k}_01"])
        end
      end
      py.save!
    end
  else
    puts "Couldn't find: #{record['FEIN']} - #{record['HBX_ID']} - #{record['NAME']}"
  end
end

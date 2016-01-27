require 'csv'

hbx_oracle = CSV.read("enrollment.csv", headers: true)
bizz = CSV.read("bizz.csv", headers: true)

hbx_eg_ids = hbx_oracle['curam_enroll_id'].map{|id| id.gsub(/\[?"?"?\]?/,"").strip}
hbx_timestamp = hbx_oracle['time'].map{|t| Date.parse(t).strftime("%Y%m%d%H%M%S") }

result = []
CSV.foreach("enrollment.csv", :headers => true) do |row|
  result << "#{row['time']}_#{row['curam_enroll_id'].gsub(/\[?"?"?\]?/,"").strip}"
end

puts result

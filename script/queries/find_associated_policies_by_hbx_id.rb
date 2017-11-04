# This script is designed to take a spreadsheet generated from graylog and find the associated policies for a specific person for them. 
require 'csv'

graylog_filename = 'graylog-searchresult.csv'

output_filename = "#{graylog_filename}_policy_data.csv"

total_count = 0

CSV.foreach(graylog_filename, headers: true) do |row|
  total_count += 1
end

puts "Finished Counting at #{Time.now}"

count = 0

CSV.open(output_filename,"w") do |csv|
  csv << ["timestamp","source","individual_id","message","enrollment_id","last_transaction_timestamp","last_updated_timestamp"]
  CSV.foreach(graylog_filename, headers: true) do |row|
    count += 1
    puts "#{Time.now} - #{count}/#{total_count}" if count % 100 == 0
    hbx_id = row['individual_id']
    policies = Policy.where("enrollees.m_id" => hbx_id)
    policies.each do |policy|
      policy_year = policy.plan.year rescue next
      next if policy_year < 2016
      last_transaction_timestamp = policy.transaction_set_enrollments.sort_by{|tse| tse.submitted_at}.last.submitted_at rescue nil
      updated_at = policy.updated_at
      csv << [row['timestamp'],row['source'],row['individual_id'],row['message'],policy.eg_id, last_transaction_timestamp, updated_at]
    end
    csv << []
  end
end
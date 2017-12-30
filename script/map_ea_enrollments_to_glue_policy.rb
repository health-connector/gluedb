# parse the text file to extract the hbx_id's of the enrollments whose
# status is not shopping


enrollment_ids = []
file = "resident_enrollments_in_ea.txt"
output = "ea_to_glue_enrollments_map.txt"
enrollments_map = "ea_coverall_enrollments_to_glue_policy_map.txt"
enrollments_not_found = "ea_coverall_enrollments_not_found_in_glue.txt"
o = File.open(output, "w")
f = File.open(file, "r")
e_map = File.open(enrollments_map, "w")
not_found_enrollments = File.open(enrollments_not_found, "w")
f.readlines.each do |line|
  temp = line.split(",")
  temp[2].chomp!
  #store enrollments that were not in shopping aasm_state
  if temp[2] != "shopping" && temp[2] != "enrollment status"
    enrollment_ids << temp[1]
    o.puts(temp[1])
  end
end
puts enrollment_ids
puts enrollment_ids.size
f.close
o.close

### Rails Part ###

# feed the id's to Glue to find which policy contains the EA enrollment
# results will be key-value pairs stored in an array where the key is the EA
# hbx_id and the value is the Policy.eg_id in glue that it maps to
ea_to_glue_map = []
ea_enrollments_not_found = []

policies = Policy.all.to_a

enrollment_ids.each do |hbx_id|
  not_found = true
  policies.each do |policy|
    result = policy.hbx_enrollment_ids.detect{|policy_enrollment_id| policy_enrollment_id == hbx_id}
    # store if found
    if result
      ea_to_glue_map << {hbx_id => policy.eg_id}
      puts "found #{hbx_id}"
      e_map.puts({hbx_id => policy.eg_id})
      not_found = false
    end
  end
  if not_found
    ea_enrollments_not_found << hbx_id
    not_found_enrollments.puts(hbx_id)
    puts "did not find #{hbx_id}"
  end
  not_found = true
end
puts "did not find #{ea_enrollments_not_found.size} enrollments"

# close remaining resources
e_map.close
not_found_enrollments.close

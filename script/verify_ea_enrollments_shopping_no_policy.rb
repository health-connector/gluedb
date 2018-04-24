# parse the text file to extract the hbx_id's of the enrollments whose status is shopping

enrollment_ids = []
file = "resident_enrollments_in_ea.txt"
output = "ea_enrollments_to_verify_no_policy_in_glue.txt"
incorrect_map = "ea_coverall_enrollments_to_glue_policy_map_incorrect.txt"
enrollments_not_found = "ea_coverall_enrollments_not_found_in_glue_verified.txt"
o = File.open(output, "w")
f = File.open(file, "r")
i_map = File.open(incorrect_map, "w")
not_found_enrollments = File.open(enrollments_not_found, "w")
f.readlines.each do |line|
  temp = line.split(",")
  temp[2].chomp!

  # make sure data contains all the fields we expect it to
  if temp[2].blank?
    raise ArgumentError, 'Argument cannot be blank. Check data coming from EA query. Missing aasm_state.'
  end

  #store enrollments that are in shopping aasm_state
  if temp[2] == "shopping"
    enrollment_ids << temp[1]
    o.puts(temp[1])
  end
end
puts enrollment_ids
puts enrollment_ids.size
f.close
o.close
# output file contains all the coverall enrollments that are in the shopping state
### Rails Part ###

# feed the id's to Glue to verify that there is no policy that contains them
ea_to_glue_map = []
ea_enrollments_not_found = []

# policies = Policy.all.to_a

enrollment_ids.each do |hbx_id|
  not_found = true
  policies  = Policy.where(:hbx_enrollment_ids.in => [hbx_id])
  policies.each do |policy|
    result = policy.hbx_enrollment_ids.detect{|policy_enrollment_id| policy_enrollment_id == hbx_id}
    # store if found
    if result
      ea_to_glue_map << {hbx_id => policy.eg_id}
      puts "found #{hbx_id}"
      i_map.puts({hbx_id => policy.eg_id})
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
i_map.close
not_found_enrollments.close

# if everything is correct the text file ea_coverall_enrollments_to_glue_policy_map_incorrect.txt
# should be empty and the text file ea_coverall_enrollments_not_found_in_glue_verified.txt should be
# identical to ea_enrollments_to_verify_no_policy_in_glue.txt

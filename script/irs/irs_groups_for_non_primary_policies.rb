@logger = Logger.new("#{Rails.root}/log/irs_groups_for_non_primary_policies_#{Time.now.to_s.gsub(' ', '')}.log")

Family.all.to_a.each do |family|

  next if family.irs_groups.length > 0

  if family.households.flat_map(&:hbx_enrollments).length > 0
    irs_group = family.irs_groups.build
    irs_group.save!
    family.active_household.irs_group_id = irs_group._id
    family.save!

    @logger.info "Family #{family.e_case_id} created IRS Group #{family.active_household.irs_group.hbx_assigned_id}"
  end
end
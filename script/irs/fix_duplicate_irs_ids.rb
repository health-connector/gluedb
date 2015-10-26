@logger = Logger.new("#{Rails.root}/log/fix_duplicate_irs_ids#{Time.now.to_s.gsub(' ', '')}.log")

incrementor = MongoidAutoIncrement::Incrementor.new
irs_groups = Family.all.flat_map(&:irs_groups);
irs_ids = irs_groups.map(&:hbx_assigned_id);
dup_irs_ids = irs_ids.select{ |e| irs_ids.count(e) > 1 };
dup_irs_ids.map do |irs_id|
  family = Family.where("irs_groups.hbx_assigned_id" => irs_id).last
  irs_group = family.irs_groups.first
  irs_group.hbx_assigned_id = incrementor.inc('irsgroup_hbx_assigned_id', {})
  irs_group.save
  family.save
  @logger.info "Updated Family #{family.e_case_id} IRS Group #{irs_group.hbx_assigned_id}"
end
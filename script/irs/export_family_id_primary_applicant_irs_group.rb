#This script will export to csv e_case_id, primary_applicant.id, irs_group.hbx_assigned_id for every family in db
#To run
# rails r script/irs/export_family_id_primary_applicant_irs_group.rb
require 'csv'

def normalize_primary_applicant_id(family)
  if family.primary_applicant.nil?
    ""
  else
    family.primary_applicant.id
  end
end

def normalize_irs_group_hbx_assigned_id(family)
  if family.active_household.nil?
    ""
  elsif family.active_household.irs_group.nil?
    ""
  else
    family.active_household.irs_group.hbx_assigned_id
  end
end

csv = CSV.open('irs_groups.csv', 'w')
@logger = Logger.new("#{Rails.root}/log/irs_groups_export_#{Time.now.to_s.gsub(' ', '')}.log")

Family.all.each do |family|

  begin
    csv << [family.e_case_id, normalize_primary_applicant_id(family), normalize_irs_group_hbx_assigned_id(family)]
  rescue Exception => e
    @logger.error "family.e_case_id #{family.e_case_id} " + e.message
  end

end



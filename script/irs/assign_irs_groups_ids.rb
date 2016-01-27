#This script will read the e_case_ids from the csv and assign corresponding irs_groups to the matching Families in glue.
# This will help us retain the irs_group_ids even after we make a new curam import. If e_case_id does not match we match the primary_applicant.person.id
#To run
# rails r script/irs/assign_irs_groups.rb
require 'csv'

@logger = Logger.new("#{Rails.root}/log/irs_groups_ids_assignment_#{Time.now.to_s.gsub(' ', '')}.log")

csv_file = ""

CSV.foreach('/Users/CitadelFirm/Downloads/projects/hbx/gluedb/irs_groups.csv') do |row|

  if row[0].blank? || row[1].blank? || row[2].blank?
    @logger.info "Blank input #{row[0]} #{row[1]} #{row[2]}"
    next
  end

  family = nil
  if row[0].present?
    family = Family.where(e_case_id: row[0]).first
  elsif row[1].present?
    families = Family.where({:family_members => {"$elemMatch" => {:person_id => Moped::BSON::ObjectId(row[1])}}})
    families.each do |f|
      family = f if f.primary_applicant.person.id.eql? row[1]
    end
  end

  if family.nil?
    @logger.info "Record does not match e_case_id or primary_applicant #{row[0]} #{row[1]} #{row[2]}"
    next
  end

  begin
    if family.active_household.nil?
      @logger.info "No household #{row[0]} #{row[1]} #{row[2]}"
      next
    end

    if family.active_household.irs_group.nil?
      @logger.info "No irs_group object in glue #{row[0]} #{row[1]} #{row[2]}"
      next
    end
  rescue Exception => e
    @logger.error "#{family.e_case_id} #{e.message}"
    next
  end


  family.active_household.irs_group.hbx_assigned_id = row[2]
  family.save
  @logger.info "#{family.e_case_id} family.active_household.irs_group.hbx_assigned_id: #{family.active_household.irs_group.hbx_assigned_id} csv:#{row[2]}"

end
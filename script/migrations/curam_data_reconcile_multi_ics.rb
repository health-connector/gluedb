require 'csv'
$logger = Logger.new("#{Rails.root}/log/curam_data_reconcile_multi_ic#{Time.now.to_s.gsub(' ', '')}.log")

csv_file="/Users/CitadelFirm/Downloads/tochris_090815/export_multi_ic_090815.csv"
@family = nil


def get_citizen_status(status)
  case status
    when 'U.S. Citizen'
      return 'us_citizen'
    when 'Alien Lawfully Present'
      return 'alien_lawfully_present'
    when 'Not lawfully present in the U.S'
      return 'not_lawfully_present_in_us'
    else
      return nil
  end
end

def process_person_row(row)

  family_member = @family.family_members.detect do |family_member|
    next unless family_member.person.respond_to?(:ssn)
    authority_member = family_member.person.authority_member
    family_member.person.ssn.eql?(row[7]) && authority_member.dob == Date.strptime(row[6], "%Y-%m-%d")
  end
  return unless family_member
  citizen_status = get_citizen_status(row[10])
  authority_member = family_member.person.authority_member
  authority_member.citizen_status = citizen_status if citizen_status
  authority_member.is_incarcerated = true if row[11].downcase.eql?('incarcerated') if row[11]
  authority_member.save
  family_member.save
  @family.save
  $logger.info "Family Member person: #{family_member.person.id} set #{family_member.mec} #{authority_member.citizen_status} #{authority_member.is_incarcerated}"

end

CSV.foreach(File.path(csv_file)) do |row|
  if row[0].include?("line")
    next if @family.nil?
    process_person_row(row)
  else
    families = Family.where(e_case_id: row[13])
    if families.length == 0
      $logger.error "Family with e_case_id: #{row[13]} not found"
      next
    else
      family = families.first
      family.app_ref = row[11]
      family.application_case_type = "Insurance Affordability"
      family.save
      @family = family
      $logger.info "Family: #{family.e_case_id} saved with app_ref #{family.app_ref} application_case_type #{family.application_case_type}"
    end
  end
end
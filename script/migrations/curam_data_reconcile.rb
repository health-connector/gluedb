require 'csv'
$logger = Logger.new("#{Rails.root}/log/curam_data_reconcile#{Time.now.to_s.gsub(' ', '')}.log")

csv_file="/Users/CitadelFirm/Downloads/tochris_090815/export_found_090815.csv"
@family_row=nil
@family


def get_citizen_status(status)
  case status
    when 'U.S. Citizen'
      return 'us_citizen'
    when 'Alien Lawfully Present'
      return 'alien_lawfully_present'
    else
      return nil
  end
end

def process_person_row(row)

  family_member = @family.family_members.detect do |family_member|
    next unless family_member.person.respond_to?(:ssn)
    family_member.person.ssn.eql?(row[7])
  end
  return unless family_member
  family_member.mes = compute_mes(row)
  citizen_status = get_citizen_status(row[10])
  authority_member = family_member.person.authority_member
  authority_member.citizen_status = citizen_status if citizen_status
  authority_member.is_incarcerated = true if row[11].downcase.eql?('incarcerated') if row[11]
  authority_member.save
  family_member.save
  @family.save
  $logger.info "Family Member person: #{family_member.person.id} set #{family_member.mes} #{authority_member.citizen_status} #{authority_member.is_incarcerated}"

end

def compute_mes(row)
  dates = []
  dates << Date.strptime(row[17], "%Y-%m-%d") rescue nil
  dates << Date.strptime(row[19], "%Y-%m-%d") rescue nil
  dates << Date.strptime(row[22], "%Y-%m-%d") rescue nil
  future_date = dates.detect(&:future?)
  future_date.present?
end

def process_family_row
  @family.app_ref = @family_row[10]
  @family.save
  $logger.info "Family: #{@family.e_case_id} saved with app_ref #{@family.app_ref}"
end

CSV.foreach(File.path(csv_file)) do |row|
  if row[0].include?("line")
    next if @family_row==nil
    process_person_row(row)
  else
     @person_rows = []
    @family_row = row
    if Family.where(e_case_id: row[12]).length == 0
      @family_row = nil
      $logger.error "Family with e_case_id: #{row[12]} not found"
      next
    else
      @family = Family.where(e_case_id: row[12]).first
      process_family_row
    end
  end
end


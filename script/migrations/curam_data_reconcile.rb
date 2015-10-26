require 'csv'
log_file="#{Rails.root}/log/curam_data_reconcile#{Time.now.to_s.gsub(' ', '')}.log"
$logger = Logger.new(log_file)

csv_file="/Users/CitadelFirm/Downloads/export_sept16/export_found_091615.csv"
@family_row=nil
@family


def get_citizen_status(status)
  case status
    when 'U.S. Citizen'
      return 'us_citizen'
    when 'Alien Lawfully Present'
      return 'alien_lawfully_present'
    when 'Naturalized Citizen'
      return 'naturalized_citizen'
    when 'Not lawfully present in the U.S'
      return 'not_lawfully_present_in_us'
    else
      return nil
  end
end

def process_person_row(row)
  family_member = @family.family_members.detect do |family_member|
    family_member.person.authority_member.ssn.eql?(row[6]) && family_member.person.authority_member.dob == Date.strptime(row[5], "%Y-%m-%d")
  end
  if family_member.nil?
    $logger.info "Family Member dob #{row[5]} ssn #{row[6]} not found in family #{@family.e_case_id} #{row}"
    return
  end
  family_member.mec = compute_mec(row)
  if family_member.mec
    $logger.info "Family Member #{family_member.id} has mec true #{row}"
  end
  citizen_status = get_citizen_status(row[9])
  authority_member = family_member.person.authority_member
  authority_member.citizen_status = citizen_status if citizen_status
  authority_member.is_incarcerated = true if row[10].downcase.eql?('incarcerated') if row[10]
  authority_member.save
  family_member.save
  @family.save
  $logger.info "Family Member person: #{family_member.person.id} set #{family_member.mec} #{authority_member.citizen_status} #{authority_member.is_incarcerated}"
end

def compute_mec(row)
  dates = []
  dates << date_in_future?(row[15], row[16])
  dates << date_in_future?(row[17], row[18])
  dates << date_in_future?(row[19] || row[20], row[21])
  dates.any?
end

def date_in_future?(field, date)
  date_obj = Date.strptime(date, "%Y-%m-%d") rescue nil

  if field.present?
    return true if date_obj.present? && date_obj >= Date.new(2016, 1, 1)
    return true if date_obj.present? && !date_obj.present?
    return false
  else
    return false
  end
end

def process_family_row(family)
  family.app_ref = @family_row[11]
  if @family_row[17].present? && (@family_row[17].downcase.eql? "streamlinemedicaid")
    family.application_case_type = ""
  else
    family.application_case_type = @family_row[17]
  end
  family.motivation_type = @family_row[16]
  family.save
  $logger.info "Family: #{family.e_case_id} saved with app_ref #{family.app_ref} application_case_type #{family.application_case_type}"
end

def find_family(row)
  dob = Date.strptime(row[6], "%Y-%m-%d")
  person = Person.where("members.ssn" => row[7]).and("members.dob" => dob).first
  return nil if person.nil?
  families = Family.where({:family_members => {"$elemMatch" => {:person_id => Moped::BSON::ObjectId(person.id)}}})
  if families.length == 0
    return nil
  else
    if person == families.first.primary_applicant.person
      return families.first
    else
      return nil
    end
  end
end

CSV.foreach(File.path(csv_file)) do |row|
  begin
    if row[0].include?("line")
      next if @family_row==nil
      process_person_row(row)
    else
      @person_rows = []
      @family_row = row

      @family = find_family(row)

      if @family
        @family_row = row
        process_family_row(@family)
      else
        @family_row = nil
        $logger.error "Family for subscriber with dob and ssn #{row[6]} #{row[7]} not found #{row}"
        next
      end
    end
  rescue Exception => e
    $logger.error "Error processing row #{row} #{e.message}"
  end

end

puts "Log written to #{log_file}"
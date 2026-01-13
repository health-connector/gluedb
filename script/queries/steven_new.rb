require 'csv'
include Config::AcaHelper

def log_message(msg)
  puts msg
  Rails.logger.info msg
end

def log_error(msg)
  puts msg
  Rails.logger.error msg
end

timey = Time.now
log_message "Report started at #{timey}"
policies = Policy.no_timeout.where(
  {"eg_id" => {"$not" => /DC0.{32}/},
   :enrollees => {"$elemMatch" =>
      {:rel_code => "self",
            :coverage_start => {"$gt" => Date.new(2014,12,31)}}}}
)

policies = policies.reject{|pol| pol.market == 'individual' && !pol.subscriber.nil? && (pol.subscriber.coverage_start.year == 2014 || pol.subscriber.coverage_start.year == 2015) }

def bad_eg_id(eg_id)
  (eg_id =~ /\A000/) || (eg_id =~ /\+/)
end

filename = fetch_file_format

Caches::MongoidCache.with_cache_for(Carrier, Plan, Employer) do

  CSV.open(filename, 'w') do |csv|
    csv << ["Subscriber ID", "Member ID", "Policy ID", "Enrollment Group ID", "Carrier Member ID",
            "First Name", "Last Name", "SSN", "DOB", "Gender", "Relationship",
            "Plan Name", "HIOS ID", "Plan Metal Level", "Carrier Name",
            "Premium Amount", "Premium Total", "Policy Employer Contribution",
            "Coverage Start", "Coverage End", "Benefit Status",
            "Employer Name", "Employer DBA", "Employer FEIN", "Employer HBX ID",
            "Address1_Home", "Address2_Home", "City_Home", "County_Home", "StateCode_Home", "ZipCode_Home",
            "Address1_Mail", "Address2_Mail", "City_Mail", "County_Mail", "StateCode_Mail", "ZipCode_Mail",
            "Email", "Phone Number", "Broker"]

    policies.each do |pol|
      begin
        if !bad_eg_id(pol.eg_id)
          if !pol.subscriber.nil?
            subscriber_id = pol.subscriber.m_id
            subscriber_member = pol.subscriber.member
            auth_subscriber_id = subscriber_member.person.authority_member_id

            if !auth_subscriber_id.blank?
              if subscriber_id != auth_subscriber_id
                next
              end
            end

            plan = Caches::MongoidCache.lookup(Plan, pol.plan_id) {
              pol.plan
            }

            carrier = Caches::MongoidCache.lookup(Carrier, pol.carrier_id) {
              pol.carrier
            }

            employer = nil

            if !pol.employer_id.blank?
              employer = Caches::MongoidCache.lookup(Employer, pol.employer_id) {
                pol.employer
              }
            end

            if !pol.broker.blank?
              broker = pol.broker.full_name
            end

            pol.enrollees.each do |en|
              begin
                per = en.person
                next if per.blank?

                # Home Address
                home_address = per.home_address || pol.subscriber.person.home_address
                address1_home = home_address.try(:address_1)
                address2_home = home_address.try(:address_2)
                city_home = home_address.try(:city)
                county_home = home_address.try(:county)
                state_home = home_address.try(:state)
                zip_home = home_address.try(:zip)

                # Mailing Address
                mailing_address = per.mailing_address || pol.subscriber.person.mailing_address
                address1_mail = mailing_address.try(:address_1)
                address2_mail = mailing_address.try(:address_2)
                city_mail = mailing_address.try(:city)
                county_mail = mailing_address.try(:county)
                state_mail = mailing_address.try(:state)
                zip_mail = mailing_address.try(:zip)

                csv << [
                  subscriber_id, en.m_id, pol._id, pol.eg_id, en.c_id,
                  per.name_first,
                  per.name_last,
                  en.member.ssn,
                  en.member.dob.blank? ? nil : en.member.dob.strftime("%Y%m%d"),
                  en.member.gender,
                  en.rel_code,
                  plan.name, plan.hios_plan_id, plan.metal_level, carrier.name,
                  en.pre_amt, pol.pre_amt_tot, pol.tot_emp_res_amt,
                  en.coverage_start.blank? ? nil : en.coverage_start.strftime("%Y%m%d"),
                  en.coverage_end.blank? ? nil : en.coverage_end.strftime("%Y%m%d"),
                  en.ben_stat == "cobra" ? en.ben_stat : nil,
                  pol.employer_id.blank? ? nil : employer.name,
                  pol.employer_id.blank? ? nil : employer.dba,
                  pol.employer_id.blank? ? nil : employer.fein,
                  pol.employer_id.blank? ? nil : employer.hbx_id,
                  address1_home, address2_home, city_home, county_home, state_home, zip_home,
                  address1_mail, address2_mail, city_mail, county_mail, state_mail, zip_mail,
                  per.emails.first.try(:email_address), per.phones.first.try(:phone_number), broker
                ]
              rescue => e
                log_error "ERROR: Policy #{pol._id} - Exception processing enrollee #{en.m_id}: #{e.message}"
                log_error e.backtrace.first(6).join("\n") if e.backtrace
                next
              end
            end
          end
        end
      rescue => e
        log_error "ERROR: Policy #{pol.id} - Exception processing policy: #{e.message}"
        log_error e.backtrace.first(10).join("\n") if e.backtrace
        next
      end
    end
  end
end

upload_to_s3 = Aws::S3Storage.new
uri = upload_to_s3.save(file_path: filename, options: { internal_artifact: true})
upload_to_s3.publish_to_sftp(filename,"Legacy::PushGlueEnrollmentReport", uri)
timey2 = Time.now
log_message "Report ended at #{timey2}"

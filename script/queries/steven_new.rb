require 'csv'
include Config::AcaHelper

timey = Time.now
puts "Report started at #{timey}"
policies = Policy.no_timeout.where(
  {"eg_id" => {"$not" => /DC0.{32}/},
   :enrollees => {"$elemMatch" =>
      {:rel_code => "self",
            :coverage_start => {"$gt" => Date.new(2014,12,31)}}}}
)

policies = policies.reject{|pol| pol.market == 'individual' && !pol.subscriber.nil? &&(pol.subscriber.coverage_start.year == 2014||pol.subscriber.coverage_start.year == 2015) }


def bad_eg_id(eg_id)
  (eg_id =~ /\A000/) || (eg_id =~ /\+/)
end

filename = fetch_file_format

Caches::MongoidCache.with_cache_for(Carrier, Plan, Employer) do

  CSV.open(filename, 'w') do |csv|
    csv << ["Subscriber ID", "Member ID" , "Policy ID", "Enrollment Group ID",
            "First Name", "Last Name","SSN", "DOB", "Gender", "Relationship",
            "Plan Name", "HIOS ID", "Plan Metal Level", "Carrier Name",
            "Premium Amount", "Premium Total", "Policy Employer Contribution",
            "Coverage Start", "Coverage End", "Benefit Status",
            "Employer Name", "Employer DBA", "Employer FEIN", "Employer HBX ID",
            "Home Address", "Mailing Address","Email","Phone Number","Broker"]
    policies.each do |pol|
      if !bad_eg_id(pol.eg_id)
        if !pol.subscriber.nil?
          #if !pol.subscriber.canceled?
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
              #if !en.canceled?
                per = en.person
                next if per.blank?
                csv << [
                  subscriber_id, en.m_id, pol._id, pol.eg_id,
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
                  per.home_address.try(:full_address) || pol.subscriber.person.home_address.try(:full_address),
                  per.mailing_address.try(:full_address) || pol.subscriber.person.mailing_address.try(:full_address),
                  per.emails.first.try(:email_address), per.phones.first.try(:phone_number), broker
                ]
              #end
            end
          #end
        end
      end
    end
  end

end

upload_to_s3 = Aws::S3Storage.new
uri = upload_to_s3.save(file_path: filename, options: { internal_artifact: true})
upload_to_s3.publish_to_sftp(filename,"Legacy::PushGlueEnrollmentReport", uri)
timey2 = Time.now
puts "Report ended at #{timey2}"

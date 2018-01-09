# Generates Carrier Audits and Transforms
require File.join(Rails.root, "lib/mongoid_migration_task")
require File.join(Rails.root,"script","transform_edi_files.rb")

class GenerateAudits < MongoidMigrationTask
  def pull_policies(market,cutoff_date,carrier_abbrev)
    carrier_ids = Carrier.where(:abbrev => carrier_abbrev).map(&:id)
    plan_ids = Plan.where(:carrier_id => {"$in" => carrier_ids})
    active_start = find_active_start(market,cutoff_date)
    active_end = find_active_end(cutoff_date)

    eligible_policies = Policy.where({:enrollees => {"$elemMatch" => {:rel_code => "self",
                                                                       :coverage_start => {"$gt" => active_start}}},
                                       :employer_id => {"$in" => employer_ids},
                                       :plan_id => {"$in" => plan_ids}}).no_timeout

    cleaned_policies = []
    eligible_policies.each do |policy|
      if !policy.canceled?
        if !(policy.subscriber.coverage_start > active_end)
          employer = policy.employer
          next unless in_current_plan_year?(policy,employer,cutoff_date,active_start,active_end)
          subscriber_id = policy.subscriber.m_id
          next if policy.subscriber.person.blank?
          auth_subscriber_id = policy.subscriber.person.authority_member_id
          if subscriber_id == auth_subscriber_id
            cleaned_policies << policy
          end
        end
      end
    end
    cleaned_policies
  end

  def find_active_start(market,cutoff_date)
    if market.downcase == 'ivl'
      active_start = cutoff_date.beginning_of_year - 1.day
    elsif market.downcase == 'shop'
      active_start = (cutoff_date + 1.month) - 1.year
    end
    active_start
  end

  def find_active_end(cutoff_date)
    active_end = cutoff_date.end_of_month
    active_end
  end

  def get_employer_ids(active_start,active_end,market)
    if market.downcase == 'ivl'
      employer_ids = [nil]
    elsif market.downcase == 'shop'
      employer_ids = PlanYear.where(:start_date => {"$gt" => active_start, "$lt" => active_end}).map(&:employer_id)
    end
    employer_ids
  end

  def in_current_plan_year?(policy,employer,cutoff_date,active_start,active_end)
    plan_year = current_plan_year(employer,cutoff_date,active_start,active_end)
    policy_start_date = policy.subscriber.coverage_start
    py_start = plan_year.start_date
    py_end = plan_year.end_date
    date_range = (py_start..py_end)
    if date_range.include?(policy_start_date)
      return true
    else
      return false
    end
  end

  def current_plan_year(employer,cutoff_date,active_start,active_end)
    current_range = (active_start..active_end)
    if current_range.include?(Time.now.to_date)
      today = Time.now.to_date
    else
      today = cutoff_date
    end
    employer.plan_years.each do |plan_year|
      py_start = plan_year.start_date
      py_end = plan_year.end_date
      date_range = (py_start..py_end)
      if date_range.include?(today)
        return plan_year
      end
    end
  end

  def generate_cv2s
    cutoff_date = Date.strptime(ENV['cutoff_date'], '%m-%d-%Y')
    policies = pull_policies(ENV['market'],cutoff_date,ENV['carrier'])
    Dir.mkdir("untransformed_audits")

    policies.each do |policy|
      affected_members = []
      policy.enrollees.each{|en| affected_members << BusinessProcesses::AffectedMember.new(:policy => policy, :member_id => en.m_id)}
      event_type = "urn:openhbx:terms:v1:enrollment#audit"
      tid = generate_transaction_id
      cv_render = render_cv(affected_members,policy,event_type,tid)
      cv_file = File.new("#{policy._id}.xml","w")
      cv_file.puts(cv_render)
      cv_file.close
    end
  end

  def generate_transaction_id
    transaction_id ||= begin
                          ran = Random.new
                          current_time = Time.now.utc
                          reference_number_base = current_time.strftime("%Y%m%d%H%M%S") + current_time.usec.to_s[0..2]
                          reference_number_base + sprintf("%05i", ran.rand(65535))
                        end
    transaction_id
  end

  def render_cv(affected_members,policy,event_type,transaction_id)
    render_result = ApplicationController.new.render_to_string(
         :layout => "enrollment_event",
         :partial => "enrollment_events/enrollment_event",
         :format => :xml,
         :locals => {
           :affected_members => affected_members,
           :policy => policy,
           :enrollees => policy.enrollees,
           :event_type => event_kind,
           :transaction_id => transaction_id
         })
  end
end
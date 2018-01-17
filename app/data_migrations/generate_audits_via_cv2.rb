# Generates Carrier Audits and Transforms

class TransformSimpleEdiFileSet
  include ::Handlers::EnrollmentEventXmlHelper

  XML_NS = { "cv" => "http://openhbx.org/api/terms/1.0" }

  def initialize(out_path)
    @out_path = out_path
  end

  def transform(xml_string)
    enrollment_event_cv = enrollment_event_cv_for(xml_string)
    if is_publishable?(enrollment_event_cv)
      edi_builder = EdiCodec::X12::BenefitEnrollment.new(xml_string)
      x12_xml = edi_builder.call.to_xml
      publish_to_file(enrollment_event_cv, x12_xml)
    end
  end

  def publish_to_file(enrollment_event_cv, x12_payload)
    file_name = determine_file_name(enrollment_event_cv)
    File.open(File.join(@out_path, file_name), 'w') do |f|
      f.write(x12_payload)
    end
  end

  def find_carrier_abbreviation(enrollment_event_cv)
    policy_cv = extract_policy(enrollment_event_cv)
    hios_id = extract_hios_id(policy_cv)
    active_year = extract_active_year(policy_cv)
    found_plan = Plan.where(:hios_plan_id => hios_id, :year => active_year.to_i).first
    found_plan.carrier.abbrev.upcase
  end

  def determine_file_name(enrollment_event_cv)
    market_identifier = shop_market?(enrollment_event_cv) ? "S" : "I"
    carrier_identifier = find_carrier_abbreviation(enrollment_event_cv)
    category_identifier = "_A_F_"
    "834_" + transaction_id(enrollment_event_cv) + "_" + carrier_identifier + category_identifier + market_identifier + "_1.xml"
  end

  protected

  def is_publishable?(enrollment_event_cv)
    Maybe.new(enrollment_event_cv).event.body.publishable?.value
  end

  def is_initial?(enrollment_event_cv)
    event_name = Maybe.new(enrollment_event_cv).event.body.enrollment.enrollment_type.strip.split("#").last.downcase.value
    (event_name == "initial")
  end

  def routing_key(enrollment_event_cv)
    is_initial?(enrollment_event_cv) ? "hbx.enrollment_messages" : "hbx.maintenance_messages"
  end

  def transaction_id(enrollment_event_cv)
    Maybe.new(enrollment_event_cv).event.body.transaction_id.strip.value
  end

  def shop_market?(enrollment_event_cv)
    determine_market(enrollment_event_cv) == "shop"
  end
end

class GenerateAudits
  def pull_policies(market,cutoff_date,carrier_abbrev)
    carrier_ids = Carrier.where(:abbrev => carrier_abbrev).map(&:id)
    plan_ids = Plan.where(:carrier_id => {"$in" => carrier_ids}).map(&:id)
    active_start = find_active_start(market,cutoff_date)
    active_end = find_active_end(cutoff_date)
    employer_ids = get_employer_ids(active_start,active_end,market)

    eligible_policies = Policy.where({:enrollees => {"$elemMatch" => {:rel_code => "self",
                                                                       :coverage_start => {"$gt" => active_start}}},
                                       :employer_id => {"$in" => employer_ids},
                                       :plan_id => {"$in" => plan_ids}}).no_timeout

    eligible_policies.each do |policy|
      if !policy.canceled?
        if !(policy.subscriber.coverage_start > active_end)
          employer = policy.employer
          next unless in_current_plan_year?(policy,employer,cutoff_date,active_start,active_end)
          subscriber_id = policy.subscriber.m_id
          next if policy.subscriber.person.blank?
          auth_subscriber_id = policy.subscriber.person.authority_member_id
          if subscriber_id == auth_subscriber_id
            yield policy
          end
        end
      end
    end
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
    if employer.blank?
      date_range = (active_start..active_end)
    else
      plan_year = current_plan_year(employer,cutoff_date,active_start,active_end)
      py_start = plan_year.start_date
      py_end = plan_year.end_date
      date_range = (py_start..py_end)
    end
    policy_start_date = policy.subscriber.coverage_start
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
    system("rm -rf untransformed_audits > /dev/null")
    Dir.mkdir("untransformed_audits")

    transformer = TransformSimpleEdiFileSet.new('untransformed_audits')

    pull_policies(ENV['market'],cutoff_date,ENV['carrier']) do |policy|
      affected_members = []
      policy.enrollees.each{|en| affected_members << BusinessProcesses::AffectedMember.new(:policy => policy, :member_id => en.m_id)}
      event_type = "urn:openhbx:terms:v1:enrollment#audit"
      tid = generate_transaction_id
      cv_render = render_cv(affected_members,policy,event_type,tid)
      transformer.transform(cv_render)
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

  def render_cv(affected_members,policy,event_kind,transaction_id)
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


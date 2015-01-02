class Policy
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning
#  include Mongoid::Paranoia
  include AASM

  extend Mongorder

  attr_accessor :coverage_start

  auto_increment :_id

  field :eg_id, as: :enrollment_group_id, type: String
  field :preceding_enrollment_group_id, type: String
#  field :r_id, as: :hbx_responsible_party_id, type: String

  field :allocated_aptc, type: BigDecimal, default: 0.00
  field :elected_aptc, type: BigDecimal, default: 0.00
  field :applied_aptc, type: BigDecimal, default: 0.00
  field :csr_amt, type: BigDecimal

  field :pre_amt_tot, as: :total_premium_amount, type: BigDecimal, default: 0.00
  field :tot_res_amt, as: :total_responsible_amount, type: BigDecimal, default: 0.00
  field :tot_emp_res_amt, as: :employer_contribution, type: BigDecimal, default: 0.00
  field :sep_reason, type: String, default: :open_enrollment
  field :carrier_to_bill, type: Boolean, default: false
  field :aasm_state, type: String
  field :updated_by, type: String
  field :is_active, type: Boolean, default: true


  validates_presence_of :eg_id
#  validates_presence_of :plan_id
  validates_presence_of :pre_amt_tot
  validates_presence_of :tot_res_amt
  validates_presence_of :plan_id

  embeds_many :enrollees
  accepts_nested_attributes_for :enrollees, reject_if: :all_blank, allow_destroy: true

  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  belongs_to :hbx_enrollment_policy, class_name: "ApplicationGroup", inverse_of: :hbx_enrollment_policies, index: true
  belongs_to :carrier, counter_cache: true, index: true
  belongs_to :broker, counter_cache: true, index: true # Assumes that broker change triggers new enrollment group
  belongs_to :plan, counter_cache: true, index: true
  belongs_to :employer, counter_cache: true, index: true
  belongs_to :responsible_party

  has_many :transaction_set_enrollments,
              class_name: "Protocols::X12::TransactionSetEnrollment",
              order: { submitted_at: :desc }
  has_many :premium_payments, order: { paid_at: 1 }

  has_many :csv_transactions, :class_name => "Protocols::Csv::CsvTransaction"

  index({:eg_id => 1})
  index({:aasm_state => 1})
  index({:eg_id => 1, :carrier_id => 1, :plan_id => 1})
  index({ "enrollees.person_id" => 1 })
  index({ "enrollees.m_id" => 1 })
  index({ "enrollees.hbx_member_id" => 1 })
  index({ "enrollees.carrier_member_id" => 1})
  index({ "enrollees.carrier_policy_id" => 1})
  index({ "enrollees.rel_code" => 1})
  index({ "enrollees.coverage_start" => 1})
  index({ "enrollees.coverage_end" => 1})

  before_create :generate_enrollment_group_id
  before_save :invalidate_find_cache
  before_save :check_for_cancel_or_term

  scope :all_active_states,   where(:aasm_state.in => %w[submitted resubmitted effectuated])
  scope :all_inactive_states, where(:aasm_state.in => %w[canceled carrier_canceled terminated])

  scope :individual_market, where(:employer_id => nil)
  scope :unassisted, where(:applied_aptc.in => ["0", "0.0", "0.00"])
  scope :insurance_assisted, where(:applied_aptc.nin => ["0", "0.0", "0.00"])

  # scopes of renewal reports
  scope :active_renewal_policies, where({:employer_id => nil, :enrollees => {"$elemMatch" => { :rel_code => "self", :coverage_start => {"$gt" => Date.new(2014,12,31)}, :coverage_end.in => [nil]}}})
  scope :by_member_id, ->(member_id) { where("enrollees.m_id" => {"$in" => [ member_id ]}, "enrollees.rel_code" => "self") }
  scope :with_aptc, where(PolicyQueries.with_aptc)
  scope :without_aptc, where(PolicyQueries.without_aptc)

  aasm do
    state :submitted, initial: true
    state :effectuated
    state :carrier_canceled
    state :carrier_terminated
    state :hbx_canceled
    state :hbx_terminated

    event :initial_enrollment do
      transitions from: :submitted, to: :submitted
    end

    event :effectuate do
      transitions from: :submitted, to: :effectuated
      transitions from: :effectuated, to: :effectuated
      transitions from: :hbx_canceled, to: :hbx_canceled
      transitions from: :hbx_terminated, to: :hbx_terminated
    end

    event :carrier_cancel do
      transitions from: :submitted, to: :carrier_canceled
      transitions from: :carrier_canceled, to: :carrier_canceled
      transitions from: :carrier_terminated, to: :carrier_canceled
      transitions from: :hbx_canceled, to: :hbx_canceled
      transitions from: :hbx_terminated, to: :carrier_canceled
    end

    event :carrier_terminate do
      transitions from: :submitted, to: :carrier_terminated
      transitions from: :effectuated, to: :carrier_terminated
      transitions from: :carrier_terminated, to: :carrier_terminated
      transitions from: :hbx_terminated, to: :hbx_terminated
    end

    event :hbx_cancel do
      transitions from: :submitted, to: :hbx_canceled
      transitions from: :effectuated, to: :hbx_canceled
      transitions from: :carrier_canceled, to: :hbx_canceled
      transitions from: :carrier_terminated, to: :hbx_canceled
      transitions from: :hbx_canceled, to: :hbx_canceled
      transitions from: :hbx_terminated, to: :hbx_canceled
    end

    event :hbx_terminate do
      transitions from: :submitted, to: :hbx_terminated
      transitions from: :effectuated, to: :hbx_terminated
      transitions from: :carrier_terminated, to: :carrier_terminated
      transitions from: :carrier_canceled, to: :hbx_terminated
      transitions from: :hbx_terminated, to: :hbx_terminated
    end

    event :hbx_reinstate do
      transitions from: :carrier_terminated, to: :submitted
      transitions from: :carrier_canceled, to: :submitted
      transitions from: :hbx_terminated, to: :submitted
      transitions from: :hbx_canceled, to: :submitted
    end

    # Carrier Attestation documentation reference should accompany this non-standard transition
    event :carrier_reinstate do
      transitions from: :carrier_terminated, to: :effectuated
      transitions from: :carrier_canceled, to: :effectuated
    end
  end

  def canceled?
    subscriber.canceled?
  end

  def market
    is_shop? ? 'shop' : 'individual'
  end

  def is_shop?
    !employer_id.blank?
  end

  def subscriber
    enrollees.detect { |m| m.relationship_status_code == "self" }
  end

  def enrollees_sans_subscriber
    enrollees.reject { |e| e.relationship_status_code == "self" }
  end

  def has_responsible_person?
    !self.responsible_party_id.blank?
  end

  def responsible_person
    query_proxy.responsible_person
  end

  def people
    query_proxy.people
  end

  def merge_enrollee(m_enrollee, p_action)
    found_enrollee = self.enrollees.detect do |enr|
      enr.m_id == m_enrollee.m_id
    end
    if found_enrollee.nil?
      if p_action == :stop
        m_enrollee.coverage_status = 'inactive'
      end
      self.enrollees << m_enrollee
    else
      found_enrollee.merge_enrollee(m_enrollee, p_action)
    end
  end

  def latest_transaction_date
    (transaction_set_enrollments + csv_transactions).sort_by(&:submitted_at).last.submitted_at
  end

  def edi_transaction_sets
    Protocols::X12::TransactionSetEnrollment.where({"policy_id" => self._id})
  end

  def invalidate_find_cache
    Rails.cache.delete("Policy/find/subkeys.#{enrollment_group_id}.#{carrier_id}.#{plan_id}")
    if !subscriber.nil?
      Rails.cache.delete("Policy/find/sub_plan.#{subscriber.m_id}.#{plan_id}")
    end
    true
  end

  def hios_plan_id
    self.plan.hios_plan_id
  end

  def coverage_type
    self.plan.coverage_type
  end

  def enrollee_for_member_id(m_id)
    self.enrollees.detect { |en| en.m_id == m_id }
  end

  def to_cv
    CanonicalVocabulary::EnrollmentSerializer.new(self, member_ids).serialize
  end

  def self.default_search_orders
    [[:eg_id, 1]]
  end

  def self.find_all_policies_for_member_id(m_id)
    self.where(
      "enrollees.m_id" => m_id
    ).order_by([:eg_id])
  end

  def self.search_hash(s_rex)
    {
      "$or" => [
        {"eg_id" => s_rex}
      ]
    }
  end

  def self.find_by_sub_and_plan(sub_id, h_id)
#    Rails.cache.fetch("Policy/find/sub_plan.#{sub_id}.#{h_id}") do
      plans = Plan.where(:hios_plan_id => h_id)
      found_policies = Policy.where(
        {
          :plan_id => {"$in" => plans.map(&:_id)},
          :enrollees => {
            "$elemMatch" => {
              :rel_code => "self",
              :m_id => sub_id
            }
          }
        })

      if found_policies.count > 1
        (found_policies.reject { |pol| pol.aasm_state == "canceled" }).first
      else
        found_policies.first
      end
#    end
  end

  def self.find_for_group_and_hios(eg_id, h_id)
      plans = Caches::HiosCache.lookup(h_id) { Plan.where(hios_plan_id: h_id) }
      plan_ids = plans.map(&:_id)

      policies = Policy.where(
        {
          :eg_id => eg_id,
          :plan_id => {
            '$in' => plan_ids
          }
        })
      if(policies.count > 1)
        raise "More than one policy that match subkeys: eg_id=#{eg_id}, carrier_id=#{c_id}, plan_ids=#{plan_ids}"
      end
      policies.first
  end

  def self.find_by_subkeys(eg_id, c_id, h_id)
      plans = Plan.where(hios_plan_id: h_id)
      plan_ids = plans.map(&:_id)

      policies = Policy.where(
        {
          :eg_id => eg_id,
          :carrier_id => c_id,
          :plan_id => {
            '$in' => plan_ids
          }
        })
      if(policies.count > 1)
        raise "More than one policy that match subkeys: eg_id=#{eg_id}, carrier_id=#{c_id}, plan_ids=#{plan_ids}"
      end
      policies.first
  end

  def self.find_or_update_policy(m_enrollment)
    plan = Caches::MongoidCache.lookup(Plan, m_enrollment.plan_id) { Plan.find(m_enrollment.plan_id) }
    found_enrollment = self.find_by_subkeys(
      m_enrollment.enrollment_group_id,
      m_enrollment.carrier_id,
      plan.hios_plan_id
    )
    if found_enrollment
      found_enrollment.responsible_party_id = m_enrollment.responsible_party_id
      found_enrollment.employer_id = m_enrollment.employer_id
      found_enrollment.broker_id = m_enrollment.broker_id
      found_enrollment.applied_aptc = m_enrollment.applied_aptc
      found_enrollment.tot_res_amt = m_enrollment.tot_res_amt
      found_enrollment.pre_amt_tot = m_enrollment.pre_amt_tot
      found_enrollment.employer_contribution = m_enrollment.employer_contribution
      found_enrollment.carrier_to_bill = (found_enrollment.carrier_to_bill || m_enrollment.carrier_to_bill)
      found_enrollment.save!
      return found_enrollment
    end
    m_enrollment.unsafe_save!
    m_enrollment
  end



  def check_for_cancel_or_term
    if !self.subscriber.nil?
      if self.subscriber.canceled?
        self.aasm_state = "canceled"
      elsif self.subscriber.terminated?
        self.aasm_state = "terminated"
      end
    end
    true
  end

  def unsafe_save!
    Policy.skip_callback(:save, :before, :revise)
    save(validate: false)
    Policy.set_callback(:save, :before, :revise)
  end

  def self.find_covered_in_range(start_d, end_d)
    Policy.where(
      :aasm_state => { "$ne" => "canceled"},
      :enrollees => {"$elemMatch" => {
          :rel_code => "self",
          :coverage_start => {"$lte" => end_d},
          "$or" => [
            {:coverage_end => {"$gt" => start_d}},
            {:coverage_end => {"$exists" => false}},
            {:coverage_end => nil}
          ]
        }
      }
    )
  end

  def self.find_active_and_unterminated_for_members_in_range(m_ids, start_d, end_d, other_params = {})
    Policy.where(
      PolicyStatus::Active.as_of(end_d,
      {"enrollees" => {
        "$elemMatch" => {
          "m_id" => { "$in" => m_ids },
          "coverage_start" => { "$lt" => end_d },
          "$or" => [
            {:coverage_end => {"$gt" => end_d}},
            {:coverage_end => {"$exists" => false}},
            {:coverage_end => nil}
          ]
        }
      } }).query
    )
  end

  def self.find_active_and_unterminated_in_range(start_d, end_d, other_params = {})
    Policy.where(
      PolicyStatus::Active.as_of(end_d, other_params).query
    )
  end

  def self.find_terminated_in_range(start_d, end_d, other_params = {})
    Policy.where(
      PolicyStatus::Terminated.during(
        start_d,
        end_d
        ).query
    )
  end

  def self.process_audits(active_start, active_end, term_start, term_end, other_params, out_directory)
    ProcessAudits.execute(active_start, active_end, term_start, term_end, other_params, out_directory)
  end

  def can_edit_address?
    return(true) if members.length < 2
    members.map(&:person).combination(2).all? do |addr_set|
      addr_set.first.addresses_match?(addr_set.last)
    end
  end

  def coverage_start_for(member_id)
    member = enrollees.detect { |en| en.m_id == member_id }
    member ? member.coverage_start : nil
  end

  def self.active_as_of_expression(target_date)
    {
      "$or" => [
        { :aasm_state => { "$ne" => "canceled"},
          :eg_id => { "$not" => /DC0.{32}/ },
          :enrollees => {"$elemMatch" => {
            :rel_code => "self",
            :coverage_start => {"$lte" => target_date},
            :coverage_end => {"$gt" => target_date}
          }}},
          { :aasm_state => { "$ne" => "canceled"},
            :eg_id => { "$not" => /DC0.{32}/ },
            :enrollees => {"$elemMatch" => {
              :rel_code => "self",
              :coverage_start => {"$lte" => target_date},
              :coverage_end => {"$exists" => false}
            }}},
            { :aasm_state => { "$ne" => "canceled"},
              :eg_id => { "$not" => /DC0.{32}/ },
              :enrollees => {"$elemMatch" => {
                :rel_code => "self",
                :coverage_start => {"$lte" => target_date},
                :coverage_end => nil
              }}}
      ]
    }
  end

  def active_enrollees
    enrollees.select { |e| e.coverage_status == 'active' }
  end

  def currently_active?
    return false if subscriber.nil?
    return false if eg_id =~ /DC0.{32}/
    now = Date.today
    return false if subscriber.coverage_start > now
    return false if (subscriber.coverage_start == subscriber.coverage_end)
    return false if (!subscriber.coverage_end.nil? && subscriber.coverage_end < now)
    true
  end

  def active_and_renewal_eligible?
    return false if subscriber.nil?
    return false if eg_id =~ /DC0.{32}/
    # now = Date.today
    # return false if (subscriber.coverage_start == subscriber.coverage_end)
    # return false if (!subscriber.coverage_end.nil? && subscriber.coverage_end < now)
    return false if subscriber.coverage_start.nil? || subscriber.coverage_start >= Date.strptime("20150101",'%Y%m%d')
    return false if (!subscriber.coverage_end.nil? && subscriber.coverage_end < Date.strptime("20150101",'%Y%m%d'))
    true
  end

  def currently_active_for?(member_id)
    return false unless currently_active?
    en = enrollees.detect { |enr| enr.m_id == member_id }
    return false if en.nil?
    now = Date.today
    return false if en.coverage_start > now
    return false if (en.coverage_start == en.coverage_end)
    return false if (!en.coverage_end.nil? && en.coverage_end < now)
    true
  end
  def future_active?
    now = Date.today
    return false if subscriber.nil?
    return false if (subscriber.coverage_start == subscriber.coverage_end)
    return false if (!subscriber.coverage_end.nil? && subscriber.coverage_end < now)
    subscriber.coverage_start > now
  end

  def active_as_of?(date)
    return false if subscriber.nil?
    return false if (subscriber.coverage_start == subscriber.coverage_end)
    return false if (!subscriber.coverage_end.nil? && subscriber.coverage_end < date)
    subscriber.coverage_start <= date
  end

  def future_active_for?(member_id)
    en = enrollees.detect { |enr| enr.m_id == member_id }
    now = Date.today
    return false if en.nil?
    return false if (en.coverage_start == en.coverage_end)
    return false if (!en.coverage_end.nil? && en.coverage_end < now)
    return true if en.coverage_start > now
  end

  def policy_start
    subscriber.coverage_start
  end
  def policy_end
    subscriber.coverage_end
  end

  def self.find_by_id(the_id)
    Policy.where({:id => the_id}).first
  end

  def transaction_list
    (transaction_set_enrollments + csv_transactions).sort_by(&:submitted_at).reverse
  end

  def is_active?
    currently_active?
  end

  def cancel_via_hbx!
    self.aasm_state = "hbx_canceled"
    self.enrollees.each do |en|
      en.coverage_end = en.coverage_start
      en.coverage_status = 'inactive'
      self.touch
      en.save!
    end
    self.save!
  end

  def clone_for_renewal(start_date)
    pol = Policy.new({
      :broker => self.broker,
      :employer_id => self.employer_id,
      :carrier_to_bill => self.carrier_to_bill,
      :preceding_enrollment_group_id => self.eg_id,
      :carrier_id => self.carrier_id,
      :responsible_party_id => self.responsible_party_id
    })
    cloneable_enrollees = self.enrollees.reject do |en|
      en.canceled? || en.terminated?
    end
    pol.enrollees = cloneable_enrollees.map do |en|
      en.clone_for_renewal(start_date)
    end
    current_plan = Caches::MongoidCache.lookup(Plan, self.plan_id) { self.plan }
    pol.plan = Caches::MongoidCache.lookup(Plan, current_plan.renewal_plan_id) { current_plan.renewal_plan }
    pol
  end

  protected
  def generate_enrollment_group_id
    self.eg_id = self.eg_id || self._id.to_s
  end

  private
  def format_money(val)
    sprintf("%.02f", val)
  end

  def filter_delimiters(str)
    str.to_s.gsub(',','') if str.present?
  end

  def filter_non_numbers(str)
    str.to_s.gsub(/\D/,'') if str.present?
  end

  def query_proxy
    @query_proxy ||= Queries::PolicyAssociations.new(self)
  end

  def member_ids
    self.enrollees.map do |enrollee|
      enrollee.m_id
    end
  end

end

class Enrollee
  include Mongoid::Document
  include Mongoid::Timestamps

  BENEFIT_STATUS_CODE_LIST      = ["active", "cobra", "surviving insured", "tefra"]
  EMPLOYMENT_STATUS_CODE_LIST   = ["active", "full-time", "part-time", "retired", "terminated"]
  RELATIONSHIP_STATUS_CODE_LIST = ["self", "spouse", "child", "ward"]

  include MergingModel

  attr_accessor :include_checked

  field :person_id, type: Moped::BSON::ObjectId
  field :m_id, as: :hbx_member_id, type: String

  field :ds, as: :disabled_status, type: Boolean, default: false
  field :ben_stat, as: :benefit_status_code, type: String, default: "active"
  field :emp_stat, as: :employment_status_code, type: String, default: "active"
  field :rel_code, as: :relationship_status_code, type: String

  field :c_id, as: :carrier_member_id, type: String
  field :cp_id, as: :carrier_policy_id, type: String
  field :pre_amt, as: :premium_amount, type: BigDecimal
  field :coverage_start, type: Date
  field :coverage_end, type: Date
  field :coverage_status, type: String, default: "active"

  embedded_in :policy

  validates_presence_of :m_id, :relationship_status_code

  validates_inclusion_of :benefit_status_code, in: BENEFIT_STATUS_CODE_LIST
  validates_inclusion_of :employment_status_code, in: EMPLOYMENT_STATUS_CODE_LIST
  validates_inclusion_of :relationship_status_code, in: RELATIONSHIP_STATUS_CODE_LIST

  def coverage_start_matches?(date)
    if date.kind_of?(String)
      self.coverage_start == Date.parse(date)
    else
      self.coverage_start == date
    end
  end

  def person=(person_instance)
    return unless person_instance.is_a? Person
    self.person_id = person_instance._id
  end

  def person
    if self.person_id.blank?
      # Included for backward compatibility
      Queries::PersonByHbxIdQuery.new(m_id).execute unless self.m_id.blank?
    else
      Person.find(self.person_id)
    end
  end

  def member
    Queries::MemberByHbxIdQuery.new(m_id).execute
  end

  def merge_enrollee(m_enrollee, p_action)
    merge_without_blanking(
      m_enrollee,
      :pre_amt,
      :c_id,
      :cp_id,
      :coverage_start,
      :coverage_end,
      :ben_stat,
      :rel_code,
      :emp_stat,
      :ds
    )
    apply_policy_action(p_action)
  end

  def apply_policy_action(action)
    case action
    when :add
      self.coverage_status = 'active'
      self.coverage_end = nil
      if subscriber?
        self.policy.aasm_state = "submitted"
      end
    when :reinstate
      self.coverage_status = 'active'
      self.coverage_end = nil
      self.policy.aasm_state = "resubmitted"
    when :stop
      self.coverage_status = 'inactive'
      if subscriber?
        if self.coverage_start == self.coverage_end
          self.policy.aasm_state = "canceled"
        else
          self.policy.aasm_state = "terminated"
        end
      end
    else
    end
  end

  def active?
    self.coverage_status == 'active'
  end

  def canceled?
    (!self.active?) && (self.coverage_start == self.coverage_end)
  end

  def terminated?
    (!self.active?) && (self.coverage_start != self.coverage_end)
  end

  def subscriber?
    self.relationship_status_code == "self"
  end

  def reference_premium_for(plan, rate_date)
    plan.rate(rate_date, coverage_start, member.dob)
  end

  def coverage_ended?
    !coverage_end.blank?
  end
end

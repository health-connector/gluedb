class TradingPartnerTransformRequest
  include ActiveModel::Validations
  include ActiveModel::Conversion
  include ActiveModel::Naming

  # Reason codes the transform pipeline understands.
  REASON_CODES = [
    "initial",
    "auto_renew",
    "active_renew",
    "audit",
    "reinstate_enrollment",
    "terminate_enrollment"
  ].freeze

  # The pipeline has no cancel reason, so cancel is sent as
  # terminate_enrollment (see transform_reason_code).
  SELECTABLE_REASON_CODES = (REASON_CODES + ["cancel"]).freeze

  END_DATE_ACTIONS = ["none", "remove", "change", "remove_cobra"].freeze
  REMOVE_AASM_STATES = ["submitted", "resubmitted", "effectuated"].freeze
  BENEFIT_STATUSES = ["active", "cobra"].freeze

  # Terminate uses the entered end date. Cancel uses the policy start date.
  CHANGE_MODES = ["terminate", "cancel"].freeze
  END_DATE_FORMAT = "%m/%d/%Y".freeze

  MAX_POLICIES = 50

  attr_accessor :ticket_number, :eg_ids, :reason_code
  attr_accessor :end_date_action, :end_date, :change_mode, :aasm_state, :benefit_status

  # Required by every action. Ticket number is optional.
  validates_presence_of :eg_ids
  validate :policies_must_exist
  validate :policy_count_within_limit

  # Required by the generate actions.
  validates_inclusion_of :reason_code, :in => SELECTABLE_REASON_CODES, :message => "is not a valid reason code", :on => :generate

  # Required by Apply Data Changes.
  validates_inclusion_of :end_date_action, :in => END_DATE_ACTIONS, :message => "is not a valid data preparation action", :on => :apply_changes
  validate :action_required_for_apply, :on => :apply_changes
  validate :end_date_action_params, :on => :apply_changes

  def initialize(props = {})
    props ||= {}
    @ticket_number = props[:ticket_number].to_s.strip
    @eg_ids = props[:eg_ids]
    @reason_code = props[:reason_code]
    @end_date_action = props[:end_date_action].blank? ? "none" : props[:end_date_action]
    @end_date = props[:end_date]
    @change_mode = props[:change_mode].blank? ? "terminate" : props[:change_mode]
    @aasm_state = props[:aasm_state].blank? ? "submitted" : props[:aasm_state]
    @benefit_status = props[:benefit_status].blank? ? "active" : props[:benefit_status]
  end

  def eg_id_list
    @eg_ids.to_s.split(",").map(&:strip).reject(&:blank?).uniq
  end

  def policies
    @policies ||= eg_id_list.map { |eg_id| Policy.where(eg_id: eg_id).first }.compact
  end

  def missing_eg_ids
    eg_id_list - policies.map(&:eg_id)
  end

  # The reason code the transform pipeline receives.
  def transform_reason_code
    reason_code == "cancel" ? "terminate_enrollment" : reason_code
  end

  # Zip name uses the selected reason, so cancel stays cancel, prefixed
  # with the ticket number when given.
  def zip_file_name
    "#{zip_prefix}#{reason_code}_transform_xmls.zip"
  end

  # Zip name for the source XML only download.
  def source_zip_file_name
    "#{zip_prefix}#{reason_code}_source_xml.zip"
  end

  def zip_prefix
    ticket_number.present? ? "#{ticket_number.gsub(/[^0-9A-Za-z_\-]/, '_')}_" : ""
  end

  def end_date_action_selected?
    end_date_action != "none"
  end

  # Parsed strictly as MM/DD/YYYY. Date.parse would read 3/1/2026 as January 3.
  def parsed_end_date
    return nil if @end_date.blank?
    @parsed_end_date ||= begin
      Date.strptime(@end_date.to_s.strip, END_DATE_FORMAT)
    rescue ArgumentError
      nil
    end
  end

  # Terminate uses the entered date. Cancel uses the policy start date, so
  # the policy becomes canceled rather than terminated.
  def effective_end_date_for(policy)
    change_mode == "cancel" ? policy_start_for(policy) : parsed_end_date
  end

  # Current state and planned changes per policy, for the confirmation screen.
  def policy_previews
    policies.map do |policy|
      planned_aasm_state = nil
      planned_benefit_status = nil
      planned_end_date = nil

      case end_date_action
      when "change"
        effective = effective_end_date_for(policy)
        if effective
          planned_end_date = effective
          planned_aasm_state = policy_start_for(policy) == effective ? "canceled" : "terminated"
        end
      when "remove"
        planned_aasm_state = aasm_state
        planned_benefit_status = benefit_status
      end
      # remove_cobra does not change state or benefit status

      {
        :policy => policy,
        :current_aasm_state => policy.aasm_state,
        :current_end_dates => policy.enrollees.map(&:coverage_end).uniq,
        :planned_changes => planned_changes_for(policy),
        :planned_aasm_state => planned_aasm_state,
        :planned_benefit_status => planned_benefit_status,
        :planned_end_date => planned_end_date
      }
    end
  end

  def persisted?
    false
  end

  def self.reason_code_options
    [["Reason Code", nil]] + SELECTABLE_REASON_CODES.map { |rc| [rc, rc] }
  end

  protected

  def planned_changes_for(policy)
    case end_date_action
    when "change"
      change_preview_for(policy)
    when "remove"
      "enrollee end dates cleared, employment and coverage status active, benefit status #{benefit_status}, policy state becomes #{aasm_state}"
    when "remove_cobra"
      "cobra eligibility date removed from the policy (currently #{policy.cobra_eligibility_date.nil? ? 'not set' : policy.cobra_eligibility_date.strftime('%m/%d/%Y')})"
    else
      "none"
    end
  end

  def change_preview_for(policy)
    effective_date = effective_end_date_for(policy)
    return "cannot determine a cancel date, policy has no self relationship coverage start date" if effective_date.nil?
    new_state = policy_start_for(policy) == effective_date ? "canceled" : "terminated"
    "enrollee end dates set to #{effective_date.strftime('%m/%d/%Y')} (#{change_mode}), employment status terminated, coverage status inactive, policy state becomes #{new_state}"
  end

  # Policy#policy_start raises when there is no subscriber. Returns nil
  # instead so validation can report it.
  def policy_start_for(policy)
    return nil if policy.subscriber.nil?
    policy.policy_start
  end

  def policies_must_exist
    return if eg_id_list.empty?
    return if missing_eg_ids.empty?
    errors.add(:eg_ids, "no policies found for eg_ids: #{missing_eg_ids.join(', ')}")
  end

  def policy_count_within_limit
    return if eg_id_list.size <= MAX_POLICIES
    errors.add(:eg_ids, "maximum of #{MAX_POLICIES} policies allowed per request")
  end

  def action_required_for_apply
    return if end_date_action_selected?
    errors.add(:end_date_action, "must be selected to apply data changes")
  end

  def end_date_action_params
    case end_date_action
    when "change"
      change_mode_params
    when "remove"
      unless REMOVE_AASM_STATES.include?(aasm_state)
        errors.add(:aasm_state, "must be one of: #{REMOVE_AASM_STATES.join(', ')}")
      end
      unless BENEFIT_STATUSES.include?(benefit_status)
        errors.add(:benefit_status, "must be one of: #{BENEFIT_STATUSES.join(', ')}")
      end
    end
  end

  def change_mode_params
    unless CHANGE_MODES.include?(change_mode)
      errors.add(:change_mode, "must be one of: #{CHANGE_MODES.join(', ')}")
      return
    end

    if change_mode == "terminate"
      if parsed_end_date.nil?
        errors.add(:end_date, "must be provided as MM/DD/YYYY, digits only")
        return
      end
      terminate_end_date_range
    else
      missing = policies.select { |policy| policy_start_for(policy).nil? }
      missing.each do |policy|
        errors.add(:eg_ids, "policy #{policy.eg_id} has no self relationship coverage start date, cannot auto set a cancel date")
      end
      return if missing.any?
    end

    same_end_date_across_policies
  end

  # The terminate end date must be after the policy start and no later than
  # the last day of its first year (start + 1 year - 1 day). An end date
  # equal to the start is a cancel, not a terminate.
  def terminate_end_date_range
    policies.each do |policy|
      start_date = policy_start_for(policy)
      if start_date.nil?
        errors.add(:eg_ids, "policy #{policy.eg_id} has no self relationship coverage start date, cannot validate the end date")
        next
      end

      last_end_date = start_date + 1.year - 1.day
      if parsed_end_date <= start_date
        errors.add(:end_date, "must be after the policy start date (#{start_date.strftime('%m/%d/%Y')}) for policy #{policy.eg_id}. Use Cancel if the end date should equal the start date")
      elsif parsed_end_date > last_end_date
        errors.add(:end_date, "must be within one year of the policy start date, on or before #{last_end_date.strftime('%m/%d/%Y')}, for policy #{policy.eg_id}")
      end
    end
  end

  # Every policy in the batch must resolve to the same end date. Only
  # cancel can differ, when the policies have different start dates.
  def same_end_date_across_policies
    return if policies.size <= 1
    dates = policies.map { |policy| effective_end_date_for(policy) }.uniq
    return if dates.size <= 1
    details = policies.map { |policy| "#{policy.eg_id}=#{effective_end_date_for(policy).strftime('%m/%d/%Y')}" }.join(", ")
    errors.add(:eg_ids, "all eg_ids in one batch must resolve to the same end date, found different dates: #{details}")
  end
end

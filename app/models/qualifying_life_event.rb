class QualifyingLifeEvent
  include Mongoid::Document
	include Mongoid::Timestamps
  include AASM

  KINDS = [
    "open_enrollment",
    "lost_access_to_mec",
    "adoption",
    "foster_care",
    "birth",
    "marriage",
    "divorce",
    "location_change",
    "termination_of_benefits",
    "termination_of_employment",
    "immigration_status_change",
    "enrollment_error_or_misconduct_hbx",
    "enrollment_error_or_misconduct_issuer",
    "enrollment_error_or_misconduct_non_hbx",
    "contract_violation",
    "eligibility_change_medicaid_ineligible",
    "eligibility_change_assistance",
    "eligibility_change_employer_ineligible",
    "qualified_native_american",
    "exceptional_circumstances_natural_disaster",
    "exceptional_circumstances_medical_emergency",
    "exceptional_circumstances_system_outage",
    "exceptional_circumstances_domestic_abuse",
    "exceptional_circumstances_hardship_exemption",
    "exceptional_circumstances_civic_service",
    "exceptional_circumstances"
  ]

  embedded_in :application_group

	field :kind, type: String  # Qualifying Life Event
	field :event_date, type: Date
	field :sep_start_date, type: Date
	field :sep_end_date, type: Date
	field :sep_number_of_days, type: Integer
  field :aasm_state, type: String

  field :submitted_date, type: DateTime

  index({kind:  1})
  index({sep_start_date:  1})
  index({sep_end_date:  1})

  embedded_in :application_group

  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

 	validates_presence_of :event_date, :sep_start_date, :sep_end_date

	validate :end_date_follows_start_date

  validates :kind, 
  					presence: true,
  					allow_blank: false,
  					allow_nil:   false,
  					inclusion: {in: KINDS}

  # before_create :activate_household_sep
  # before_save :activate_household_sep

  def parent
    self.application_group
  end

	def calculate_end_date(period_in_days)
		self.end_date = start_date + period_in_days unless start_date.blank?
	end

  def duration_in_days
    end_date - start_date
  end

private
	def end_date_follows_start_date
		return if end_date.nil?
		# Passes validation if end_date == start_date
		errors.add(:end_date, "end_date cannot preceed start_date") if sep_end_date < sep_start_date
	end

	# def activate_household_sep
	# 	sep_period = start_date..end_date
	# 	return unless sep_period.include?(Date.today)
	# 	return if household.special_enrollment_periods.any? { |sep| sep.end_date > self.end_date }

	# 	self.reason == "open_enrollment_start" ? household.open_enrollment : household.special_enrollment
	# end

end

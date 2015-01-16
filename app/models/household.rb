class Household
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasApplicants

  embedded_in :application_group

  before_save :set_effective_start_date
  before_save :set_effective_end_date # set_effective_start_date should be done before this
  before_save :reset_is_active_for_previous
  before_save :set_submitted_at

  # field :e_pdc_id, type: String  # Eligibility system PDC foreign key

  # embedded belongs_to :irs_group association
  field :irs_group_id

  field :is_active, type: Boolean, default: true
  field :effective_start_date, type: Date
  field :effective_end_date, type: Date

  field :submitted_at, type: DateTime

  embeds_many :hbx_enrollments
  accepts_nested_attributes_for :hbx_enrollments
  
  embeds_many :tax_households
  accepts_nested_attributes_for :tax_households
  
  embeds_many :coverage_households
  accepts_nested_attributes_for :coverage_households

  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  #TODO uncomment
  #validates :effective_start_date, presence: true

  #TODO uncomment
  #validate :effective_end_date_gt_effective_start_date

  def effective_end_date_gt_effective_start_date
    if effective_end_date
      if effective_end_date < effective_start_date
        self.errors.add(:base, "The effective end date should be earlier or equal to effective start date")
      end
    end
  end

  def parent
    raise "undefined parent ApplicationGroup" unless application_group? 
    self.application_group
  end

  def irs_group=(irs_instance)
    return unless irs_instance.is_a? IrsGroup
    self.irs_group_id = irs_instance._id
  end

  def irs_group
    parent.irs_group.find(self.irs_group_id)
  end

  def is_active?
    self.is_active
  end

  def latest_coverage_household
    return coverage_households.first if coverage_households.size = 1
    coverage_households.sort_by(&:submitted_at).last.submitted_at
  end

  def applicant_ids
    th_applicant_ids = tax_households.inject([]) do |acc, th|
      acc + th.applicant_ids
    end
    ch_applicant_ids = coverage_households.inject([]) do |acc, ch|
      acc + ch.applicant_ids
    end
    hbxe_applicant_ids = hbx_enrollments.inject([]) do |acc, he|
      acc + he.applicant_ids
    end
    (th_applicant_ids + ch_applicant_ids + hbxe_applicant_ids).distinct
  end

  # This will set the effective_end_date of previously active household to 1 day
  # before start of the current household's effective_start_date
  def set_effective_end_date
    return true unless self.effective_start_date
    latest_household = self.application_group.latest_household
    return if self == latest_household
    latest_household.effective_end_date = self.effective_start_date - 1.day
    true
  end

  def reset_is_active_for_previous
    latest_household = self.application_group.latest_household
    active_value = self.is_active
    latest_household.is_active = false
    self.is_active = active_value
    true
  end

  def set_submitted_at
    self.submitted_at = tax_households.sort_by(&:updated_at).last.updated_at if tax_households.length > 0
    self.submitted_at = parent.submitted_at unless self.submitted_at
    true
  end

  def set_effective_start_date
    self.effective_start_date =  application_group.submitted_at
    true
  end

end

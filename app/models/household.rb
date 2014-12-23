class Household
  include Mongoid::Document
  include Mongoid::Timestamps
  include HasApplicants

  embedded_in :application_group

  before_save :set_effective_end_date
  before_save :reset_is_active_for_previous

  # field :e_pdc_id, type: String  # Eligibility system PDC foreign key

  # embedded belongs_to :irs_group association
  field :irs_group_id, type: Moped::BSON::ObjectId

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
  #validates :start_date, presence: true

  #TODO uncomment
  #validate :end_date_gt_start_date

  def end_date_gt_start_date
    if end_date
      if end_date < start_date
        self.errors.add(:base, "The end date should be earlier or equal to start date")
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

  def set_effective_end_date
    latest_household = self.application_group.latest_household
    latest_household.effective_end_date = latest_household.effective_start_date - 1.day
  end

  def reset_is_active_for_previous
    latest_household = self.application_group.latest_household
    latest_household.is_active = false
  end

end

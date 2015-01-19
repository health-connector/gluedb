class IrsGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :application_group

  before_save :set_effective_start_date
  before_save :set_effective_end_date

  # Unique identifier for this Household used for reporting enrollment and premium tax credits to IRS
  auto_increment :hbx_assigned_id, seed: 9999

  auto_increment :_id, seed: 1000000000000000 #The 16digit IrsGroup identifier as required by IRS

  field :effective_start_date, type: Date
  field :effective_end_date, type: Date
  field :is_active, type: Boolean, default: true

  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  index({hbx_assigned_id: 1})

  def parent
    raise "undefined parent ApplicationGroup" unless application_group? 
    self.application_group
  end

  # embedded association: has_many :tax_households
  def households
    parent.households.where(:irs_group_id => self.id)
  end
 
  def is_active?
    self.is_active
  end

  private
  def set_effective_start_date
    self.effective_start_date = application_group.active_household.effective_start_date if application_group.active_household
  end

  def set_effective_end_date
    self.effective_end_date = application_group.active_household.effective_end_date if application_group.active_household
  end
end
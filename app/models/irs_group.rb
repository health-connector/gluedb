class IrsGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :application_group

  # Unique identifier for this Household used for reporting enrollment and premium tax credits to IRS
  auto_increment :hbx_assigned_id, seed: 9999

  field :effective_start_date, type: Date
  field :effective_end_date, type: Date
  field :is_active, type: Boolean, default: true

  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  index({irs_groups.hbx_id: 1})

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

end
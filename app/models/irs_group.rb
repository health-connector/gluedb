class IrsGroup
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :application_group

  # Unique identifier for this Household used for reporting enrollment and premium tax credits to IRS
  auto_increment :hbx_id, seed: 9999


  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true

  def parent
    raise "undefined parent ApplicationGroup" unless application_group? 
    self.application_group
  end

  # embedded association: has_many :tax_households
  def tax_households
    parent.tax_households.where(:irs_group_id => self.id)
  end
 
  # embedded association: has_many :hbx_enrollments
  def hbx_enrollments
    parent.hbx_enrollments.where(:irs_group_id => self.id)
  end

  # embedded association: has_many :hbx_enrollment_exemptions
  def hbx_enrollment_exemptions
    parent.hbx_enrollment_exemptions.where(:irs_group_id => self.id)
  end

  def is_active?
    self.is_active
  end


end
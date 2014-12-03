class CoverageHousehold
  include Mongoid::Document
  include Mongoid::Timestamps
  include Mongoid::Versioning

  embedded_in :application_group

  auto_increment :hbx_id, seed: 9999  # Create 'friendly' ID to publish for other systems

  # embedded belongs_to :irs_group association
  field :irs_group_id, type: Moped::BSON::ObjectId
  field :is_active, type: Boolean, default: true

  field :submitted_date, type: DateTime
  field :effective_start_date, type: DateTime
  field :effective_end_date, type: DateTime

  embeds_many :coverage_household_members
  accepts_nested_attributes_for :coverage_household_members

  embeds_many :hbx_enrollments
  accepts_nested_attributes_for :hbx_enrollments

  embeds_many :comments
  accepts_nested_attributes_for :comments, reject_if: proc { |attribs| attribs['content'].blank? }, allow_destroy: true


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


end

class EmployeeApplicant
  include Mongoid::Document
  include Mongoid::Timestamps

  STATUS = %W[active full_time part_time terminated leave_of_absense retired]

  embedded_in :family_member

  field :employer_id, type: Moped::BSON::ObjectId

  field :status, type: String
  field :eligibility_date, type: Date
  field :start_date, type: Date
  field :end_date, type: Date

  index({employer_id: 1})

  validates_presence_of :employer_id, :start_date

  def employer=(employer_instance)
    return unless employer_instance.is_a? Employer
    self.employer_id = employer_instance._id
  end

  def employer
    Employer.find(self.employer_id) unless self.employer_id.blank?
  end


end

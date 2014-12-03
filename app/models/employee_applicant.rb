class EmployeeApplicant
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :applicant

  field :employer_id,  type: Moped::BSON::ObjectId
  field :eligibility_date, type: Date
  field :start_date, type: Date
  field :end_date, type: Date

  index({employer_id: 1})

  def employer=(employer_instance)
    return unless employer_instance.is_a? Employer
    self.employer_id = employer_instance._id
  end

  def employer
    Employer.find(self.employer_id) unless self.employer_id.blank?
  end


end

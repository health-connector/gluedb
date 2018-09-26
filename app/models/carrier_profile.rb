class CarrierProfile
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :carrier

  field :fein, type: String
  field :profile_name, type: String

  before_save :update_employer_updates_on_enrollments

  def update_employer_updates_on_enrollments
    write_attribute(:requires_employer_updates_on_enrollments, true) if profile_name == "THPP_SHP"
  end
end

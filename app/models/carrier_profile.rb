class CarrierProfile
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :carrier

  field :fein, type: String
  field :profile_name, type: String
end

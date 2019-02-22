class CarrierProfile
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :carrier

  field :fein, type: String
  field :profile_name, type: String
  field :uses_issuer_centric_sponsor_cycles, type: Boolean, default: false
end

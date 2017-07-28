class TradingPartner
  include Mongoid::Document

  field :name, type: String

  embeds_many :trading_profiles
end

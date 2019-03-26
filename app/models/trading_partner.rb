class TradingPartner
  include Mongoid::Document

  field :name, type: String

  field :inbound_enrollment_advice_enricher

  VALID_ENRICHER_FIELDS = [].freeze

  embeds_many :trading_profiles
end

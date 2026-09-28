module TradingPartnerTransforms
  # Feature flag for the Trading Partner Transforms tool. Off unless
  # TRADING_PARTNER_TRANSFORMS_ENABLED is set to "true", so the tool stays
  # hidden in an environment until it is explicitly turned on there.
  def self.enabled?
    ENV['TRADING_PARTNER_TRANSFORMS_ENABLED'].to_s.strip.casecmp('true').zero?
  end
end

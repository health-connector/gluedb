module LegacyEdiTransformations
  class PreImportEffectuationTransform
    def initialize
      @tp_transform_lookup = Hash.new
      ::TradingPartner.all.each do |tp|
        next if tp.inbound_enrollment_advice_enricher.blank?
        tp.trading_profiles.each do |trade_profile|
          @tp_transform_lookup[trade_profile.profile_name] = tp.inbound_enrollment_advice_enricher.constantize
        end
      end
    end

    def apply(csv_row)
      transform = select_transform(csv_row)
      return csv_row unless transform
      transform.apply(csv_row)
    end

    def select_transform(csv_row)
      return nil unless ("effectuation" == csv_row['TRANSTYPE'])
      return nil if csv_row["PARTNER"].blank?
      partner_name = csv_row["PARTNER"].split(" ").last
      transform_class = @tp_transform_lookup[partner_name]
      return nil unless transform_class
      transform_class.new
    end
  end
end

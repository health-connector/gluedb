namespace :ct_demo do
  desc "Load Demo Carrier Profiles"
  task :load_carriers => :environment do
    abcbs_carrier = Carrier.create!({
      id: Moped::BSON::ObjectId.from_string("5ce6ab2134913261ad000001"),
      hbx_carrier_id: "20014",
      name: "Anthem BlueCross BlueShield",
      abbrev: "ABCBS",
      shp_hlt: true,
      shp_dtl: true,
      ind_dtl: true,
      carrier_profiles: [
        CarrierProfile.new({
          profile_name: "ABCBS_IVL",
          fein: "061475928"
        }),
        CarrierProfile.new({
          profile_name: "ABCBS_SHP",
          fein: "061475928"
        })
      ]
    })
    abcbs_tp = TradingPartner.create!({
      name: "Anthem BlueCross BlueShield",
      trading_profiles: [
        TradingProfile.new({
          profile_name: "ABCBS_IVL",
          profile_code: "061475928"
        }),
        TradingProfile.new({
          profile_name: "ABCBS_SHP",
          profile_code: "061475928"
        })
      ]
    })
    ccare_carrier = Carrier.create!({
      id: Moped::BSON::ObjectId.from_string("5ce6abc2349132b47a000001"),
      hbx_carrier_id: "20015",
      name: "ConnectiCare",
      abbrev: "CCARE",
      shp_hlt: true,
      carrier_profiles: [
        CarrierProfile.new({
          profile_name: "CCARE_IVL",
          fein: "237442369"
        }),
        CarrierProfile.new({
          profile_name: "CCARE_SHP",
          fein: "237442369"
        })
      ]
    })
    ccare_tp = TradingPartner.create!({
      name: "ConnectiCare",
      trading_profiles: [
        TradingProfile.new({
          profile_name: "CCARE_IVL",
          profile_code: "237442369"
        }),
        TradingProfile.new({
          profile_name: "CCARE_SHP",
          profile_code: "237442369"
        })
      ]
    })
    ahct_carrier = Carrier.create!({
      hbx_carrier_id: "20000",
      name: "Access Health CT",
      abbrev: "AHCT",
      carrier_profiles: [
        CarrierProfile.new({
          profile_name: "AHCT_IVL",
          fein: "461542132"
        }),
        CarrierProfile.new({
          profile_name: "AHCT_SHP",
          fein: "461542132"
        })
      ]
    })
    ahct_tp = TradingPartner.create!({
      name: "Access Health CT",
      trading_profiles: [
        TradingProfile.new({
          profile_name: "AHCT_IVL",
          profile_code: "461542132"
        }),
        TradingProfile.new({
          profile_name: "AHCT_IVL",
          profile_code: "461542132"
        })
      ]
    })
  end
end

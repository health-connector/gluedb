carrier = Carrier.all.where(name:'Tufts Health Plan Premier').first
carrier.shop_profile.update_attributes(requires_employer_updates_on_enrollments: true)

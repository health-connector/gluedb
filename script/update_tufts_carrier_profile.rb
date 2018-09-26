Carrier.all.where(name:/^Tufts/i).each do |carrier|
  carrier.shop_profile.update_attributes(requires_employer_updates_on_enrollments: true)
end
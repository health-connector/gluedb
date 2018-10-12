carrier = Carrier.all.where(name:'Tufts Health Plan Premier').first
carrier.update_attributes(requires_employer_updates_on_enrollments: true)

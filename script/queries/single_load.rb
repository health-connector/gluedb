p = Person.new(name_first: "", name_last: "", authority_member_id: "" )
m = Member.new(hbx_member_id: "", dob: , ssn: "", gender: "" )
a = Address.new(address_type: "", address_1: "", address_2: "", city: "", state: "", zip: "", import_source: "" )
e = Email.new(email_type: "", email_address: "")
ph = Phone.new(phone_type: "", phone_number: "" )
p.members << m
p.addresses << a
p.emails << e
p.phones << ph

po = Policy.create(_id: , eg_id: "", pre_amt_tot: , total_responsible_amount: )
en = Enrollee.new(m_id: "", pre_amt: , coverage_start: , rel_code: )

pl = Plan.where(hios_plan_id: "", year: ).first
b = Broker.where(npn: "").first

po.broker = b
po.plan = pl
po.carrier = pl.carrier

po.enrollees << en

p.save!

po.save!

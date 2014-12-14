transmissions = Protocols::X12::Transmission.where("submitted_at" => {"$gt" => Time.mktime(2014, 12, 10, 0, 0, 0)})

transmissions.each do |t|
  t.transaction_set_enrollments.each do |tse|
    tse.body.remove!
    tse.delete
  end
  t.transaction_set_premium_payments.each do |tspp|
    tspp.premium_payments.each(&:delete)
    tspp.body.remove!
  end
  t.delete
end

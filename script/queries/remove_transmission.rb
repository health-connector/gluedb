bad_transactions = Protocols::X12::TransactionSetEnrollment.where({
  "submitted_at" => {"$gt" => Date.new(2014, 11, 1)},
  "receiver_id" => "461542132"
})

transmission_ids = bad_transactions.map(&:transmission_id)

transmissions = Protocols::X12::Transmission.where(
  "id" => {"$in" => transmission_ids },
  "submitted_at" => {"$gt" => Date.new(2014, 11, 1)},
  "isa08" => "461542132"
)

transmissions.each do |t|
  t.transaction_set_enrollments.each do |tse|
    tse.body.remove!
    tse.delete
  end
  t.delete
end

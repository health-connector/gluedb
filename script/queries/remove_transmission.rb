transmissions = Protocols::X12::Transmission.where(
  "id" => {
    "$in" => [
               "548b4519eb899ab61800a587",
               "548b13c0791e4b6b750000cd",
               "5481ccbc791e4b73320002a1",
               "54886d08791e4bfec900029d",
               "548f07db791e4becb8004628"
             ]
  }
)

transmissions.each do |t|
  t.transaction_set_enrollments.each do |tse|
    tse.body.remove!
    tse.delete
  end
  t.delete
end

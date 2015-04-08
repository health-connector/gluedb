pol_ids = [
"10656",
"12449",
"9734",
"18263",
"71",
"7864",
"623",
"8090",
"8414",
"8780",
"8656",
"8971",
"16713",
"8395",
"11864",
"27227",
"11863",
"12097",
"8376",
"9941",
"8997",
"10884",
"10871",
"625",
"21343",
"13198",
"8566",
"12434",
"12467",
"12441",
"12468",
"12472"
            ]


pols = Policy.where("id" => {"$in" => pol_ids })

pols.each do |pol|
  subscriber = pol.subscriber.person
  word = subscriber.comments.build
  word.content = "terminated policy #{pol.id} has been canceled to match information reported by carrier (in shared folder) for 2014 IRS reporting"
  word.user = "joe.kramer@dc.gov"
  word.save!
  pol.cancel_via_hbx!
  pol.updated_by = "joe.kramer@dc.gov"
  pol.save!
end

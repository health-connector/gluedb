missing_ids = [
              "28128",
              "60531",
              "60536",
              "60537",
              "60540",
              "60544",
              "60548",
              "60549",
              "60552",
              "60561",
              "60565",
              "60568",
              "60575",
              "62166",
              "62651",
              "62750",
              "62751",
              "62755",
              "62756",
              "62757",
              "62931",
              "62961",
              "63332",
              "66994",
              "67121",
              "67836",
              "68427",
              "68428",
              "68684",
              "68687",
              "68688",
              "68694",
              "68697",
              "68701",
              "68702",
              "68704",
              "68708"
            ]


missing_policies = Policy.where("id" => {"$in" => missing_ids })

missing_policies.each do |pol|
  subscriber = pol.subscriber
  start_date  = pol.subscriber.coverage_start
  plan = pol.plan

  if pol.is_shop?
    employer = pol.employer
    plan_year = employer.plan_year_of(start_date)
    pol.cancel_via_hbx!
    puts "#{pol.id} - policy start date #{start_date} does not fall into any plan years of #{employer.name} (fein: #{employer.fein})" if plan_year.nil?
  else
    pol.cancel_via_hbx!
    puts "#{pol.id} - policy start date #{start_date} not in rate table for #{plan.year} plan #{plan.name} with hios #{plan.hios_plan_id} " unless plan.year == start_date.year
  end
end

FactoryGirl.define do
  factory :plan_year do
    start_date Date.new(2014,1,1)  
    end_date  Date.new(2014,12,31)
    open_enrollment_start Date.new(2013,10,1)  
    open_enrollment_end  Date.new(2013,11,10)
    fte_count  1
    pte_count  1
  end

  trait :renewal_year do 
    start_date Date.new(2015,1,1)  
    end_date  Date.new(2015,12,31)
    open_enrollment_start Date.new(2014,10,1)  
    open_enrollment_end  Date.new(2014,11,10)
  end

  factory :renewal_plan_year, traits: [:renewal_year]
end
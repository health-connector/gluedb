FactoryGirl.define do 
  factory :premium_payment do 
    pmt_amt 22222
    paid_at Date.new(2014,12,31)
    hbx_payment_type 'PREM'
    coverage_period '20150101-20150131'
  end
end


FactoryGirl.define do
  factory :phone do
    phone_type 'home'
    sequence(:phone_number, 1111111111) { |n| "#{n}"}
    sequence(:extension) { |n| "#{n}"}
    primary true
  end
end
FactoryGirl.define do
  factory :employer do
    name 'Das Coffee'
    sequence(:hbx_id) { |n| "#{n}"}
    sequence(:fein, 111111111) {|n| "#{n}" }
    sic_code '0100'
    fte_count 1
    pte_count 1
    open_enrollment_start Date.new(2014,1,2)
    open_enrollment_end Date.new(2014,1,2)
    plan_year_start Date.new(2014,1,2)
    plan_year_end Date.new(2014,1,2)

    trait :fein_too_short do
      fein '1'
    end

    trait :with_plan_year do
      after(:create) do |employer|
        create :plan_year, employer: employer
      end
    end

    trait :with_contact_info do 
      after(:create) do |emp, evaluator|
        create_list(:address, 1, employer: emp)
        create_list(:phone, 1, employer: emp)
        create_list(:email, 1, employer: emp)
      end
    end

    factory :invalid_employer, traits: [:fein_too_short]
    factory :employer_with_plan_year, traits: [:with_plan_year, :with_contact_info]
    factory :employer_with_multiple_plan_years, traits: [:with_plan_year,:with_renewal_plan_year]
  end
end

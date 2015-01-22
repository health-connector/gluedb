FactoryGirl.define do
  factory :hbx_enrollment do
    kind 'unassisted_qhp'
    enrollment_group_id 'John'
    applied_aptc_in_cents 1000
    elected_aptc_in_cents 1000
    is_active true
    submitted_at DateTime.now

    after(:create) do |hbx_enrollment|

    end
  end
end

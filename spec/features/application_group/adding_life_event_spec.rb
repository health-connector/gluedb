=begin
require 'rails_helper'

feature 'adding life event to application group' do
  scenario 'with valid attributes' do
    user = create :user
    visit root_path
    sign_in_with(user.email, user.password)

    app_group = ApplicationGroup.create

    visit family_path(app_group.id)

    event = SpecialEnrollmentPeriod.new(reason: 'birth', start_date: Date.new(2014, 1, 1), end_date: Date.new(2014, 2, 1))

    click_link 'New Life Event'
    fill_in 'special_enrollment_period_start_date', with: '01/01/2014'
    fill_in 'special_enrollment_period_end_date', with: '02/01/2014'
    select 'birth', from: 'special_enrollment_period_reason'

    click_button 'Submit'

    expect(page).to have_content 'birth'
    expect(page).to have_content '01-01-2014'
    expect(page).to have_content '02-01-2014'
  end
end
=end

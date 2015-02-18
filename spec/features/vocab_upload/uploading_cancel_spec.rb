require 'rails_helper'

feature 'uploading a cancel/term CV' do
  given(:premium) do
    PremiumTable.new(
      rate_start_date: Date.new(2014, 1, 1),
      rate_end_date: Date.new(2014, 12, 31),
      age: 53,
      amount: 398.24
    )
  end
  background do
    user = create :user, :admin
    visit root_path
    sign_in_with(user.email, user.password)

    # Note: The file fixture is dependent on this record.
    plan = Plan.new(coverage_type: 'health', hios_plan_id: '11111111111111-11', year: 2014, ehb: 0.5)
    plan.premium_tables << premium
    plan.save!
  end

  scenario 'nonsubscriber member canceled' do
    visit new_vocab_upload_path

    choose 'Maintenance'

    file_path = Rails.root + "spec/support/fixtures/cancel/nonsubscriber_cancel.xml"
    attach_file('vocab_upload_vocab', file_path)

    click_button "Upload"

    expect(page).to have_content 'Uploaded successfully.'
  end

  scenario 'subscriber member canceled' do
    visit new_vocab_upload_path

    choose 'Maintenance'

    file_path = Rails.root + "spec/support/fixtures/cancel/subscriber_cancel.xml"
    attach_file('vocab_upload_vocab', file_path)

    click_button "Upload"

    expect(page).to have_content 'Uploaded successfully.'
  end

  scenario 'incorrect premium total' do
    visit new_vocab_upload_path

    choose 'Maintenance'

    file_path = Rails.root + "spec/support/fixtures/cancel/incorrect_premium_total.xml"
    attach_file('vocab_upload_vocab', file_path)

    click_button "Upload"

    expect(page).to have_content 'Failed to Upload.'
    expect(page).to have_content 'premium_amount_total is incorrect'
  end
end

# require 'spec_helper'


# feature 'adding new person to application group' do
#   scenario 'person added when attributes valid' do       
#     user = create :user
#     visit root_path
#     sign_in_with(user.email, user.password)

#     app_group = ApplicationGroup.create

#     visit family_path(app_group.id)

#     person = build :person

#     click_link 'New Person'

#     fill_in 'Pfx', with: person.name_pfx
#     fill_in 'First', with: person.name_first
#     fill_in 'Mid', with: person.name_middle
#     fill_in 'Last', with: person.name_last
#     fill_in 'Sfx', with: person.name_sfx

#     select 'male', from: 'person_members_attributes_0_gender'

#     fill_in 'SSN', with: '111111111'
#     fill_in 'mm/dd/yyyy', with: '01/01/1980'

#     select 'home', from: 'person_addresses_attributes_0_address_type'
#     fill_in 'Street', with: '1234 Main Street'
#     fill_in 'person_addresses_attributes_0_address_2', with: '#123'
#     fill_in 'City', with: 'Washington'

#     select 'District Of Columbia', from: 'person_addresses_attributes_0_state'
#     fill_in 'Zip code', with: '20012'

#     select 'home', from: 'person_phones_attributes_0_phone_type'
#     fill_in 'person_phones_attributes_0_phone_number', with: '222-222-2222'
#     fill_in 'person_phones_attributes_0_extension', with: '1234'

#     select 'home', from: 'person_emails_attributes_0_email_type'
#     fill_in 'person_emails_attributes_0_email_address', with: 'example@dc.gov'
    
#     select 'self', from: 'person_relationship'

#     click_button 'Create Person'
    
#     expect(page).to have_content 'Person was successfully created.'

#     expect(page).to have_content person.name_full
#     expect(URI.parse(current_url).path).to eq family_path(app_group.id)

#   end

# end

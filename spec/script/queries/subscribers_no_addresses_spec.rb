require 'rails_helper'
require File.join(Rails.root, "script", "queries", "subscribers_no_addresses")

describe 'find_previous_home_addresses' do
	it 'should return an empty array if the person has not been updated' do
		person = FactoryGirl.create :person
		expect(find_previous_home_addresses(person)).to eq []
	end

	it 'should return an array of strings if the person has been updated' do
		person = FactoryGirl.create :person
		person.remove_address_of('home')
		expect(find_previous_home_addresses(person).map(&:class).to_s).to eq 'String'
	end
end
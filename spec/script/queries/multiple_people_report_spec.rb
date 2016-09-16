require 'rails_helper'
require File.join(Rails.root, "script", "queries", "multiple_people_report")

describe 'find_matches' do
	it 'should return an array with objects of the class Person' do
		person = FactoryGirl.create :person
		carrier = FactoryGirl.create :carrier
		plan = FactoryGirl.create :plan
		policy = FactoryGirl.create :policy
		expect(find_matches(person.members.first.dob,
							 person.members.first.ssn,
							 person.name_first,
							 person.name_last).map(&:class).uniq.join("")).to eq 'Person'
	end
end

describe 'find_employers' do
	carrier = FactoryGirl.create :carrier
	plan = FactoryGirl.create :plan
	ivl_policy = FactoryGirl.create :policy

	it 'should return an array if theres a shop policy' do
		person = FactoryGirl.create :person
		shop_policy = FactoryGirl.create :shop_policy
		shop_policy.subscriber.m_id = person.members.first.hbx_member_id
		shop_policy.save
		expect(find_employers(person).class.to_s).to eq 'Array'		
	end
end
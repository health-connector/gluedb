require 'rails_helper'
require File.join(Rails.root, "script", "migrations", "person_family_creator")

describe PersonFamilyCreator do

  before(:each) do
    @person = Person.new({name_first: "nice", name_last: "person"})
    @person.save

    person_family_creator1 = PersonFamilyCreator.new([@person])
    @family1 = person_family_creator1.create.first

    @person2 = Person.new({name_first: "nice2", name_last: "person2"})
    @person2.save

    person_family_creator2 = PersonFamilyCreator.new
    @family2 = person_family_creator2.create.first
  end

  context "passing person(s) in array" do
    it 'should creates family for a person' do
      expect(@family1).to be_a_kind_of(Family)
      expect(@family1.primary_applicant.person).to eq(@person)
    end

    it 'should have person as the primary applicant in family' do
      expect(@family1.primary_applicant.person).to eq(@person)
    end
  end

  context "fetching person(s) from database" do
    it 'should creates family for a person' do
      expect(@family2).to be_a_kind_of(Family)
    end

    it 'should have person as the primary applicant in family' do
      expect(@family2.primary_applicant.person).to eq(@person2)
    end
  end
end
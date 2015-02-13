require 'rails_helper'
require File.join(Rails.root, "script", "migrations", "family_for_policy_creator")

describe FamilyForPolicyCreator do

  before(:each) do
    @policy = FactoryGirl.create(:policy)
    @family_for_policy_creator = FamilyForPolicyCreator.new(@policy)
    @family_for_policy_creator.create
    @family = @family_for_policy_creator.save
  end

  it "creates a family for a policy" do
    expect(@family).to be_a_kind_of(Family)
  end

  it "creates a family with family members as enrollees in the policy" do
    expect(@family.family_members.length).to be_a_kind_of(@policy.enrollees.length)
  end
end
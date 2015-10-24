require "rails_helper"

describe Listeners::HbxEnrollmentListener do
  it "should invoke the soa resource to get the full details about the policy provided"

  describe "given a new policy" do
    describe "and all the members on the policy exist" do
      it "should create the policy object"
      it "should send a new policy to the B2B with the provided enrollment reason"
    end

    describe "and some policy members does not exist" do
      it "should log an error and re-queue the message for later processing"
    end

    describe "with a plan which does not exist" do
      it "should log an error and acknowledge the message"
    end

    describe "with a broker that does not exist" do
      it "should log an error and re-queue the message for later processing"
    end

    describe "with an employer that does not exist" do
      it "should log an error and re-queue the message for later processing"
    end
  end

  describe "given an existing policy" do
    describe "with addition of new members" do
      it "should add the specified members to the policy"
      it "should send a policy update message to the B2B containing addition information"
    end

    describe "with termination of active members" do
      it "should terminate the specified members"
      it "should send a policy update message to the B2B containing termination information"
    end

    describe "with termination of the subscriber" do
        it "should terminate all active members of the policy"
        it "should send a policy update message to the B2B containing termination information"
    end
  end

end

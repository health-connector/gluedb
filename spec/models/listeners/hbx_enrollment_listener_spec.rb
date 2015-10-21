require "rails_helper"

describe Listeners::HbxEnrollmentListener do
  describe "given a new policy" do
    describe "and all the members on the policy exist" do
      it "should create the policy object"
    end

    describe "and a policy member does not exist" do
      it "should log an error and re-queue the message for later processing"
    end
  end
end

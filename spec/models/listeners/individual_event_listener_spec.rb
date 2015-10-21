require "rails_helper"

describe Listeners::IndividualEventListener do
  it "should contact the 'callback' service to get the full individual resource"

  describe "given a new individual" do
    it "should create that individual"
  end

  describe "given an individual which already exists" do
    describe "and the individual has no active policies" do
      it "should simply update that individual's record"
    end

    describe "and the individual has active policies" do
      describe "and there is a change to name" do
        describe "and there is also a change of address" do
          it "should update only the name portion of the individual's record"
          it "should send out policy updates via EDI with reason 'change of identifying information'"
          it "should nack the message for re-delivery"
        end

        describe "and there are no other changes to the person's information" do
          it "should update the individual's record"
          it "should send out policy updates via EDI with reason 'change of identifying information'"
        end
      end
    end
  end
end

require "rails_helper"

describe EnrollmentAction::Base do
  describe "#publish_edi" do
    subject { EnrollmentAction::Base.new(nil, nil) }

    describe "which fails to publish trading partner edi" do
      it "returns false with the publishing errors"

      it "does not attempt to publish the legacy cv"
    end

    describe "which publishes trading partner edi" do
      describe "but fails to publish the legacy cv" do
        it "returns false with the publishing errors"
      end

      describe "and to publishes the legacy cv" do
        it "returns true"
      end
    end
  end
end

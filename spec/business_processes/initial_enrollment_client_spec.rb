require "rails_helper"

describe InitialEnrollmentClient do
  it "has steps in the stack" do
    expect(subject.steps).not_to be_empty
  end
end

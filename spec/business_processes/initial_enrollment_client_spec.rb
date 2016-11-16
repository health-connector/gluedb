require "rails_helper"

describe InitialEnrollmentClient do
  it "can be composed inside of other processes" do
    expect {
      Middleware::Builder.new do |b|
        b.use subject.stack
      end.to_app
    }
  end

  it "has steps in the stack" do
    expect(subject.steps).not_to be_empty
  end
end

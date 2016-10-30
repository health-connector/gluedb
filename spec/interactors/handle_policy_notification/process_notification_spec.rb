require "rails_helper"

describe HandlePolicyNotification::ProcessNotification do
  it "passes the lint test for all it's components existing" do
    expect(subject).not_to eq nil
  end
end

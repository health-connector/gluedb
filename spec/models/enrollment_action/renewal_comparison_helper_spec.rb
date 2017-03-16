require "rails_helper"

describe EnrollmentAction::RenewalComparisonHelper do
  describe "#any_renewal_candidates?" do
    ## receives an EnrollmentEvent

  end

  describe "#same_carrier_renewal_candidates" do
    ## receives an EnrollmentEvent
  end

  describe "#renewal_dependents_changed?" do
    ## receives EnrollmentEvent and a renewal candidate
  end

  describe "#renewal_dependents_added?" do
    ## receives EnrollmentEvent and a renewal candidate

  end

  describe "#renewal_dependents_dropped?" do
    ## receives EnrollmentEvent and a renewal candidate

  end

  describe "ivl_renewal_candidate?" do
    ## receives a policy, plan, subscriber_id, subscriber_start date, and a boolean if same carrier
  end
  describe "shop_renewal_candidate?" do
    ## receives a policy, plan, subscriber_id, subscriber_start date, and a boolean if same carrier
  end

  describe "shop_renewal_candidates" do
    ## receives a policy_cv and boolean if same carrier
  end

  describe "extract_ivl_policy_details" do
    ## receives policy_cv
  end
end

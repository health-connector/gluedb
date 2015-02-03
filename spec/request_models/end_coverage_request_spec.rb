require "rails_helper"

describe EndCoverageRequest, "from form" do
  subject { EndCoverageRequest }

  let(:form_params) do
    {
      cancel_terminate:
        {
        operation: "terminate",
        reason: "termination_of_benefits",
        benefit_end_date: "01/16/2015",
        people_attributes:
          {
            "0" => {include_selected: "1", m_id: "1983410", name: "Joe Kramer", role: "self"},
            "1" => {include_selected: "0", m_id: "1983470", name: "Mary Kramer", role: "spouse"},
            "2" => {include_selected: "0", m_id: "1984090", name: "Joe Kramer Jr", role: "child"}
          }
        },
        id: "4301"
    }
  end

  let(:request) do
    {
      policy_id: "4301",
      affected_enrollee_ids: ["1983410", "1983470", "1984090"],
      coverage_end: "01/16/2015",
      operation: "terminate",
      reason: "termination_of_benefits",
      transmit: false,
      current_user: current_user
    }
  end

  let(:current_user) { 'joseph.kramer@dc.gov' }

  it "should create a request for all members to be terminated " do
    expect(subject.from_form(form_params, current_user)).to eq request
  end

end

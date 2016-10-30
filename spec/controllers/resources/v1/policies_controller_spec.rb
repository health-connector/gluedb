require "rails_helper"

describe Resources::V1::PoliciesController do
  describe "show.xml" do
    let(:policy_id) { "policy_id" }

    before :each do
      allow(Policy).to receive(:where).with({"eg_id" => policy_id}).and_return(found_policies)
      get :show, :id => policy_id, :format => :xml
    end

    describe "given an existing policy" do
      let(:found_policy) { [instance_double(Policy)] }
      let(:found_policies) { [found_policy] }

      it "renders the show template" do
        expect(response).to render_template("policies/show")
      end

      it "assigns the policy model" do
        expect(assigns[:policy]).to eq found_policy
      end

      it "returns not found" do
        expect(response.status).to eq 200
      end
    end

    describe "given a policy which does not exist" do
      let(:found_policies) { [] }

      it "returns not found" do
        expect(response.status).to eq 404
      end
    end
  end
end

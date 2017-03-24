require "rails_helper"

=begin
describe Resources::V1::IndividualsController do
  describe "show.xml" do
    let(:hbx_member_id) { "Some member id" }

    before :each do
      allow(Person).to receive(:where).with({"members.hbx_member_id" => hbx_member_id}).and_return(found_people)
      get :show, :id => hbx_member_id, :format => :xml
    end

    describe "given an existing person" do
      let(:found_person) { [instance_double(Person)] }
      let(:found_people) { [found_person] }

      it "renders the show template" do
        expect(response).to render_template("people/show")
      end

      it "assigns the person model" do
        expect(assigns[:person]).to eq found_person
      end

      it "returns not found" do
        expect(response.status).to eq 200
      end
    end

    describe "given a person which does not exist" do
      let(:found_people) { [] }

      it "returns not found" do
        expect(response.status).to eq 404
      end
    end
  end
end
=end

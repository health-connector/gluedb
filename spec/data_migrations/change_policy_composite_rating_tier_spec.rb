require "rails_helper"

describe ChangePolicyCompositeRatingTier, dbclean: :after_each do 
  let(:given_task_name) { "change_policy_composite_rating_tier" }
  let(:policy) { FactoryGirl.create(:policy) }
  subject { ChangePolicyCompositeRatingTier.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing the rating tier" do 
    before(:each) do
      allow(ENV).to receive(:[]).with("eg_id").and_return(policy.eg_id)
      allow(ENV).to receive(:[]).with("rating_tier").and_return("family")
    end

    it 'should change the rating tier' do 
      subject.migrate
      policy.reload
      new_tier = "urn:openhbx:terms:v1:composite_rating_tier#family"
      expect(policy.composite_rating_tier).to eq (new_tier)
    end
  end
end

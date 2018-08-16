require "rails_helper"
require File.join(Rails.root,"app","data_migrations","transform_xmls")

describe GenerateTransforms, dbclean: :after_each do 
  let(:given_task_name) { "generate_transforms" }
  let(:policy) { FactoryGirl.create(:terminated_policy) }
  let(:enrollees) { policy.enrollees }
  let(:reason_code){"terminate_enrollment"}
  let(:file_name) {"#{policy.eg_id}_#{reason_code.split('#').last}.xml"}

  subject { GenerateTransforms.new() }

  describe "creating a cv21" do 
    before(:each) do 
      allow(ENV).to receive(:[]).with("eg_ids").and_return(policy.eg_id)
      allow(ENV).to receive(:[]).with("reason_code").and_return(reason_code)
    end
    
    it "should generate a cv21 and place it in the correct folder" do
      enrollees.each do |en|
         person = FactoryGirl.create(:person, authority_member_id: en.m_id)
         person.members.create!(hbx_member_id: en.m_id, gender:"male")
      end

      subject.generate_transform
      expect(File.exist?(Rails.root.join('source_xmls', file_name))).to be(true) 
    end
    after(:all) do
      FileUtils.rm_rf(Dir["#{Rails.root}/source_xmls/*"])
      FileUtils.rm_rf(Dir["#{Rails.root}/source_xmls.zip"])
    end
  end

end
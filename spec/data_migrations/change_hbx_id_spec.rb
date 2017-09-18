require "rails_helper"
require File.join(Rails.root,"app","data_migrations","change_hbx_id")

describe ChangeHbxId, dbclean: :after_each do
  let(:given_task_name) { "change_hbx_id" }
  let(:person) { FactoryGirl.create(:person) }
  let(:nonauthority_member) { person.members.detect{|m| m.hbx_member_id != person.authority_member_id} }
  let(:nonauthority_member_id) { nonauthority_member.hbx_member_id }
  subject { ChangeHbxId.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing person hbx id" do
    before(:each) do
      allow(ENV).to receive(:[]).with("new_hbx_id").and_return("34588973")
    end

    it "should change member hbx id and authority member ID if the specified ID is the authority member ID" do
      allow(ENV).to receive(:[]).with("person_hbx_id").and_return(person.authority_member_id)
      subject.migrate
      person.reload
      expect(person.authority_member_id).to eq "34588973"
      expect(person.authority_member.hbx_member_id).to eq "34588973"
    end

    it "should only change member hbx id if the specified ID is not the authority member ID" do 
      allow(ENV).to receive(:[]).with("person_hbx_id").and_return(nonauthority_member_id)
      subject.migrate
      person.reload
      nonauthority_member.reload
      expect(person.authority_member_id).not_to eq "34588973"
      expect(nonauthority_member.hbx_member_id).to eq "34588973"
    end
  end
end
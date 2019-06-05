require "rails_helper"
require File.join(Rails.root,"app","data_migrations","change_phone_number")

describe ChangePhoneNumber, dbclean: :after_each do
  let(:given_task_name) { "change_phone_number" }
  let!(:person) { FactoryGirl.create(:person) }
  let(:kind) {person.phones.first.phone_type}
  let!(:phone_no) {person.phones.first.phone_number}
  subject { ChangePhoneNumber.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing person phone number" do
    before(:each) do
      person.update_attributes(:authority_member_id => person.members.first.hbx_member_id)
      allow(ENV).to receive(:[]).with("authority_member_ids").and_return(person.authority_member_id)
      allow(ENV).to receive(:[]).with("kind").and_return(kind)
      allow(ENV).to receive(:[]).with("phone_number").and_return("1234567890")
    end

    it "should change the phone number of a specific person" do
      expect(person.phones.first.phone_number).to eq phone_no
      subject.migrate
      person.reload
      expect(person.phones.first.phone_number).to eq "1234567890"
    end
  end
end
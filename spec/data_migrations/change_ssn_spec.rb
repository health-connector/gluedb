require "rails_helper"
require File.join(Rails.root,"app","data_migrations","change_ssn")

describe ChangeSsn, dbclean: :after_each do
  let(:given_task_name) { "change_ssn" }
  let(:person) { FactoryGirl.create(:person) }
  subject { ChangeSsn.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe "changing ssn" do
    before(:each) do 
      allow(ENV).to receive(:[]).with("hbx_id").and_return(person.members.first.hbx_member_id)
      allow(ENV).to receive(:[]).with("new_ssn").and_return("888888888")
    end

    it "should change the ssn" do 
      member = person.members.detect{|member| member.hbx_member_id == ENV["hbx_id"]}
      subject.migrate
      person.reload
      member.reload
      expect(member.ssn).to eq ENV["new_ssn"]
    end 
  end
end
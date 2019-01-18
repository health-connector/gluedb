require "rails_helper"
require File.join(Rails.root,"app","data_migrations","merge_duplicate_employers")

describe "MergeDuplicateEmployers", dbclean: :after_each do
  let!(:given_task_name) { "merge_duplicate_employers" }
  let!(:employee1) {FactoryGirl.create(:person, employer_id: employer_to_keep.id)}
  let!(:employee2) {FactoryGirl.create(:person, employer_id: employer_to_remove.id)}
  let!(:employer_to_keep) { FactoryGirl.create(:employer_with_plan_year) }
  let!(:employer_to_remove) { FactoryGirl.create(:employer_with_plan_year, carrier_ids: [carrier.id], plan_ids: [plan.id], broker_id: broker.id) }
  let!(:carrier) { FactoryGirl.create(:carrier) }
  let!(:plan) {FactoryGirl.create(:plan)}
  let!(:broker) {FactoryGirl.create(:broker)}
  subject { MergeDuplicateEmployers.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name", dbclean: :after_each do 
    it "has the given task name" do
      expect(subject.name).to eql given_task_name
    end
  end

  describe 'merge the employers', dbclean: :after_each do

    before(:each) do
      allow(employer_to_keep).to receive(:employees).and_return([employee1])
      allow(employer_to_remove).to receive(:employees).and_return([employee2])
      employee1.update_attributes(:authority_member_id => employee1.members.first.hbx_member_id)
      employee2.update_attributes(:authority_member_id => employee2.members.first.hbx_member_id)
      ENV['employer_to_keep'] = employer_to_keep.id
      ENV['employer_to_remove'] = employer_to_remove.id
    end

    it 'should merge any non-duplicate addresses' do
      addresses = (employer_to_keep.addresses.map(&:full_address) + employer_to_remove.addresses.map(&:full_address)).uniq.sort
      subject.merge_addresses(employer_to_keep, employer_to_remove)
      employer_to_keep.reload
      new_addresses = employer_to_keep.addresses.map(&:full_address).uniq
      expect(new_addresses).to eq addresses
    end

    it 'should merge any non-duplicate phones' do
      phones = (employer_to_keep.phones.map(&:phone_number) + employer_to_remove.phones.map(&:phone_number)).uniq.sort
      subject.merge_phones(employer_to_keep, employer_to_remove)
      employer_to_keep.reload
      new_phones = employer_to_keep.phones.map(&:phone_number).uniq.sort
      expect(new_phones).to eq phones
    end

    it 'should merge any non-duplicate emails' do
      emails = (employer_to_keep.emails.map(&:email_address) + employer_to_remove.emails.map(&:email_address)).uniq.sort
      subject.merge_emails(employer_to_keep, employer_to_remove)
      employer_to_keep.reload
      new_emails = employer_to_keep.emails.map(&:email_address).uniq.sort
      expect(new_emails).to eq emails
    end

    it 'should move all the employees from the duplicate employer' do
      employer_to_keep.reload
      member_ids_before = (employer_to_remove.employees.map(&:authority_member_id) + employer_to_keep.employees.map(&:authority_member_id)).uniq.sort
      subject.migrate
      employer1 = Employer.find(employer_to_keep.id)
      employer2 = Employer.find(employer_to_remove.id)
      expect(employer1.employees.size).to eq member_ids_before.count
      expect(employer2.employees.size).to eq 0
      expect(employer2.employees.map(&:authority_member_id)).to eq []
    end
  end
end
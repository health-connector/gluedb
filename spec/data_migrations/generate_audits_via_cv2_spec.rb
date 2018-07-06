require "rails_helper"
require File.join(Rails.root,"app","data_migrations","generate_audits_via_cv2")

describe GenerateAudits, dbclean: :after_each do
  let(:cutoff_date) { Date.today.beginning_of_month }
  let(:carrier) { FactoryGirl.create(:carrier) }
  let(:carrier_abbrev) { 'SAC' }
  let(:ivl_pol) { FactoryGirl.create(:canceled_dependent_policy) }
  let(:shop_pol) { FactoryGirl.create(:shop_policy) }
  let(:renewal_shop_pol) { FactoryGirl.create(:shop_policy) }
  let(:person) { FactoryGirl.create(:person) }
  let(:dependent_person) { FactoryGirl.create(:person)}
  subject { GenerateAudits.new }

  describe 'given that these are IVL audits' do 
    let(:market) { 'ivl' }

    before(:each) do 
      carrier.abbrev = carrier_abbrev
      carrier.save

      ivl_pol.plan.carrier = carrier
      ivl_pol.plan.save

      ivl_pol.carrier = carrier
      ivl_pol.save

      ivl_pol.enrollees.each do |en|
        if en.coverage_start == en.coverage_end
          en.coverage_end = cutoff_date + 1.day
          en.save
        end
      end

      ivl_pol.enrollees.each do |en|
        en.coverage_start = cutoff_date + 1.day
        en.save
      end

      person.members.first.hbx_member_id = ivl_pol.subscriber.m_id
      person.members.first.save
      person.authority_member_id = ivl_pol.subscriber.m_id

      dependent_person.members.first.hbx_member_id = ivl_pol.enrollees.detect{|en| en.rel_code != "self"}.m_id
      dependent_person.members.first.save
      dependent_person.authority_member_id = ivl_pol.enrollees.detect{|en| en.rel_code != "self"}.m_id
    end

    it 'should only return the ivl policy' do 
      yielded_policy = subject.pull_policies(market,cutoff_date,carrier_abbrev)
      expect(yielded_policy.first).to eq ivl_pol
    end

    it 'should not return the shop policy' do 
      yielded_policy = subject.pull_policies(market,cutoff_date,carrier_abbrev)
      expect(yielded_policy).not_to eq shop_pol
    end

    it 'should not include canceled dependents' do 
      enrollees = subject.select_enrollees(ivl_pol)
      expect(enrollees.select{|en| (en.coverage_start == en.coverage_end)}).to eq []
    end
  end

  describe 'given that these are SHOP audits' do 
    let(:market) { 'shop' }
    let(:employer) { shop_pol.employer }
    let(:plan_year_1) { FactoryGirl.create(:plan_year)}
    let(:plan_year_2) { FactoryGirl.create(:plan_year)}

    before(:each) do 
      carrier.update_attributes(abbrev: carrier_abbrev)

      shop_pol.plan.update_attributes(carrier_id: carrier._id)

      shop_pol.update_attributes(carrier: carrier._id)

      shop_pol.enrollees.each{|en| en.update_attributes(coverage_start: cutoff_date + 1.day)}

      renewal_shop_pol.enrollees.each{|en| en.update_attributes(coverage_start: cutoff_date + 1.year)}

      person.members.first.update_attributes(hbx_member_id: shop_pol.subscriber.m_id)
      person.update_attributes(authority_member_id: shop_pol.subscriber.m_id)

      plan_year_1.update_attributes(employer_id: employer._id, start_date: cutoff_date, end_date: (cutoff_date + 1.year - 1.day))
      plan_year_2.update_attributes(employer_id: employer._id, start_date: (cutoff_date - 1.year), end_date: (cutoff_date - 1.day))
    end

    it 'should only select the current plan year' do
      active_start = subject.find_active_start(market,cutoff_date)
      active_end = subject.find_active_end(cutoff_date) 
      cpy = subject.current_plan_year(employer,cutoff_date,active_start,active_end)
      expect(cpy).to eq plan_year_1
    end

    it 'should not select the renewal plan year' do 
      active_start = subject.find_active_start(market,cutoff_date)
      active_end = subject.find_active_end(cutoff_date)
      cpy = subject.current_plan_year(employer,cutoff_date,active_start,active_end)
      expect(cpy).not_to eq plan_year_2
    end

    it 'should verify that a policy is in the current plan year' do 
      active_start = subject.find_active_start(market,cutoff_date)
      active_end = subject.find_active_end(cutoff_date)
      expect(subject.in_current_plan_year?(shop_pol,employer,cutoff_date,active_start,active_end))
    end

    it 'should verify that a renewal policy is not in the current plan year' do 
      active_start = subject.find_active_start(market,cutoff_date)
      active_end = subject.find_active_end(cutoff_date)
      expect(subject.in_current_plan_year?(renewal_shop_pol,employer,cutoff_date,active_start,active_end))
    end

    it 'should only return the shop policy' do 
      yielded_policy = subject.pull_policies(market,cutoff_date,carrier_abbrev)
      expect(yielded_policy.first).to eq shop_pol
    end

    it 'should not return the ivl policy' do 
      yielded_policy = subject.pull_policies(market,cutoff_date,carrier_abbrev)
      expect(yielded_policy).not_to eq ivl_pol
    end

  end
end
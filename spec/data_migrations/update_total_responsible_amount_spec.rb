require "rails_helper"
require File.join(Rails.root,"app","data_migrations","update_total_responsible_amount.rb")

describe UpdateTotalResponsibleAmount, dbclean: :after_each do
  let(:given_task_name) { "update_total_responsible_amount" }
  let(:policy) { FactoryGirl.create(:policy)}
  subject { UpdateTotalResponsibleAmount.new(given_task_name, double(:current_scope => nil)) }

  describe "given a task name" do 
    it "has the given task name" do 
      expect(subject.name).to eql given_task_name
    end
  end

  describe "updating policy totals" do 
    before(:each) do
      allow(ENV).to receive(:[]).with("eg_id").and_return(policy.eg_id)
      allow(ENV).to receive(:[]).with("total_responsible_amount").and_return(5)
      allow(ENV).to receive(:[]).with("premium_amount_total").and_return(4)
      allow(ENV).to receive(:[]).with("applied_aptc").and_return(3)
      allow(ENV).to receive(:[]).with("employer_contribution").and_return(6)
    end

    it 'update policy totals' do
      subject.migrate
      policy.reload
      expect(policy.tot_res_amt).to eq 5
      expect(policy.pre_amt_tot).to eq 4 
      expect(policy.applied_aptc).to eq 3
      expect(policy.tot_emp_res_amt).to eq 6
    end

    it 'update the policy totals  missing total responsible amount' do
      allow(ENV).to receive(:[]).with("total_responsible_amount").and_return('')
      allow(ENV).to receive(:[]).with("applied_aptc").and_return(nil)
      allow(ENV).to receive(:[]).with("employer_contribution").and_return(20.20)
      subject.migrate
      policy.reload
      expect(policy.tot_res_amt).to eq policy.tot_res_amt
      expect(policy.pre_amt_tot).to eq 4 
      expect(policy.applied_aptc).to eq policy.applied_aptc 
      expect(policy.tot_emp_res_amt).to eq 20.20
    end

    it 'update the policy totals missing premium amount totals' do
      allow(ENV).to receive(:[]).with("premium_amount_total").and_return('')
      allow(ENV).to receive(:[]).with("employer_contribution").and_return('')
      subject.migrate
      policy.reload
      expect(policy.pre_amt_tot).to eq policy.pre_amt_tot
      expect(policy.applied_aptc).to eq 3
      expect(policy.tot_emp_res_amt).to eq policy.employer_contribution
    end   

    it 'update the policy totals with non numbers' do
      allow(ENV).to receive(:[]).with("applied_aptc").and_return('asdlasjf')
      subject.migrate
      policy.reload
      expect(policy.pre_amt_tot).to eq 4 
      expect(policy.applied_aptc).to eq policy.applied_aptc
    end
  end
end
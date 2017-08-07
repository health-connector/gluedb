require "rails_helper"

shared_examples_for "a policy with updated aptc credits" do
  it "updates the value of pre_amt_tot" do
    expect(subject.pre_amt_tot).to eq pre_amt_tot
  end

  it "updates the value of applied_aptc" do
    expect(subject.applied_aptc).to eq aptc_amount
  end

  it "updates the value of tot_res_amt" do
    expect(subject.tot_res_amt).to eq tot_res_amt
  end
end

describe Policy, "with no aptc credits, told to update aptc to a given date which is the same as the start of the policy" do

  let(:policy_start) { Date.new(2013, 1, 1) }
  let(:effective_date) { Date.new(2013, 1, 1) }
  let(:aptc_amount) { BigDecimal.new("23.21") }
  let(:pre_amt_tot) { BigDecimal.new("123.45") }
  let(:tot_res_amt) { BigDecimal.new("100.44") }

  subject do
    Policy.new(
      :enrollees => [Enrollee.new(
        :rel_code => "self",
        :coverage_start => policy_start
      )]
    )
  end

  before :each do
    subject.set_aptc_effective_on(effective_date, aptc_amount, pre_amt_tot, tot_res_amt)
  end

  it "creates the new aptc credit" do
    expect(subject.aptc_credits.length).to eq 1
  end

  it "sets the correct start date of the aptc credit" do
    aptc_credit = subject.aptc_credits.first
    expect(aptc_credit.start_on).to eq effective_date
  end

  it "sets the correct end date of the aptc credit" do
    aptc_credit = subject.aptc_credits.first
    expect(aptc_credit.end_on).to eq Date.new(2013, 12, 31)
  end

  it "sets the correct aptc of the aptc credit" do
    aptc_credit = subject.aptc_credits.first
    expect(aptc_credit.aptc).to eq aptc_amount
  end

  it "sets the correct tot_res_amt of the aptc credit" do
    aptc_credit = subject.aptc_credits.first
    expect(aptc_credit.tot_res_amt).to eq tot_res_amt
  end

  it "sets the correct pre_amt_tot of the aptc credit" do
    aptc_credit = subject.aptc_credits.first
    expect(aptc_credit.pre_amt_tot).to eq pre_amt_tot
  end

  it_behaves_like "a policy with updated aptc credits"
end


describe Policy, "with no aptc credits, told to update aptc to a given date which is not the same as the policy start" do

  let(:policy_end) { Date.new(2013, 12, 31) }
  let(:policy_start) { Date.new(2013, 1, 1) }
  let(:effective_date) { Date.new(2013, 4, 15) }
  let(:aptc_amount) { BigDecimal.new("23.21") }
  let(:pre_amt_tot) { BigDecimal.new("123.45") }
  let(:tot_res_amt) { BigDecimal.new("100.44") }
  let(:old_aptc_amount) { BigDecimal.new("20.11") }
  let(:old_pre_amt_tot) { BigDecimal.new("120.45") }
  let(:old_tot_res_amt) { BigDecimal.new("100.34") }

  subject do
    Policy.new(
      :enrollees => [Enrollee.new(
        :rel_code => "self",
        :coverage_start => policy_start
      )],
      :applied_aptc => old_aptc_amount,
      :pre_amt_tot => old_pre_amt_tot,
      :tot_res_amt => old_tot_res_amt
    )
  end

  before :each do
    subject.set_aptc_effective_on(effective_date, aptc_amount, pre_amt_tot, tot_res_amt)
  end

  it "creates two aptc credits" do
    expect(subject.aptc_credits.length).to eq 2
  end

  it "sets the correct aptc of the old aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).first
    expect(aptc_credit.aptc).to eq old_aptc_amount
  end

  it "sets the correct total amount of the old aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).first
    expect(aptc_credit.pre_amt_tot).to eq old_pre_amt_tot
  end

  it "sets the correct total responsible amount of the old aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).first
    expect(aptc_credit.tot_res_amt).to eq old_tot_res_amt
  end

  it "sets the correct start date of the old aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).first
    expect(aptc_credit.start_on).to eq policy_start
  end

  it "sets the correct end date of the old aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).first
    expect(aptc_credit.end_on).to eq (effective_date - 1.day)
  end

  it "sets the correct start date of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.start_on).to eq effective_date
  end

  it "sets the correct end date of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.end_on).to eq policy_end
  end

  it "sets the correct aptc of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.aptc).to eq aptc_amount
  end

  it "sets the correct tot_res_amt of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.tot_res_amt).to eq tot_res_amt
  end

  it "sets the correct pre_amt_tot of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.pre_amt_tot).to eq pre_amt_tot
  end

  it_behaves_like "a policy with updated aptc credits"
end

describe Policy, "with an aptc credit, told to update aptc in the middle of the other credit" do
  let(:policy_start) { Date.new(2013, 1, 1) }
  let(:policy_end) { Date.new(2013, 12, 31) }
  let(:effective_date) { Date.new(2013, 4, 15) }
  let(:aptc_amount) { BigDecimal.new("23.21") }
  let(:pre_amt_tot) { BigDecimal.new("123.45") }
  let(:tot_res_amt) { BigDecimal.new("100.44") }

  subject do
    Policy.new(
      :enrollees => [Enrollee.new(
        :rel_code => "self",
        :coverage_start => policy_start
      )],
      :aptc_credits => [
         AptcCredit.new(
           start_on: policy_start,
           end_on: policy_end
         )
      ]
    )
  end

  before :each do
    subject.set_aptc_effective_on(effective_date, aptc_amount, pre_amt_tot, tot_res_amt)
  end

  it "creates the new aptc credit" do
    expect(subject.aptc_credits.length).to eq 2
  end

  it "sets the correct end date of the old aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).first
    expect(aptc_credit.end_on).to eq (effective_date - 1.day)
  end

  it "sets the correct start date of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.start_on).to eq effective_date
  end

  it "sets the correct end date of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.end_on).to eq policy_end
  end

  it "sets the correct aptc of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.aptc).to eq aptc_amount
  end

  it "sets the correct tot_res_amt of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.tot_res_amt).to eq tot_res_amt
  end

  it "sets the correct pre_amt_tot of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.pre_amt_tot).to eq pre_amt_tot
  end

  it_behaves_like "a policy with updated aptc credits"
end

describe Policy, "with an aptc credit, told to update aptc with the same start as the other credit" do
  let(:policy_start) { Date.new(2013, 1, 1) }
  let(:policy_end) { Date.new(2013, 12, 31) }
  let(:effective_date) { Date.new(2013, 1, 1) }
  let(:aptc_amount) { BigDecimal.new("23.21") }
  let(:pre_amt_tot) { BigDecimal.new("123.45") }
  let(:tot_res_amt) { BigDecimal.new("100.44") }

  subject do
    Policy.new(
      :enrollees => [Enrollee.new(
        :rel_code => "self",
        :coverage_start => policy_start
      )],
      :aptc_credits => [
         AptcCredit.new(
           start_on: policy_start,
           end_on: policy_end
         )
      ]
    )
  end

  before :each do
    subject.set_aptc_effective_on(effective_date, aptc_amount, pre_amt_tot, tot_res_amt)
  end

  it "updates the existing aptc credit" do
    expect(subject.aptc_credits.length).to eq 1
  end

  it "sets the correct start date of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.start_on).to eq effective_date
  end

  it "sets the correct end date of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.end_on).to eq policy_end
  end

  it "sets the correct aptc of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.aptc).to eq aptc_amount
  end

  it "sets the correct tot_res_amt of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.tot_res_amt).to eq tot_res_amt
  end

  it "sets the correct pre_amt_tot of the aptc credit" do
    aptc_credit = subject.aptc_credits.sort_by(&:start_on).last
    expect(aptc_credit.pre_amt_tot).to eq pre_amt_tot
  end

  it_behaves_like "a policy with updated aptc credits"
end

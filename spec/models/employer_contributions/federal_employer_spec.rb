require 'rails_helper'

describe EmployerContributions::FederalEmployer do
  let(:employer_groups) { [] }
  let(:fed_employer_props) { { 
    :federal_contribution_groups => employer_groups,
    :contribution_percent => 75.0
  } }

  let(:enrollment) { double(:enrollees => enrollees, :pre_amt_tot => pre_amt_tot) }
  let(:enrollees) { [] }
  let(:pre_amt_tot) { 0.0 }
  let(:mg) { EmployerContributions::FederalContributionGroup }

  describe "given some employer groups" do
    let(:employer_groups) { [
      mg.new(:enrollee_count => 1, :contribution_amount => 222.11),
      mg.new(:enrollee_count => 2, :contribution_amount => 400.12),
      mg.new(:enrollee_count => 3, :contribution_amount => 600.34)
    ]}

    subject { EmployerContributions::FederalEmployer.new(fed_employer_props) }

    describe "given just an employee" do
      let(:enrollees) { [1] }
      let(:pre_amt_tot) { 400.23 }

      it "should use the correct group size" do
        expect(subject.max_amount_for(enrollment)).to eql(222.11)
      end

      it "should calculate the right employer contribution" do
        expect(subject.contribution_for(enrollment)).to eql(222.11)
      end
    end

    describe "given an enrollment with more people than the existing max group size" do
      let(:enrollees) { [1,2,3,4,5] }
      let(:pre_amt_tot) { 500.21 }

      it "should use the largest group size" do
        expect(subject.max_amount_for(enrollment)).to eql(600.34)
      end

      it "should calculate the right employer contribution" do
        expect(subject.contribution_for(enrollment)).to eql(375.16)
      end
    end

  end

end

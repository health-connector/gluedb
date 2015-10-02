require 'rails_helper'

describe Listeners::EmployerUpdateListener do
  let(:employer) { double }
  let(:employer_hbx_id) { "an employer hbx id" }

  before :each do
    allow(Employer).to receive(:by_hbx_id).with(employer_hbx_id).and_return(matching_employers)
  end

  describe "given an employer which doesn't exist" do
    let(:matching_employers) { [] }
    it "should create that employer"
  end

  describe "given an employer which exists" do
    let(:matching_employers) { [employer] }
    it "should update that employer"
  end
end

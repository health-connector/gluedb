require 'rails_helper'

describe TaxHousehold do

  subject { TaxHousehold.new }


  let(:tax_household_members) { [member1, member2, member3]}
  let(:member1) { double(financial_statements: [tax_filer]) }
  let(:member2) { double(financial_statements: [non_filer1]) }
  let(:member3) { double(financial_statements: [dependent]) }
  let(:tax_filer) { double(tax_filing_status: 'tax_filer', is_tax_filing_together: false) }
  let(:non_filer1) { double(tax_filing_status: 'non_filer', is_tax_filing_together: false) }
  let(:non_filer2) { double(tax_filing_status: 'non_filer', is_tax_filing_together: false) }
  let(:dependent) { double(tax_filing_status: 'dependent', is_tax_filing_together: false) }
  let(:joint_filer1) { double(tax_filing_status: 'tax_filer', is_tax_filing_together: true) }
  let(:joint_filer2) { double(tax_filing_status: 'tax_filer', is_tax_filing_together: true) }

  before(:each) do 
    allow(subject).to receive(:tax_household_members).and_return(tax_household_members) 
    allow(subject).to receive(:has_spouse_relation?).with(member2).and_return(true) 
  end

  context '#primary' do

    context 'when single filer present' do 
      it 'should return tax filer' do
        expect(subject.primary).to eq(member1)
      end
    end

    context 'when multiple filers filing together' do 
      let(:member1) { double(financial_statements: [joint_filer1]) }
      let(:member2) { double(financial_statements: [joint_filer2]) }

      it 'should return primary_applicant' do 
        allow(member1).to receive(:is_primary_applicant?).and_return(false)
        allow(member2).to receive(:is_primary_applicant?).and_return(true)
        expect(subject.primary).to eq(member2)
      end
    end
  end

  context '#spouse' do
    context 'when single filer present' do 
      let(:member2) { double(financial_statements: [non_filer1]) }
      let(:member3) { double(financial_statements: [non_filer2]) }

      it 'should return non_filer with spouse relation on policy' do
        expect(subject.spouse).to eq(member2)
      end
    end

    context 'when multiple filers filing together' do 
      let(:member1) { double(financial_statements: [joint_filer1]) }
      let(:member2) { double(financial_statements: [non_filer1]) }
      let(:member3) { double(financial_statements: [joint_filer2]) }

      it 'should return non primary_applicant' do
        allow(member1).to receive(:is_primary_applicant?).and_return(true)
        allow(member3).to receive(:is_primary_applicant?).and_return(false)

        expect(subject.spouse).to eq(member3)
      end
    end
  end

  context '#dependents' do
    context 'when member with filing status dependent present' do
      it 'should return' do
        expect(subject.dependents).to eq([member3])
      end
    end

    context 'when non_filer without spouse relation present' do
      let(:member2) { double(financial_statements: [non_filer1]) }
      let(:member3) { double(financial_statements: [non_filer2]) }

      it 'should return as dependent' do
        expect(subject.dependents).to eq([member3])
      end
    end

    context 'when both non filers and dependents present' do
      let(:member2) { double(financial_statements: [non_filer1]) }
      let(:member3) { double(financial_statements: [non_filer2]) } 
      let(:member4) { double(financial_statements: [dependent]) }
      let(:tax_household_members) { [member1, member2, member3, member4]}

      it 'should return non_filers without spouse relation and dependents' do
        expect(subject.primary).to eq(member1)
        expect(subject.spouse).to eq(member2) 
        expect(subject.dependents).to eq([member4, member3])
      end
    end
  end
end

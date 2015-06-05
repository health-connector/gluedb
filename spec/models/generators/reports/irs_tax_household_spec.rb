require 'rails_helper'

module Generators::Reports
  describe IrsTaxHousehold do

    subject { IrsTaxHousehold.new(tax_household, policy_ids) }

    let(:tax_household) { double(tax_household_members: tax_household_members, household: household) }
    let(:household) { double(family: family)}
    let(:family) { double }

    let(:tax_household_members) { [ member1 ] }
    let(:member1) { double(tax_filing_status: 'non_filer', family_member: family_member1) }

    let(:family_member1) { double(person: double) }
    let(:family_member2) { double(person: double) }
    let(:family_member3) { double(person: double) }

    let(:policy_ids) { [1234] }

    let(:policies) { [ double(subscriber: family_member2, id: 1234, enrollees: enrollees) ] }
    let(:enrollees) { [family_member1, family_member2, family_member3] }

    before(:each) do
      allow(subject).to receive(:find_policies).with(policy_ids).and_return(policies)
    end

    context 'when there is no tax_filer' do
      it 'should return primary as nil' do 
        subject.build
        expect(subject.primary).to be_nil
      end
    end

    context 'when there is a single tax_filer' do
      let(:member1) { double(tax_filing_status: 'tax_filer', family_member: family_member1) }

      it 'should return tax_filer as primary' do
        subject.build
        expect(subject.primary).to eq(member1)
      end
    end

    context 'when there is a single tax_filer with dependents' do
      let(:member1) { double(tax_filing_status: 'tax_filer', family_member: family_member1) }
      let(:member2) { double(tax_filing_status: 'dependent', family_member: family_member2) }
      let(:member3) { double(tax_filing_status: 'dependent', family_member: family_member3) }
      let(:tax_household_members) { [ member1, member2, member3 ] }

      it 'should return primary and dependents' do
        subject.build
        expect(subject.primary).to eq(member1)
        expect(subject.dependents).to eq([member2, member3])
      end
    end

    context 'when there are multiple tax filers' do 
      let(:member1) { double(tax_filing_status: 'tax_filer', family_member: family_member1) }
      let(:member2) { double(tax_filing_status: 'tax_filer', family_member: family_member2) }
      let(:member3) { double(tax_filing_status: 'dependent', family_member: family_member3) }

      let(:tax_household_members) { [ member1, member2, member3 ] }

      context 'primary applicant matches with tax_filer' do
        let(:family) { double(primary_applicant: family_member2) }

        it 'should return primary applicant as tax primary' do
          allow(member1).to receive(:tax_filing_together?).and_return(true)
          allow(member2).to receive(:tax_filing_together?).and_return(true)
          subject.build
          expect(subject.primary).to eq(member2)
          expect(subject.spouse).to eq(member1)
        end
      end

      context 'primary applicant not matches with tax_filer' do 
        let(:family) { double(primary_applicant: double) }

        it 'should return policy subscriber as primary' do 
          allow(member1).to receive(:tax_filing_together?).and_return(true)
          allow(member2).to receive(:tax_filing_together?).and_return(true)
          subject.build
          expect(subject.primary).to eq(member2)
          expect(subject.spouse).to eq(member1)          
        end
      end
    end

    context 'when there is a tax_filer and non_filer' do
      let(:member1) { double(tax_filing_status: 'tax_filer', family_member: family_member1) }
      let(:member2) { double(tax_filing_status: 'non_filer', family_member: family_member2) }
      let(:member3) { double(tax_filing_status: 'dependent', family_member: family_member3) }
      let(:tax_household_members) { [ member1, member2, member3 ] }
      let(:family_member1) { double(person: double, rel_code: 'self') }
      let(:family_member3) { double(person: double, rel_code: 'child') }

      context 'where non_filer has spouse relation ship on the policy' do
        let(:family_member2) { double(person: double, rel_code: 'spouse') }

        it 'should return primary, spouse and dependents' do
          subject.build
          expect(subject.primary).to eq(member1)
          expect(subject.spouse).to eq(member2)
          expect(subject.dependents).to eq([member3])
        end
      end

      context 'where non_filer has self relationship on the policy' do
        let(:family_member2) { double(person: double, rel_code: 'self') }
        let(:family_member1) { double(person: double, rel_code: 'spouse') }
        
        it 'should return primary, spouse and dependents' do
          subject.build
          expect(subject.primary).to eq(member1)
          expect(subject.spouse).to eq(member2)
          expect(subject.dependents).to eq([member3])
        end
      end

      context 'where non_filer has child relationship on the policy' do
        let(:family_member2) { double(person: double, rel_code: 'child') }

        it 'should return primary, spouse and dependents' do
          subject.build
          expect(subject.primary).to eq(member1)
          expect(subject.spouse).to be_nil
          expect(subject.dependents).to eq([member2, member3])
        end
      end
    end
  end
end
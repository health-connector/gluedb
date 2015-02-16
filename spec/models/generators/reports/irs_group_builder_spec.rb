require 'rails_helper'

module Generators::Reports
  describe IrsGroupBuilder do
    subject { IrsGroupBuilder.new(family) }

    let(:family) { double(households: households) }
    let(:households) { [household1, household2] }
    let(:household1) { double(tax_households: [double, double]) }
    let(:household2) { double }

    let(:mock_household) { PdfTemplates::Household.new }
    let(:mock_taxhousehold) { PdfTemplates::TaxHousehold.new }

    context 'when multiple households present' do
      it 'should append multiple to irs group' do 
        allow(subject).to receive(:build_household).and_return(mock_household)

        subject.build_households
        expect(subject.irs_group.households.count).to eq(households.count)
      end
    end

    context 'when building a household' do 
      context 'when multiple tax households present' do 
        it 'should build mulitple tax households' do 
          allow(subject).to receive(:build_tax_household).and_return(mock_taxhousehold)

          expect(subject.build_household(household1).tax_households.count).to eq(household1.tax_households.count)     
        end
      end
    end

    context 'building tax household' do 
    end

  end
end
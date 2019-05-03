require 'spec_helper'

describe Parsers::Edi::Etf::EmployerLoop do
  let(:employer_loop) { Parsers::Edi::Etf::EmployerLoop.new(raw_loop) }

  describe '#group_id' do
    let(:group_id) { '1234' }
    let(:raw_loop) { ['','','','', group_id] }

    it 'returns the group id' do
      expect(employer_loop.group_id).to eq group_id
    end
  end

  describe '#name' do
    let(:name) { 'SuperEmployer' }
    let(:raw_loop) { ['','', name,''] }

    it 'returns the employer name' do
      expect(employer_loop.name).to eq name
    end
  end

  describe '#fein' do
    let(:fein) { '12-34' }
    let(:raw_loop) { ['','', '', '', fein] }

    it 'returns the employer fein' do
      expect(employer_loop.fein).to eq "1234"
    end
  end

  describe '#specified_as_group?' do
    context 'when stated as employer group' do
      let(:raw_loop) { ['','','','94'] }

      it 'returns true' do
        expect(employer_loop.specified_as_group?).to eq true
      end
    end

    context 'when not specified as a group' do
      let(:raw_loop) { ['','','','  '] }
      it 'returns false' do
        expect(employer_loop.specified_as_group?).to eq false
      end
    end
  end

  describe '#id_qualifier' do
    let(:id_qualifier) { '94' }
    let(:raw_loop) { ['','','', id_qualifier] }

    it 'returns the qualifier' do
      expect(employer_loop.id_qualifier).to eq id_qualifier
    end
  end

end

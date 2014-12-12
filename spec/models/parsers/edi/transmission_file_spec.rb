require 'spec_helper'

describe Parsers::Edi::TransmissionFile do
  let(:pb) { double(:refresh => nil) }
  let(:transmission_file) { Parsers::Edi::TransmissionFile.new(' ', ' ', ' ', nil, pb) }
  describe '#persist_broker_get_id' do
    context 'transmission has no broker loop' do
      let(:etf_loop) { {"L1000C" => Hash.new } }
      it 'returns nil' do
        expect(transmission_file.persist_broker_get_id(etf_loop)).to eq nil
      end
    end

    context 'transmission has broker loop' do
      let(:name) { 'SuperBroker' }
      let(:npn) { 'npn' }
      let(:etf_loop) { { 'L1000C' => { 'N1' => ['','', name, '', npn] } } }
      context 'npn absent' do
        let(:npn) { ' ' }
        it 'returns nil' do
          expect(transmission_file.persist_broker_get_id(etf_loop)).to eq nil
        end
      end

      context 'npn present' do
        it 'returns a broker id' do
          expect(transmission_file.persist_broker_get_id(etf_loop)).not_to eq nil
        end
      end
    end
  end

  describe '#transaction_set_kind' do
    context 'transmission is not an effectuation' do
      it 'returns the kind unchanged' do
        kind = 'something'
        etf = Parsers::Edi::Etf::EtfLoop.new({'L2000s' => [ { "INS" => ['', '', '', ''] } ]})
        transmission_file.transmission_kind = kind
        expect(transmission_file.transaction_set_kind(etf)).to eq kind
      end
    end

    context 'transmission_kind is an effectuation' do
      let(:kind) { 'effectuation' }
      before { transmission_file.transmission_kind = kind }
      context 'cancellation or term' do
        it 'returns maintenance' do
          etf = Parsers::Edi::Etf::EtfLoop.new({'L2000s' => [ { "INS" => ['', '', '', '024'] } ]})
          expect(transmission_file.transaction_set_kind(etf)).to eq 'maintenance'
        end
      end

      context 'not a cancellation or term' do
        it 'returns the kind unchanged' do
          etf = Parsers::Edi::Etf::EtfLoop.new({'L2000s' => [ { "INS" => ['', '', '', 'xxx'] } ]})
          expect(transmission_file.transaction_set_kind(etf)).to eq kind
        end
      end
    end
  end

  describe '#responsible_party_loop' do
    let(:data) { 'the_data'}

    context 'when data is in Custodial Parent (2100f)' do
      let(:person_loops) { [ { 'L2100F' => data } ]  }
      it 'returns the loop data' do
        expect(transmission_file.responsible_party_loop(person_loops)).to eq data
      end
    end

    context 'when data is in Responsible Person(2100g)' do
      let(:person_loops) { [ { 'L2100G' => data } ] }
      it 'returns the loop data' do
        expect(transmission_file.responsible_party_loop(person_loops)).to eq data
      end
    end
  end
end

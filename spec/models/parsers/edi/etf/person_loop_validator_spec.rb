require 'rails_helper'

describe Parsers::Edi::PersonLoopValidator do
  let(:person_loop) { double(carrier_member_id: carrier_member_id)}
  let(:listener) { double }
  let(:policy) { nil }
  let(:validator) { Parsers::Edi::PersonLoopValidator.new }

  context ' carrier member id is missing' do
    let(:carrier_member_id) { ' ' }
    it 'notifies listener of missing carrier member id' do
      expect(listener).to receive(:missing_carrier_member_id).with(person_loop)
      expect(validator.validate(person_loop, listener, policy)).to eq false
    end
  end

  context 'carrier member id is present' do
    let(:carrier_member_id) { '1234' }

    it 'notifies listener of found carrier member id' do
      expect(listener).to receive(:found_carrier_member_id).with('1234')
      expect(validator.validate(person_loop, listener, policy)).to eq true
    end
  end
end

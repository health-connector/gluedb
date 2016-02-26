require 'rails_helper'

describe PolicyLoopValidator do
  let(:policy) { double(id: carrier_policy_id, action: :change)}
  let(:listener) { double }
  let(:validator) { PolicyLoopValidator.new }

  context ' carrier policy id is missing' do
    let(:carrier_policy_id) { ' ' }
    it 'notifies listener of missing carrier policy id' do
      expect(listener).to receive(:missing_carrier_policy_id)
      expect(validator.validate(policy, listener)).to eq false
    end

  end

  context 'carrier policy id is present' do
    let(:carrier_policy_id) { '1234' }

    it 'notifies listener of found carrier policy id' do
      expect(listener).to receive(:found_carrier_policy_id).with('1234')
      expect(validator.validate(policy, listener)).to eq true
    end
  end
end

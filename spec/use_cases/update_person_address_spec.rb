require 'spec_helper'
module TestBarrier

  describe UpdatePersonAddress do
    subject(:update_person) { UpdatePersonAddress.new(person_repo, address_changer, change_address_request_factory) }
    let(:listener) { double(has_errors?: false, success: false, :set_current_address => nil) }
    let(:person_repo) { double(find_by_id: person) }
    let(:change_address_request_factory) { double(from_person_update_request: change_address_request) }

    let(:change_address_request) do
      {
        person_id: "1",
        type: request[:addresses].first[:address_type],
        address1: request[:addresses].first[:address_1],
        address2: request[:addresses].first[:address_2],
        city: request[:addresses].first[:city],
        state: request[:addresses].first[:state],
        zip: request[:addresses].first[:zip],
        current_user: request[:current_user]
      }
    end

    let(:address_changer) { double(validate: true, commit: nil) }
    let(:person) { Person.new(name_first: 'Joe', name_last: 'Dirt', addresses: addresses, address_of: nil) }
    let(:addresses) { [existing_address] }
    let(:existing_address) do
      Address.new(existing_address_fields)
    end

    let(:existing_address_fields) {
      {
        address_type: existing_address_type,
        address_1: '1234 A street',
        address_2: '#321',
        city: 'Atlanta',
        state: 'GA',
        zip: '12345'
      }
    }

    let(:existing_address_type) { 'home' }

    let(:request) do
      {
        person_id: '1234',
        current_user: current_user,
        addresses: [
          requested_address_fields
        ]
      }
    end

    let(:current_user) { 'me@example.com' }

    let(:requested_address_fields) {
          {
            address_type: requested_address_type,
            address_1: '666 Halo Street',
            address_2: '#777',
            city: 'Orlando',
            state: 'FL',
            zip: '98765'
          }
    }

    let(:requested_address_type) { 'home' }

    it 'finds the person' do
      expect(person_repo).to receive(:find_by_id).with(request[:person_id])
      subject.execute(request, listener)
    end

    it 'saves the person' do
      expect(person).to receive(:save!)
      subject.execute(request, listener)
    end

    it 'labels person as updated by user' do
      subject.execute(request, listener)
      expect(person.updated_by).to eq current_user
    end

    context 'when the home address changes' do
      let(:existing_address_type) { 'home' }
      let(:requested_address_type) { 'home' }
      let(:listener) { double(has_errors?: false, success: nil, :set_current_address => nil) }

      it 'builds a change address request' do
        expect(change_address_request_factory).to receive(:from_person_update_request)
        subject.execute(request, listener)
      end

      it 'invokes the address changer' do
        expect(address_changer).to receive(:commit).with(change_address_request)
        subject.execute(request, listener)
      end
    end

    context 'when request doesnt have a home address' do
      let(:listener) { double(home_address_not_present: nil, has_errors?: true, fail: nil, :set_current_address => nil) }
      before { request[:addresses] = [{ address_type: 'work' }, { address_type: 'billing' }] }
      it 'notifies the listener' do
        expect(listener).to receive(:home_address_not_present)
        expect(listener).to receive(:fail)
        subject.execute(request, listener)
      end

      it 'does not save the person' do
        subject.execute(request, listener)
      end
    end

    context 'when request contains more than one address with the same type' do
      let(:listener) { double(:too_many_addresses_of_type, has_errors?: true, fail: nil, :set_current_address => nil) }
      before { request[:addresses] = [{ address_type: 'home' }, { address_type: 'home' }]}

      it 'notifies the listener' do
        expect(listener).to receive(:too_many_addresses_of_type).with({address_type: 'home', max: 1})
        expect(listener).to receive(:fail)
        subject.execute(request, listener)
      end
    end

    context 'when listener has received errors' do
      let(:listener) { double(has_errors?: true, fail: nil, :set_current_address => nil)}
      it 'does not save' do
        expect(person).not_to receive(:save!)
        subject.execute(request, listener)
      end
      it 'does not invoke the address changer' do
        expect(address_changer).not_to receive(:commit)
        subject.execute(request, listener)
      end
    end
  end
end

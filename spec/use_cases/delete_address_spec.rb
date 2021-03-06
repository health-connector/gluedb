require "spec_helper"

# class MyPStub
#   def initialize(pol, affected, included_enrollees)
#     @policy = pol
#     @affected = affected
#     @included_enrollees = included_enrollees
#   end

#   def each_affected_group
#     yield @policy, @affected, @included_enrollees
#   end
# end

describe DeleteAddress do
  subject { DeleteAddress.new(transmitter, person_repo, eligible_policy_factory) }
  # let(:propy_repo) { double(new: MyPStub.new(policy, affected_enrollees, included_enrollees) )}
  let(:eligible_policy_factory) { double(:for_person => eligible_policies) }
  let(:eligible_policies) { double(:empty? => false, too_many_health_policies?: false, too_many_dental_policies?: false) }
  let(:person_repo) { double(find_by_id: person) }
  let(:person) { double(save!: nil, address_of: address, :remove_address_of => nil) }
  let(:address) { double }
  let(:transmitter) { double(execute: nil) }
  let(:target_enrollee) { double(:m_id => '234', :person => person) }
  let(:affected_enrollees) { [target_enrollee] }
  let(:included_enrollees) { [target_enrollee] }

  let(:transmit_request) do
    {
      policy_id: policy.id,
      operation: 'change',
      reason: 'change_of_location',
      affected_enrollee_ids: affected_enrollee_ids,
      include_enrollee_ids: include_enrollee_ids,
      current_user: 'me@example.com' 
    }
  end
  let(:affected_enrollee_ids) { [target_enrollee.m_id] }
  let(:include_enrollee_ids) { [target_enrollee.m_id] }
  let(:policy) { double(id: '1234')}

  let(:request) do
    {
      person_id: '1',
      type: 'home',
      transmit: true,
      current_user: 'me@example.com' 
    }
  end

  before {
    allow(eligible_policies).to receive(:each_affected_group).and_yield(policy, [target_enrollee], [target_enrollee])
  }

  it 'finds the person' do
    expect(person_repo).to receive(:find_by_id).with(request[:person_id])
    subject.commit(request)
  end

  it 'looks for the address of type' do
    expect(person).to receive(:address_of).with(request[:type])
    subject.commit(request)
  end

  it 'removes the address' do
    expect(person).to receive(:save!)
    subject.commit(request)
  end

  it 'transmits the changes' do
    expect(transmitter).to receive(:execute).with(transmit_request)
    subject.commit(request)
  end

  context 'when address type does not exist' do
    let(:address) { nil }
    it 'does not update the person' do
      expect(person).not_to receive(:save!)
      subject.commit(request)
    end

    it 'does not transmit the changes' do
      expect(transmitter).not_to receive(:execute)
      subject.commit(request)
    end
  end

end


  # let(:address_to_be_removed) { 
  #     Address.new(address_type: requested_address_type, 
  #       address_1: '1234 A street', 
  #       address_2: '#321', 
  #       city: 'Atlanta', 
  #       state: 'GA', 
  #       zip: '12345') 
  #   }
  #   let(:addresses) { [existing_address, address_to_be_removed] }

  #   before { request[:addresses] = [existing_address_fields] }

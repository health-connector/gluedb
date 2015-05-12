require 'rails_helper'

describe Household do

  subject { Household.new }

  let(:hbx_enrollments) { [enrollment1, enrollment2] }
  let(:enrollment1) { double(policy: policy1, policy_id: 1)}
  let(:enrollment2) { double(policy: policy2, policy_id: 2)}

  let(:policy1) { double(id: 1, subscriber: subscriber, enrollees: [subscriber, dependent1]) }
  let(:policy2) { double(id: 2, subscriber: subscriber, enrollees: [subscriber, dependent1]) }

  let(:subscriber) { double(person: person) }
  let(:dependent1) { double(person: person) }

  let(:person) { double(full_name: 'Ann B Mcc') }


  context 'policy coverage households' do

    it 'should group policies by subscriber' do
      allow(subject).to receive(:hbx_enrollments).and_return(hbx_enrollments)
        expect(subject.policy_coverage_households.size).to eq(1)
      expect(subject.policy_coverage_households[0][:policy_ids]).to eq([1,2])
      expect(subject.policy_coverage_households[0][:primary]).to eq(person)
    end 

    context 'when we have two policies with different subscribers' do 
      let(:policy2) { double(id: 2, subscriber: subscriber1, enrollees: [subscriber1, dependent1]) }
      let(:subscriber1) { double(person: person1) }
      let(:person1) { double(full_name: 'Joe') }

      it 'should have coverage household for each policy' do 
        allow(subject).to receive(:hbx_enrollments).and_return(hbx_enrollments)
        expect(subject.policy_coverage_households.size).to eq(2)
        expect(subject.policy_coverage_households[0][:primary]).to eq(person)
        expect(subject.policy_coverage_households[0][:policy_ids]).to eq([1])
        expect(subject.policy_coverage_households[1][:primary]).to eq(person1)
        expect(subject.policy_coverage_households[1][:policy_ids]).to eq([2])
      end
    end

    context 'when we have three policies with two under same subscriber' do 
      let(:hbx_enrollments) { [enrollment1, enrollment2, enrollment3] }

      let(:policy2) { double(id: 2, subscriber: subscriber1) }
      let(:subscriber1) { double(person: person1) }
      let(:person1) { double(full_name: 'Joe') }

      let(:enrollment3) { double(policy: policy3, policy_id: 3)}
      let(:policy3) { double(id: 2, subscriber: subscriber) }


      it 'should add policies with same subcriber under same coverage household' do 
        allow(subject).to receive(:hbx_enrollments).and_return(hbx_enrollments)
        expect(subject.policy_coverage_households.size).to eq(2)
        expect(subject.policy_coverage_households[0][:primary]).to eq(person)
        expect(subject.policy_coverage_households[0][:policy_ids]).to eq([1, 3])
        expect(subject.policy_coverage_households[1][:primary]).to eq(person1)
        expect(subject.policy_coverage_households[1][:policy_ids]).to eq([2])
      end
    end
  end
end
require 'spec_helper'
require './lib/renewals_generator'

describe RenewalsGenerator do

  subject { RenewalsGenerator.new }

  let(:enrollee1) { double(m_id: "100001")}
  let(:enrollee2) { double(m_id: "100002")}
  let(:enrollee3) { double(m_id: "100003")}
  let(:enrollee4) { double(m_id: "100004")}
  let(:health) { double(plan: health_plan, enrollees: [enrollee1, enrollee2]) }
  let(:health_plan) { double(coverage_type: 'health')}
  let(:dental) { double(plan: dental_plan, enrollees: [enrollee1, enrollee2]) }
  let(:dental_plan) { double(coverage_type: 'dental')}

  context 'group polices for notices' do
    context 'when two health policies present' do 
      let(:policies) { [health, health]}
      it 'should return array of health policies' do
        output = subject.group_policies_for_noticies(policies)
        expect(output).to eq [[health, nil], [health, nil]]
      end
    end

    context 'when two dental policies present' do 
      let(:policies) { [dental, dental]}
      it 'should return array of dentail policies' do
        output = subject.group_policies_for_noticies(policies)
        expect(output).to eq [[nil,dental], [nil,dental]]
      end     
    end

    context 'when two health and one dental polcies present' do
      let(:health1) { double(plan: health_plan, enrollees: [enrollee1, enrollee2]) }
      let(:health2) { double(plan: health_plan, enrollees: [enrollee1, enrollee2, enrollee3]) }
      let(:policies) { [health1, health2, dental]}
      it 'should group polices with same enrollees' do
        output = subject.group_policies_for_noticies(policies)
        expect(output).to eq [[health1, dental], [health2, nil]]
      end
    end

    context 'when one health and two dental polcies present' do
      let(:dental1) { double(plan: dental_plan, enrollees: [enrollee1, enrollee2]) }
      let(:dental2) { double(plan: dental_plan, enrollees: [enrollee1, enrollee2, enrollee3]) }
      let(:policies) { [health, dental1, dental2]}
      it 'should group polices with same enrollees' do
        output = subject.group_policies_for_noticies(policies)
        expect(output).to eq [[health, dental1], [nil, dental2]]
      end       
    end

    context 'when one health and one dental policy with same enrollees' do
      let(:health1) { double(plan: health_plan, enrollees: [enrollee1, enrollee2]) }
      let(:dental1) { double(plan: dental_plan, enrollees: [enrollee1, enrollee2]) }
      let(:policies) { [health1, dental1]}
      it 'should group polices with same enrollees' do
        output = subject.group_policies_for_noticies(policies)
        expect(output).to eq [[health1, dental1]]
      end      
    end

    context 'when one health and one dental policy with different enrollees' do
      let(:health1) { double(plan: health_plan, enrollees: [enrollee1, enrollee2, enrollee3]) }
      let(:dental1) { double(plan: dental_plan, enrollees: [enrollee1, enrollee2]) }
      let(:policies) { [health1, dental1]}
      it 'should group polices with same enrollees' do
        output = subject.group_policies_for_noticies(policies)
        expect(output).to eq [[health1, nil], [nil, dental1]]
      end
    end 

    context 'when single health policy present' do
      let(:policies) { [health]}
      it 'should group polices with same enrollees' do
        output = subject.group_policies_for_noticies(policies)
        expect(output).to eq [[health, nil]]
      end     
    end

    context 'when single dental policy present' do 
      let(:policies) { [dental]}
      it 'should group polices with same enrollees' do
        output = subject.group_policies_for_noticies(policies)
        expect(output).to eq [[nil, dental]]
      end       
    end

    context 'when more than one health and dentail policies present' do 
      let(:health1) { double(plan: health_plan, enrollees: [enrollee1, enrollee2]) }
      let(:health2) { double(plan: health_plan, enrollees: [enrollee1, enrollee2, enrollee3]) }
      let(:dental1) { double(plan: dental_plan, enrollees: [enrollee1, enrollee2]) }
      let(:dental2) { double(plan: dental_plan, enrollees: [enrollee1, enrollee2, enrollee3]) }

      let(:policies) { [health1, dental1, health2, dental2]}
      it 'should group polices with same enrollees' do
        output = subject.group_policies_for_noticies(policies)
        expect(output).to eq [[health1, dental1], [health2, dental2]]
      end
    end

    context 'when more than two health and one dentail policy present' do 
      let(:health1) { double(plan: health_plan, enrollees: [enrollee1, enrollee2]) }
      let(:health2) { double(plan: health_plan, enrollees: [enrollee1, enrollee2, enrollee3]) }
      let(:health3) { double(plan: health_plan, enrollees: [enrollee1, enrollee2, enrollee3, enrollee4]) }
      let(:dental2) { double(plan: dental_plan, enrollees: [enrollee1, enrollee2, enrollee3]) }

      let(:policies) { [health1, health2, health3, dental2]}
      it 'should group polices with same enrollees' do
        output = subject.group_policies_for_noticies(policies)
        expect(output).to eq [[health1, nil], [health2, dental2], [health3, nil]]
      end
    end

  end
end
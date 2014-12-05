require 'rails_helper'

shared_examples "coverage ended with correct responsible amount" do
  describe "when a shop enrollment" do
    let(:employer) { Employer.new(:name => "Fake Shell Corp, LLC") }

    before {
      policy.employer = employer
      policy.tot_emp_res_amt = previous_employer_contribution
    }
    it "should properly re-calculate the employer contribution amount" do
      end_coverage.execute(request)
      expect(policy.tot_emp_res_amt).to eql(expected_employer_contribution)
    end

    it "should set the total responsible amount to the premium total minus the employer contribution" do
      end_coverage.execute(request)
      expect(policy.tot_res_amt).to eql(policy.pre_amt_tot - expected_employer_contribution)
    end
  end

  describe "when an individual enrollment" do
    it "should set the responsible amount equal to the new premium total" do
      end_coverage.execute(request)
      expect(policy.tot_res_amt).to eql(policy.pre_amt_tot)
    end
  end
end

describe EndCoverage do
  subject(:end_coverage) { EndCoverage.new(action_factory, policy_repo) }
  let(:request) do
    {
      policy_id: policy.id,
      affected_enrollee_ids: affected_enrollee_ids,
      coverage_end: coverage_end,
      operation: operation,
      reason: 'death',
      current_user: current_user,
      transmit: true
    }
  end

  let(:action_request) do
    {
      policy_id: policy.id,
      operation: request[:operation],
      reason: request[:reason],
      affected_enrollee_ids: request[:affected_enrollee_ids],
      include_enrollee_ids: enrollees.map(&:m_id),
      current_user: current_user
    }
  end

  let(:affected_enrollee_ids) { [subscriber.m_id, member.m_id] }
  let(:coverage_end) { Date.new(2014, 1, 14)}
  let(:operation) { 'terminate' }
  let(:current_user) { 'joe@example.com' }

  let(:policy_repo) { double(find: policy) }
  let(:policy) { Policy.create!(eg_id: '1', enrollees: enrollees, pre_amt_tot: premium_total, plan_id: "1") }
  let(:premium_total) { 300.00 }
  let(:enrollees) { [ subscriber, member ]}
  let(:subscriber) { Enrollee.new(rel_code: 'self', coverage_start: coverage_start, pre_amt: 100.00, ben_stat: 'active', emp_stat: 'active',  m_id: '1') }
  let(:member) { Enrollee.new(rel_code: 'child', coverage_start: coverage_start, pre_amt: 200.00, ben_stat: 'active', emp_stat: 'active',  m_id: '2') }
  let(:previous_employer_contribution) { 248.33 }
  
  let(:action_factory) { double(create_for: action) }
  let(:action) { double(execute: nil) }
  let(:coverage_start) { Date.new(2014, 1, 2)}

  it 'finds the policy' do
    expect(policy_repo).to receive(:find).with(policy.id)
    end_coverage.execute(request)
  end

  it 'labels policy as updated by user' do
    end_coverage.execute(request)
    expect(policy.updated_by).to eq current_user
  end

  it 'creates a resulting action' do
    expect(action_factory).to receive(:create_for).with(request)
    end_coverage.execute(request)
  end

  it 'invokes the resulting action' do
    expect(action).to receive(:execute).with(action_request)
    end_coverage.execute(request)
  end

  context 'no one is affected' do
    let(:affected_enrollee_ids) { [] }
    it "doesn't execute the resulting action" do
      expect(action).not_to receive(:execute)
      end_coverage.execute(request)
    end
  end

  context 'when subscriber\'s coverage ends' do
    let(:affected_enrollee_ids) { [ subscriber.m_id ] }

    before { end_coverage.execute(request) }

    it 'affects all enrollees' do
      policy.enrollees.each do |e|
        expect(e.coverage_status).to eq 'inactive'
        expect(e.coverage_end).to eq request[:coverage_end]
      end
    end

    context 'by cancelation' do
      let(:operation) { 'cancel' }
      let(:coverage_start) { Date.new(2014, 1, 2)}
      let(:coverage_end) { coverage_start }
      let(:expected_employer_contribution) { 248.33 }

      it 'adjusts premium total to be the sum of all enrollees\' premiums' do
        sum = 0
        policy.enrollees.each do |e|
          sum += e.pre_amt
        end
        expect(policy.pre_amt_tot.to_f).to eq sum.to_f
      end

      it 'updates policy status' do
        expect(policy.aasm_state).to eq 'canceled'
      end

      it_behaves_like "coverage ended with correct responsible amount"
    end

    context 'by termination' do
      let(:operation) { 'terminate' }
      let(:coverage_start) { Date.new(2014, 1, 2)}
      let(:coverage_end) { Date.new(2014, 1, 14)}
      let(:expected_employer_contribution) { 248.33 }

      context 'when member\'s coverage ended previously' do
        let(:member) { Enrollee.new(rel_code: 'child', pre_amt: 200.00, coverage_status: 'inactive', coverage_start: Date.new(2014, 1, 2), coverage_end:  Date.new(2014, 1, 2), ben_stat: 'active', emp_stat: 'active',  m_id: '2') }
        let(:previous_employer_contribution) { 82.77 }
        let(:expected_employer_contribution) { 82.77 }

        it 'new policy premium total doesnt include member' do
          sum = 0
          policy.enrollees.each do |e|
            sum += e.pre_amt if e.coverage_end == subscriber.coverage_end
          end

          expect(policy.pre_amt_tot.to_f).to eq sum.to_f
        end
      end
      it 'updates policy status' do
        expect(policy.aasm_state).to eq 'terminated'
      end

      it_behaves_like "coverage ended with correct responsible amount"
    end

  end

  context 'when a member\'s coverage is ended' do
    let(:affected_enrollee_ids) { [member.m_id] }
    let(:expected_employer_contribution) { 82.77 }

    it 'doesn\'t end the subscribers coverage' do
      end_coverage.execute(request)
      expect(subscriber.coverage_status).to eq 'active'
    end

    it 'ends the member\'s coverage' do
      end_coverage.execute(request)
      expect(member.coverage_status).to eq 'inactive'
      expect(member.coverage_end).to eq request[:coverage_end]
    end

    it 'deducts member\'s premium from policy\'s total'  do
      end_coverage.execute(request)
      expect(policy.pre_amt_tot.to_f).to eq(100.00)
    end

    it_behaves_like "coverage ended with correct responsible amount"

    context 'by cancelation' do
      let(:operation) { 'cancel' }
      it 'sets the benefit end date to be equal to benefit begin date' do
        end_coverage.execute(request)
        expect(member.coverage_end).to eq member.coverage_start
      end
    end

    context 'and the members coverage is already ended' do
      let(:inactive_member) { Enrollee.new(rel_code: 'child', coverage_status: 'inactive', coverage_start: coverage_start, coverage_end: already_ended_date, pre_amt: 50.00, ben_stat: 'active', emp_stat: 'active',  m_id: '3') }
      let(:already_ended_date) { request[:coverage_end].prev_year }
      before do
        affected_enrollee_ids << inactive_member.m_id
        policy.enrollees << inactive_member
        policy.save
      end

      it 'does not change their coverage end date' do
        expect { end_coverage.execute(request) }.not_to change{ inactive_member.coverage_end }
      end
    end
  end
end

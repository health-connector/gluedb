require "rails_helper"

describe ::ExternalEvents::EnrollmentEventNotification do
  let(:m_tag) { double('m_tag') }
  let(:t_stamp) { double('t_stamp') }
  let(:e_xml) { double('e_xml') }
  let(:headers) { double('headers') }
  let(:responder) { instance_double('::ExternalEvents::EventResponder') }

  let :enrollment_event_notification do
    ::ExternalEvents::EnrollmentEventNotification.new responder, m_tag, t_stamp, e_xml, headers
  end

  describe "#drop_if_bogus_plan_year!" do
    subject { enrollment_event_notification.drop_if_bogus_plan_year! }

    context 'of a notification without a bogus plan year' do
      before { allow(enrollment_event_notification).to receive('has_bogus_plan_year?').and_return(false) }

      it 'returns false if has_bogus_plan_year is false' do
        expect(subject).to be_falsey
      end
    end

    context 'of a notification with a bogus plan year' do
      let(:result_publisher) { double :drop_bogus_plan_year! => true }

      before do
        allow(enrollment_event_notification).to receive('has_bogus_plan_year?').and_return(true)
        allow(enrollment_event_notification).to receive('response_with_publisher').and_yield(result_publisher)
      end

      it 'drops bogus plan year if has_bogus_plan_year is true' do
        subject
        expect(result_publisher).to have_received('drop_bogus_plan_year!')
      end
    end
  end

  describe "#drop_if_bogus_term!" do
    subject { enrollment_event_notification.drop_if_bogus_term! }

    context 'of a notification without a bogus_termination' do
      it 'returns false' do
        expect(subject).to be_falsey
      end
    end

    context 'of a notification with a bogus termination' do
      let(:result_publisher) { double :drop_bogus_term! => true }

      before do
        enrollment_event_notification.instance_variable_set :@bogus_termination, true
        allow(enrollment_event_notification).to receive('response_with_publisher').and_yield(result_publisher)
      end

      it 'calls drops_bogus_term! on result_publisher' do
        subject
        expect(result_publisher).to have_received('drop_bogus_term!').with(enrollment_event_notification)
      end
    end
  end

  describe "#check_for_bogus_term_against" do
    let(:others) { spy Array.new([ other ]) }

    subject { enrollment_event_notification.check_for_bogus_term_against(others) }

    context 'of a non-termination event' do
      let(:other) { double }

      before do
        allow(enrollment_event_notification).to receive('is_termination?').and_return(false)
      end

      it 'returns nothing' do
        expect(subject).to be_nil
      end

      it 'does nothing' do
        subject
        expect(others).to_not have_received('each')
      end
    end

    context 'of a termination event' do
      before do
        allow(enrollment_event_notification).to receive('is_termination?').and_return(true)
      end

      context 'an enrollment with coverage starter' do
        let(:other) { double :is_coverage_starter? => true }

        it 'sets @bogus_termination to false' do
          expect(enrollment_event_notification.instance_variable_get(:@bogus_termination)).to be_falsey
        end
      end

      context 'an enrollment that is not coverage starter' do
        let(:other) { double :is_coverage_starter? => false }

        before { allow(enrollment_event_notification).to receive('existing_policy').and_return(nil) }

        it 'sets @bogus_termination to existing_policy.nil?' do
          subject
          expect(enrollment_event_notification).to have_received('existing_policy')
        end
      end
    end
  end

  describe "#edge_for" do
    let(:graph) { double 'graph', :add_edge => true }
    let(:other) { double 'other', :hbx_enrollment_id => 1 }

    subject { enrollment_event_notification.edge_for(graph, other) }

    context 'other being the same enrollment' do
      before { allow(enrollment_event_notification).to receive('hbx_enrollment_id').and_return(1) }

      context 'when other is termination, and self is not' do
        before do
          allow(other).to                         receive(:is_termination?).and_return(true)
          allow(enrollment_event_notification).to receive(:is_termination?).and_return(false)
        end

        it 'adds edge to graph of enrollment_event_notification to other' do
          subject
          expect(graph).to have_received('add_edge').with(enrollment_event_notification, other)
        end
      end

      context 'when other is not termination, and self is' do
        before do
          allow(other).to                         receive(:is_termination?).and_return(false)
          allow(enrollment_event_notification).to receive(:is_termination?).and_return(true)
        end

        it 'adds edge to graph of other to enrollment_event_notification' do
          subject
          expect(graph).to have_received('add_edge').with(other, enrollment_event_notification)
        end
      end

      context 'other cases' do
        before do
          allow(other).to                         receive(:is_termination?).and_return(false)
          allow(enrollment_event_notification).to receive(:is_termination?).and_return(false)
        end

        it 'returns :ok' do
          expect(subject).to eql(:ok)
        end
      end
    end

    context 'enrollment_event_notification and other being different years' do
      before do
        allow(enrollment_event_notification).to receive('hbx_enrollment_id').and_return(2)
      end

      context 'and other being before enrollment_event_notification' do
        before do
          allow(other).to                         receive(:active_year).and_return(2016)
          allow(enrollment_event_notification).to receive(:active_year).and_return(2017)
        end

        it 'adds edge to graph of other to enrollment_event_notification' do
          subject
          expect(graph).to have_received('add_edge').with(other, enrollment_event_notification)
        end
      end

      context 'and enrollment_event_notification being before other' do
        before do
          allow(other).to                         receive(:active_year).and_return(2017)
          allow(enrollment_event_notification).to receive(:active_year).and_return(2016)
        end

        it 'adds edge to graph of enrollment_event_notification to other' do
          subject
          expect(graph).to have_received('add_edge').with(enrollment_event_notification, other)
        end
      end
    end

    context "subscriber_start is different" do
      before do
        allow(other).to                         receive(:active_year).and_return(2017)
        allow(enrollment_event_notification).to receive(:active_year).and_return(2017)
        allow(enrollment_event_notification).to receive('hbx_enrollment_id').and_return(2)
      end

      context 'and other is before enrollment_event_notification' do
        before do
          allow(other).to                         receive(:subscriber_start).and_return(2016)
          allow(enrollment_event_notification).to receive(:subscriber_start).and_return(2017)
        end

        it 'adds edge to graph of other to enrollment_event_notification' do
          subject
          expect(graph).to have_received('add_edge').with(other, enrollment_event_notification)
        end
      end

      context 'and enrollment_event_notification is before other' do
        before do
          allow(other).to                         receive(:subscriber_start).and_return(2017)
          allow(enrollment_event_notification).to receive(:subscriber_start).and_return(2016)
        end

        it 'adds edge to graph of enrollment_event_notification to other' do
          subject
          expect(graph).to have_received('add_edge').with(enrollment_event_notification, other)
        end
      end
    end

    context 'other scenarios like' do
      before do
        allow(other).to                         receive(:active_year).and_return(2017)
        allow(enrollment_event_notification).to receive(:active_year).and_return(2017)
        allow(other).to                         receive(:subscriber_start).and_return(2017)
        allow(enrollment_event_notification).to receive(:subscriber_start).and_return(2017)
        allow(enrollment_event_notification).to receive('hbx_enrollment_id').and_return(2)
      end

      context "when both other's and enrollment_event_notification's subscriber_end is nil" do
        before do
          allow(other).to                         receive(:subscriber_end).and_return(nil)
          allow(enrollment_event_notification).to receive(:subscriber_end).and_return(nil)
        end

        it 'returns :ok' do
          expect(subject).to eql(:ok)
        end
      end

      context "when other's subscriber_end is nil" do
        before do
          allow(other).to                         receive(:subscriber_end).and_return(nil)
          allow(enrollment_event_notification).to receive(:subscriber_end).and_return(1)
        end

        it 'adds edge to graph of enrollment_event_notification to other' do
          subject
          expect(graph).to have_received('add_edge').with(enrollment_event_notification, other)
        end
      end

      context "when enrollment_event_notification's subscriber_end is nil" do
        before do
          allow(other).to                         receive(:subscriber_end).and_return(1)
          allow(enrollment_event_notification).to receive(:subscriber_end).and_return(nil)
        end

        it 'adds edge to graph of other to enrollment_event_notification' do
          subject
          expect(graph).to have_received('add_edge').with(other, enrollment_event_notification)
        end
      end

      context "when enrollment_event_notification's subscriber_end is before other's" do
        before do
          allow(other).to                         receive(:subscriber_end).and_return(2)
          allow(enrollment_event_notification).to receive(:subscriber_end).and_return(1)
        end

        it 'adds edge to graph of enrollment_event_notification to other' do
          subject
          expect(graph).to have_received('add_edge').with(enrollment_event_notification, other)
        end
      end

      context "when other's subscriber_end is before enrollment_event_notification's" do
        before do
          allow(other).to                         receive(:subscriber_end).and_return(1)
          allow(enrollment_event_notification).to receive(:subscriber_end).and_return(2)
        end

        it 'adds edge to graph of other to enrollment_event_notification' do
          subject
          expect(graph).to have_received('add_edge').with(other, enrollment_event_notification)
        end
      end
    end
  end

  describe "#drop_if_bogus_renewal_term!" do
    subject { enrollment_event_notification.drop_if_bogus_renewal_term! }

    context 'of a notification without a bogus_renewal_termination' do
      it 'returns false' do
        expect(subject).to be_falsey
      end
    end

    context 'of a notification with a bogus renewal termination' do
      let(:result_publisher) { double :drop_bogus_renewal_term! => true }

      before do
        enrollment_event_notification.instance_variable_set :@bogus_renewal_termination, true
        allow(enrollment_event_notification).to receive('response_with_publisher').and_yield(result_publisher)
      end

      it 'calls drops_bogus_renewal_term! on result_publisher' do
        subject
        expect(result_publisher).to have_received('drop_bogus_renewal_term!').with(enrollment_event_notification)
      end
    end
  end

  describe "#check_for_bogus_renewal_term_against" do
    let(:other) { double 'other' }
    subject { enrollment_event_notification.check_for_bogus_renewal_term_against(other) }

    context 'when other is termination' do
      before { allow(other).to receive('is_termination?').and_return(true) }

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context 'when enrollment_event_notification is not termination' do
      before do
        allow(other).to                         receive('is_termination?').and_return(false)
        allow(enrollment_event_notification).to receive('is_termination?').and_return(false)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context "when enrollment_event_notification subscriber_end is not the same as other's subscriber_start" do
      before do
        allow(other).to                         receive('is_termination?').and_return(false)
        allow(enrollment_event_notification).to receive('is_termination?').and_return(true)
        allow(other).to                         receive('subscriber_start').and_return(Date.today)
        allow(enrollment_event_notification).to receive('subscriber_end').and_return(Date.today)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context "when enrollment_event_notification active year does not precede other's active_year" do
      before do
        allow(other).to                         receive('is_termination?').and_return(false)
        allow(enrollment_event_notification).to receive('is_termination?').and_return(true)
        allow(other).to                         receive('subscriber_start').and_return(Date.today)
        allow(enrollment_event_notification).to receive('subscriber_end').and_return(Date.yesterday)
        allow(other).to                         receive('active_year').and_return(2017)
        allow(enrollment_event_notification).to receive('active_year').and_return(2016)
      end

      it 'returns nil' do
        expect(subject).to be_nil
      end
    end

    context "other scenarios" do
      before do
        allow(other).to                         receive('is_termination?').and_return(false)
        allow(enrollment_event_notification).to receive('is_termination?').and_return(true)
        allow(other).to                         receive('subscriber_start').and_return(Date.today)
        allow(enrollment_event_notification).to receive('subscriber_end').and_return(Date.yesterday)
        allow(other).to                         receive('active_year').and_return(2016)
        allow(enrollment_event_notification).to receive('active_year').and_return(2017)
      end

      it 'sets @bogus_renewal_termination to true' do
        subject
        expect(enrollment_event_notification.instance_variable_get(:@bogus_renewal_termination)).to be_truthy
      end
    end
  end
end

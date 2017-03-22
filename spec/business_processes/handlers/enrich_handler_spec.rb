require "rails_helper"

describe Handlers::EnrichHandler do
  let(:app) { double 'app' }
  let(:enrich_handler) { Handlers::EnrichHandler.new(app) }

  describe "#call" do
    let(:context) do
      double 'context',
        business_process_history: nil,
        :business_process_history= => nil,
        errors: errors,
        event_list: nil,
        :event_message= => Proc.new { |x| x }
    end

    let(:event_list_element) { double 'event_list_element' }

    subject { enrich_handler.call(context) }

    before do
      allow(app).to receive('call').and_return(nil)
      allow(enrich_handler).to receive('merge_or_split').and_return([event_list_element])
      allow(enrich_handler).to receive('duplicate_context').and_return(context)
    end

    context "with a context that has errors" do
      let(:errors) { double 'errors', has_errors?: true }

      it 'returns the context in an array' do
        expect(subject).to match([context])
      end
    end

    context "with an error free context" do
      let(:errors) { double 'errors', has_errors?: false }

      it 'calls super' do
        subject
        expect(app).to have_received('call').with(context)
      end
    end
  end

  describe '#duplicate_context' do
    let(:context) { double 'context', :event_message= => nil }

    let(:event_xml) { double 'event_xml' }

    subject { enrich_handler.duplicate_context context, event_xml }

    before do
      allow(context).to receive('clone').and_return(context)
      subject
    end

    it 'clones the context' do
      expect(context).to have_received('clone')
    end

    it 'sets the cloned context event_message to event_xml' do
      expect(context).to have_received('event_message=').with(event_xml)
    end

    it 'returns the context' do
      expect(subject).to eql(context)
    end
  end

  describe "#merge_or_split" do
    let(:errors) { double 'errors', add: nil }
    let(:context) { double 'context', errors: errors }
    let(:event) do
      double 'event',
        event_xml: '<xml><lol /></xml>'
    end
    let(:event_list) { spy Array.new([event]) }

    before do
      allow(enrich_handler).to receive('enrollment_event_cv_for').and_return(double('enrollment_event_cv_for'))
      allow(enrich_handler).to receive('extract_policy').and_return(double('extract_policy'))
      allow(enrich_handler).to receive('already_exists?').and_return(false)
    end


    subject { enrich_handler.merge_or_split context, event_list }

    it 'finds the enrollment_event_cv for the last event' do
      subject
      expect(enrich_handler).to have_received('enrollment_event_cv_for').with(event_list)
    end

    context 'of an event_list with more then one event' do
      before do
        allow(event_list).to receive('length').and_return(2)
        subject
      end

      it 'adds an error to the context' do
        expect(errors).to have_received('add').with(:process, "These events represent a compound event flow, and we don't handle that yet.")
      end

      it 'returns an empty array' do
        expect(subject).to match([])
      end
    end

    context 'of an already existing policy cv' do
      before do
        allow(enrich_handler).to receive('already_exists?').and_return(true)
        allow(event_list).to receive('length').and_return(1)
        subject
      end

      it 'adds an error' do
        expect(errors).to have_received('add').with(:process, "The enrollment to create already exists")
      end
    end
  end
end

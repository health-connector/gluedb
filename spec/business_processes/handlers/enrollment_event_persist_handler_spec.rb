require "rails_helper"

describe Handlers::EnrollmentEventPersistHandler do
  let(:app) { double call: nil }
  subject { Handlers::EnrollmentEventPersistHandler.new(app) }

  before { subject.call(context) }

  context 'an event that is persisted' do
    let(:context) { instance_double(EnrollmentAction::Base, persist: true, update_business_process_history: nil) }

    it 'calls super on the app' do
      expect(app).to have_received(:call)
    end
  end

  context 'an event that is not persisted' do
    let(:context) { instance_double(EnrollmentAction::Base, persist: false, persist_failed!: nil) }

    it 'calls persist_failed! on the context' do
      expect(context).to have_received(:persist_failed!).with({})
    end
  end

  context 'an event that raises an exception' do
    let(:context) do
      instance_double(EnrollmentAction::Base).tap do |context|
        allow(context).to receive(:drop_not_yet_implemented!)
        allow(context).to receive(:persist).and_raise(NotImplementedError)
      end
    end

    it 'calls drop_not_yet_implemented! on the context' do
      expect(context).to have_received(:drop_not_yet_implemented!)
    end
  end
end

require "rails_helper"

describe Handlers::EnrollmentEventPersistHandler do
  let(:app) { double call: nil }
  subject { Handlers::EnrollmentEventPersistHandler.new(app) }


  context 'an event that is persisted' do
    let(:context) { instance_double(EnrollmentAction::Base, persist: true, update_business_process_history: nil) }

    it 'calls super on the app' do
      expect(app).to receive(:call).with(context)
      subject.call(context)
    end
  end

  context 'an event that is not persisted' do
    let(:context) { instance_double(EnrollmentAction::Base, persist: false, persist_failed!: nil, errors: errors) }
    let(:errors_hash) { double }
    let(:errors) { double(to_hash: errors_hash) }

    it 'calls persist_failed! on the context with the errors from the context' do
      expect(context).to receive(:persist_failed!).with(errors_hash)
      subject.call(context)
    end
  end

  context 'an event that raises an exception' do
    before(:each) do 
      allow(context).to receive(:drop_not_yet_implemented!)
      allow(context).to receive(:persist).and_raise(NotImplementedError)
    end

    let(:context) { instance_double(EnrollmentAction::Base) }

    it 'calls drop_not_yet_implemented! on the context' do
      expect(context).to receive(:drop_not_yet_implemented!)
      subject.call(context)
    end
  end
end

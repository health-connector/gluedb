require 'rails_helper'

describe EmployerEvents::CarrierFile, "given a carrier" do
  let(:carrier) { instance_double(Carrier) }
  
  subject { EmployerEvents::CarrierFile.new(carrier) }

  describe "and asked to render_event_using a renderer, and an employer_event" do
    let(:employer_id) { "some employer id" }
    let(:employer_event) { EmployerEvent.new(:employer_id => employer_id) }
    let(:event_renderer) { instance_double(EmployerEvents::Renderer, :timestamp => Time.now) }
    let(:buffer) { double }

    before :each do
      allow(StringIO).to receive(:new).and_return(buffer)
      allow(event_renderer).to receive(:render_for).with(carrier, buffer).
        and_return(event_render_result)
      subject.render_event_using(event_renderer, employer_event)
    end

    describe "when the employer_event is rendered by the renderer" do
      let(:event_render_result) { true }

      it "is NOT empty" do
        expect(subject.empty?).to be_falsey
      end

      it "has the employer id in rendered_employers" do
        expect(subject.rendered_employers).to include(employer_id)
      end
    end

    describe "when the employer_event is NOT rendered by the renderer" do
      let(:event_render_result) { false }

      it "is empty" do
        expect(subject.empty?).to be_truthy
      end

      it "does not have the employer id in rendered_employers" do
        expect(subject.rendered_employers).not_to include(employer_id)
      end
    end
  end
end
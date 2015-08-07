require 'rails_helper'
require 'ruby-debug'

describe Api::V2::QuoteGeneratorController do

  describe "POST generate_quote" do

    let(:request_xml) {
      File.read(Rails.root.join("spec", "data", "coverage_quote_request_type.xml"))
    }

    let(:response_xml) {
      File.read(Rails.root.join("spec", "data", "coverage_quote_response_type.xml"))
    }

    let(:policy) { Policy.new }

    let(:xml_doc) {
      Nokogiri::XML(request_xml)
    }

    context "successful response" do

      it 'should respond with premiums' do
        allow(Nokogiri).to receive(:XML).with(anything()).and_return(xml_doc)
        allow_any_instance_of(QuoteValidator).to receive(:initialize).with(anything()).and_return(double())
        allow_any_instance_of(QuoteValidator).to receive(:check_against_schema)
        allow_any_instance_of(QuoteValidator).to receive(:valid?).and_return(true)
        allow_any_instance_of(Premiums::PolicyCalculator).to receive(:apply_calculations).with(policy).and_return(response_xml)
        allow_any_instance_of(QuoteCvProxy).to receive(:response_xml).and_return(response_xml)
        allow_any_instance_of(QuoteCvProxy).to receive(:invalid?).and_return(false)
        allow_any_instance_of(QuoteCvProxy).to receive(:enrollees_pre_amt=)
        allow_any_instance_of(QuoteCvProxy).to receive(:policy_pre_amt_tot=)

        post :generate, {:format => "xml"}
        expect(response.body).to eq(response_xml)
        expect(response.body).to include("<premium_amount>26.62</premium_amount>")
        expect(response.body).to include("<premium_total_amount>26.62</premium_total_amount>")
        expect(response).to have_http_status(:ok)
      end
    end

    context "failure response" do
      it 'should respond with errors' do
        allow(Nokogiri).to receive(:XML).with("").and_return(xml_doc)
        allow_any_instance_of(Premiums::PolicyCalculator).to receive(:apply_calculations).with(policy).and_return(response_xml)
        allow_any_instance_of(QuoteCvProxy).to receive(:to_xml).and_return(response_xml)
        allow_any_instance_of(QuoteCvProxy).to receive(:enrollees_pre_amt=)
        allow_any_instance_of(QuoteCvProxy).to receive(:policy_pre_amt_tot=)

        post :generate, {:format => "xml"}
        expect(response.body).to include("<errors>")
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

  end
end
require 'rails_helper'

=begin
describe Api::V1::EventsController, :type => :controller do
  describe 'POST create' do
    let(:document) { double }
    let(:body) { "" }
    let(:event_notification) { double( :user_token => user_token ) }
    let(:found_user) { double }

    before(:each) do
      allow(Nokogiri).to receive(:XML).with(body).and_return(document)
      allow(EventNotification).to receive(:new).with(document).and_return(event_notification)
      allow(User).to receive(:find_by_authentication_token).with(user_token).and_return(found_user)
      post :create, {:format => "xml"}
    end

    describe "with no user token" do
      let(:user_token) { nil }

      it "should give unauthorized" do
        expect(response.status).to eql 401
      end
    end

    describe "with an invalid user token" do
      let(:user_token) { "bogus token" }
      let(:found_user) { nil }

      it "should give unauthorized" do
        expect(response.status).to eql 401
      end
    end

    describe "with a valid user token, but invalid event" do
      let(:user_token) { "bogus token" }
      let(:found_user) { User.new(:approved => true) }
      let(:errors) { { "bogus_reason" => "bogus_value" }  }
      let(:event_notification) { double( :user_token => user_token, :save => false, :errors => errors) }

      it "should give invalid entity" do
        expect(response.body).to eql errors.to_xml(:root_element => "errors") 
        expect(response.status).to eql 422
      end
    end

    describe "with a valid user token, and valid event" do
      let(:user_token) { "valid token" }
      let(:found_user) { User.new(:approved => true) }
      let(:event_notification) { double( :user_token => user_token, :save => true) }

      it "should give accepted" do
        expect(response.status).to eql 202
      end
    end
  end
end
=end

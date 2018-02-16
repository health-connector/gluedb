require "rails_helper"
require "cancan/matchers"

describe "User" do
  describe "abilities" do
    subject(:ability) { Ability.new(user)}
    let(:user) { nil }

    context "when is an admin" do
      let(:user) { FactoryGirl.create(:user, :admin)}

      it{ should be_able_to(:manage, :all) }
    end

    context "when is an edi_ops user" do
      let(:user) { FactoryGirl.create(:user, :edi_ops) }

      it{ should be_able_to(:manage, :all) }
      it{ should_not be_able_to(:modify, User)}
    end

    context "when is a user user" do
      let(:user) { FactoryGirl.create(:user) }

      it{ should be_able_to(:read, :all) }
      it{ should be_able_to(:premium_calc, :all)}
      it{ should be_able_to(:manage, Carrier)}
      it{ should should_not be_able_to(:manage, :all)}
    end

    context "when is a service user" do
      let(:user) { FactoryGirl.create(:user, :service) }

      it{ should be_able_to(:read, Person)}
      it{ should be_able_to(:premium_calc, :all)}
      it{ should_not be_able_to(:manage, :all)}
    end
  end
end
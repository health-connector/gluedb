require File.join(Rails.root, "app", "models", "premiums", "quote_cv_proxy.rb")

class Api::V2::QuoteGeneratorController < ApplicationController
  skip_before_filter :authenticate_user_from_token!
  skip_before_filter :authenticate_me!
  protect_from_forgery

  def generate

    begin
      quote_request_xml = request.body.read

      xml_node = Nokogiri::XML(quote_request_xml)

      plan_hash = Parsers::Xml::Cv::PlanParser.parse(xml_node).first.to_hash
      quote_cv_proxy = QuoteCvProxy.new(quote_request_xml)

      enrollees = quote_cv_proxy.enrollees

      plan = quote_cv_proxy.plan

      if quote_cv_proxy.invalid?
        errors = ""
        quote_cv_proxy.errors.each do |attribute, error| errors += "<error>#{attribute} #{error}</error>" end
        raise errors
      end

      policy = Policy.new(plan: plan, enrollees: enrollees)

      premium_calculator = Premiums::PolicyCalculator.new

      premium_calculator.apply_calculations(policy)

      quote_cv_proxy.enrollees_pre_amt=policy.enrollees
      quote_cv_proxy.policy_pre_amt_tot=policy.pre_amt_tot

      render :xml => quote_cv_proxy.to_xml
    rescue Exception => e
      render :xml => "<errors>#{e.message}</errors>"
    end

  end
end
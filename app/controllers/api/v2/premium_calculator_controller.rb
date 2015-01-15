require File.join(Rails.root, "app", "models", "premiums", "enrollment_cv_proxy.rb")

class Api::V2::PremiumCalculatorController < ApplicationController
  skip_before_filter :authenticate_user_from_token!
  skip_before_filter :authenticate_me!
  protect_from_forgery :except => [:create]


  def calculate

    enrollment_xml = request.body.read

    enrollment_validator = EnrollmentValidator.new(enrollment_xml)
    enrollment_validator.check_against_schema

    if !enrollment_validator.valid?
      render :xml => enrollment_validator.errors.to_xml, :status => :unprocessable_entity
      return
    end

    enrollment_cv_proxy = EnrollmentCvProxy.new(enrollment_xml)
    policy = enrollment_cv_proxy.policy

    uri_dereference_requestor = Amqp::UriDereferenceRequestor.default
    properties = {:routing_key => "uri.resolve", :reference_uri => policy.employer_id_uri}
    delivery_info, properties, payload = uri_dereference_requestor.request(properties, "")

    if delivery_info[:status] != "200"
      render :xml => "<errors><error>Failed to deference employer id #{policy.employer_id_uri}</error></errors>", :status => :unprocessable_entity
      return
    end

    policy.employer_id= properties[:headers][:uri]

    premium_calculator = Premiums::PolicyCalculator.new

    premium_calculator.apply_calculations(policy)

    enrollment_cv_proxy.policy_emp_res_amt = policy.tot_emp_res_amt
    enrollment_cv_proxy.policy_tot_res_amt = policy.tot_res_amt
    enrollment_cv_proxy.policy_pre_amt_tot = policy.pre_amt_tot

    enrollment_cv_proxy.enrollees_pre_amt=(policy.enrollees)

    #policy.enrollees.each do |enrollee|
    #end

    render :xml => enrollment_cv_proxy.to_xml
  end

end
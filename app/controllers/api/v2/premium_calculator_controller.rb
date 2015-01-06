require File.join(Rails.root, "app", "models", "premiums", "enrollment_cv_proxy.rb")

class Api::V2::PremiumCalculatorController < ApplicationController
  skip_before_filter :authenticate_user_from_token!
  skip_before_filter :authenticate_me!
  protect_from_forgery :except => [:create]


  def calculate


    enrollment_xml = request.body.read

    enrollment_cv_proxy = EnrollmentCvProxy.new(enrollment_xml)

    policy = enrollment_cv_proxy.policy

    premium_calculator = Premiums::PolicyCalculator.new

    premium_calculator.apply_calculations(policy)

    enrollment_cv_proxy.policy_emp_res_amt = policy.tot_emp_res_amt
    enrollment_cv_proxy.policy_tot_res_amt = policy.tot_res_amt
    enrollment_cv_proxy.policy_pre_amt_tot = policy.pre_amt_tot

    policy.enrollees.each do |enrollee|
      enrollment_cv_proxy.enrollee_pre_amt=(enrollee)
    end

    render :text => enrollment_cv_proxy.to_xml
  end

end
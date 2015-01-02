class Api::V2::PremiumCalculatorController < ApplicationController



  def calculate


    enrollment_xml = request.body.read

    policy_parser = Parsers::Xml::Cv::PolicyParser.parse(enrollment_xml)

    @policy = PolicyBuilder.new(policy_parser.first.to_hash).policy

    @old_policy = @policy.clone

    premium_calculator = Premiums::PolicyCalculator.new

    premium_calculator.apply_calculations(@policy)

    logger.info "#{@old_policy.inspect}"
    logger.info "#{@policy.inspect}"
    render xml: @policy, layout: false
  end

end
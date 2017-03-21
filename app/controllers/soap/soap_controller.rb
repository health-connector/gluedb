class Soap::SoapController < ApplicationController
#  skip_before_filter :authenticate_user_from_token!
#  skip_before_filter :authenticate_me!
  SOAP_NS = {
    :soap => 'http://www.w3.org/2001/12/soap-envelope',
    :cv_soap => 'http://openhbx.org/api/transports/soap/1.0'
  }
  protect_from_forgery :except => [:wsdl]

  @@logger = Logger.new("#{Rails.root}/log/soap.log")

  def get_user_token(xml_body)
    node = (xml_body.xpath("//user_token", SOAP_NS) | xml_body.xpath("//cv_soap:user_token", SOAP_NS)) .first
    MayBlank.new(node).text.value
  end

  def get_soap_body
    Nokogiri::XML(request.body.read)
  end

  def wsdl
    render action: 'wsdl', :content_type => "text/xml", :formats => [:xml]
  end

  def fail_authentication(user_token)
    user = user_token && User.find_by_authentication_token(user_token.to_s)

    if user
      sign_in user, store: false
      return false
    end
    true
  end
end

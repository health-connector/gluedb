class Soap::FamiliesController < Soap::SoapController

  def get_by_family_id
    in_req = get_soap_body

    @@logger.info "#{DateTime.now.to_s} class:#{self.class.name} method:#{__method__.to_s} in_req:#{in_req.to_s}"

    user_token = get_user_token(in_req)

    if fail_authentication(user_token)
      render :status => 401, :nothing => true
      return
    end
    family_id = get_family_id(in_req)
    if family_id.blank?
      render :status => 422, :nothing => true
      return
    end

    @groups = Family.find([family_id])

    @@logger.info "#{DateTime.now.to_s} class:#{self.class.name} method:#{__method__.to_s} group:#{@groups.inspect}"


    render 'get_by_family_id', :content_type => "text/xml"
  end

  private

  def get_family_id(xml_body)
    node = (xml_body.xpath("//application_group_id", SOAP_NS) | xml_body.xpath("//cv_soap:get_application_group_id", SOAP_NS)).first

    MayBlank.new(node).text.value
  end

end
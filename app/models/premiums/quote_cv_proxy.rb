require Rails.root.join "app", "models", "premiums", "enrollment_cv_proxy.rb"

class QuoteCvProxy < EnrollmentCvProxy
  include ActiveModel::Validations

  validates_presence_of :enrollees
  validates_presence_of :plan
  validate :presence_of_essential_data

  def policy_pre_amt_tot=(value)
    premium_total_amount_node = Nokogiri::XML::Node.new "premium_total_amount", @xml_doc
    premium_total_amount_node.content = value

    enrollment_node = @xml_doc.xpath('//ns1:enrollment', NAMESPACES).first
    enrollment_node.add_child(premium_total_amount_node)
  end

  def enrollees_pre_amt=(enrollees)
    enrollees_node = @xml_doc.xpath('//ns1:enrollee', NAMESPACES)

    enrollees_and_nodes = enrollees_node.zip enrollees

    enrollees_and_nodes.each do |enrollee_node, enrollee|
      #@xml_doc.xpath('//ns1:enrollee/ns1:benefit/ns1:premium_amount', NAMESPACES).first.content = enrollee.premium_amount
      premium_amount_node = Nokogiri::XML::Node.new "premium_amount", @xml_doc
      premium_amount_node.content =  enrollee.premium_amount

      benefits_node = enrollee_node.xpath('ns1:benefit', NAMESPACES).first
      benefits_node.add_child(premium_amount_node)
    end
  end

  def presence_of_essential_data

  end

end
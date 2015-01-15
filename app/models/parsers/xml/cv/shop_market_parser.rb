module Parsers::Xml::Cv

  class ShopMarketParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'shop_market'
    namespace 'cv'

    element :total_employer_responsible_amount, String, tag: "total_employer_responsible_amount"
    has_one :employer_link, Parsers::Xml::Cv::EmployerLinkParser, tag: "employer_link"

    def to_hash
      {
          total_employer_responsible_amount:total_employer_responsible_amount,
          employer_link:employer_link.to_hash
      }
    end

  end
end
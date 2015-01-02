module Parsers::Xml::Cv
  class EnrollmentParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'enrollment'
    namespace 'cv'

    element :premium_amount_total, String, tag: "premium_amount_total"
    element :total_responsible_amount, String, tag: "total_responsible_amount"
    has_one :plan, Parsers::Xml::Cv::PlanParser, tag:'plan'
    has_one :shop_market, Parsers::Xml::Cv::ShopMarketParser, tag:'shop_market'

    def to_hash
      {
          premium_total_amount:premium_amount_total,
          total_responsible_amount:total_responsible_amount,
          plan: plan.to_hash,
          shop_market:shop_market.to_hash
      }
    end
  end
end
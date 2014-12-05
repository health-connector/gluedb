module Parsers::Xml::Cv
  class Renewal
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'renewal'
    namespace 'cv'

    has_one :current_policy, Parsers::Xml::Cv::Policy, tag:'current_policy/cv:policy'
    has_one :renewal_policy, Parsers::Xml::Cv::Policy, tag:'renewal_policy/cv:policy'
  end
end
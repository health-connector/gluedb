module Parsers::Xml::Cv

  class EnrolleeParser
    include HappyMapper

    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'enrollee'
    namespace 'cv'

    element :is_subscriber, String, tag: "is_subscriber"
    has_one :member, Parsers::Xml::Cv::EnrolleeMemberParser, tag: 'member'

    def to_hash
      {
          is_subscriber:is_subscriber,
          member:member.to_hash
      }
    end

  end
end
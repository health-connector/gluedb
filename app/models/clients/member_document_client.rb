module Clients
  class MemberDocumentClient
    def self.call(authority_member)
      if authority_member.blank?
        return []
      end
      req = Amqp::Requestor.default
      di, rprops, rbody = req.request({
        :routing_key => "member_documents.find_by_hbx_member_id",
        :headers => {
          :hbx_member_id => authority_member.hbx_member_id
        }
      }, "")
      dlr = Parsers::DocumentListResponse.parse(rbody)
      return [] if dlr.document.blank?
      dlr.document
    end
  end
end

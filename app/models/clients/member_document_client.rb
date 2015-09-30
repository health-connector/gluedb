module Clients
  class MemberDocumentClient
    def self.call(authority_member)
      begin
      if authority_member.blank?
        return []
      end
      conn = Bunny.new(ExchangeInformation.amqp_uri, :heartbeat => 10)
      begin
        conn.start
        req = Amqp::Requestor.new(conn)
        di, rprops, rbody = req.request({
          :routing_key => "member_documents.find_by_hbx_member_id",
          :headers => {
            :hbx_member_id => authority_member.hbx_member_id
          }
        }, "", 2)
        dlr = Parsers::DocumentListResponse.parse(rbody)
        return [] if dlr.document.blank?
        dlr.document
      ensure
        conn.close
      end
      rescue Bunny::TCPConnectionFailed => e
        []
      rescue Timeout::Error => e
        []
      end
    end
  end
end

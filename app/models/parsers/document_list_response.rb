module Parsers
  class DocumentListResponse
    include HappyMapper
    register_namespace "cv", "http://openhbx.org/api/terms/1.0"
    tag 'document_list'
    namespace 'cv'

    has_many :document, Parsers::DocumentListItem

    def self.from_documents(docs)
      gen_doc = Parsers::DocumentListResponse.new
      dlis = []
      docs.each do |doc|
        dli = Parsers::DocumentListItem.new
        dli.document_id = doc.document_id
        dli.document_kind = doc.document_kind
        dli.document_name = doc.document_name
        dlis << dli
      end
      gen_doc.document = dlis
      gen_doc
    end
  end
end

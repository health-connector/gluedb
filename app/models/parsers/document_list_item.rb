module Parsers
  class DocumentListItem
        include HappyMapper

        register_namespace "cv", "http://openhbx.org/api/terms/1.0"
        tag 'document'
        namespace "cv"

        element :document_id, String, :tag => "document_id"
        element :document_name, String, :tag => "document_name"
        element :document_kind, String, :tag => "document_kind"
  end
end

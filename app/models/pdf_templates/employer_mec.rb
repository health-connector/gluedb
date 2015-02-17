module PdfTemplates
  class EmployerMec
    include Virtus.model

    attribute :ein, String
    attribute :business_name, String
    attribute :business_address, PdfTemplates::NoticeAddress
    attribute :mec_status_ind, String
  end
end
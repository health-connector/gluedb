module TradingPartnerTransforms
  # Transforms uploaded enrollment event XML into X12 and CV1 payloads.
  # Does not look up policies.
  class UploadedXmlTransformer
    include BatchEdiTransform

    SOURCE_DIR = "source_xmls".freeze
    X12_DIR = "transformed_x12s".freeze
    CV1_DIR = "transformed_cv1s".freeze

    attr_reader :errors

    # source_files is an array of [file_name, xml_string] pairs.
    def initialize(source_files)
      @source_files = source_files
      @errors = []
    end

    # Returns the zip path. The caller deletes the file. The zip includes the
    # uploaded source XML in the same layout as PackageBuilder.
    def build
      source_files = @source_files.map { |name, xml| [File.join(SOURCE_DIR, File.basename(name)), xml] }
      x12_files = transform_source_files(@source_files, EdiCodec::X12::BenefitEnrollment, X12_DIR, @errors)
      cv1_files = transform_source_files(@source_files, EdiCodec::Cv1::Cv1Builder, CV1_DIR, @errors)
      ZipPackager.build(source_files + x12_files + cv1_files, @errors)
    end
  end
end

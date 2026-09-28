module TradingPartnerTransforms
  # Shared step for turning a batch of enrollment event XML strings into
  # X12 or CV1 payloads with EdiFileTransformer. Used both when the source
  # XML was just generated from a policy, and when it was uploaded directly.
  # Failures on one file are recorded in errors and do not stop the batch.
  module BatchEdiTransform
    def transform_source_files(source_files, builder_class, dir_name, errors)
      transformer = EdiFileTransformer.new(builder_class)
      source_files.inject([]) do |acc, (source_name, source_xml)|
        begin
          result = transformer.transform(source_xml)
          if result
            acc << [File.join(dir_name, result.first), result.last]
          else
            errors << "#{File.basename(source_name)} - event is not publishable, no #{dir_name} output"
          end
        rescue StandardError => e
          errors << "#{File.basename(source_name)} - #{dir_name} transform failed: #{e.message}"
        end
        acc
      end
    end
  end
end

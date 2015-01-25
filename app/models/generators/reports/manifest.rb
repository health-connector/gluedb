module Generators::Reports  
  class Manifest

    NS = {
      "xmlns:ns2" => "http://hix.cms.gov/0.1/hix-core", 
      "xmlns:ns1" => "http://niem.gov/niem/structures/2.0", 
      "xmlns:ns4" => "http://birsrep.dsh.cms.gov/extension/1.0",
      "xmlns:ns3" => "http://niem.gov/niem/niem-core/2.0",
      "xmlns:ns5" => "http://birsrep.dsh.cms.gov/exchange/1.0"
    }


    def create(folder)
      @folder = folder
      @manifest = OpenStruct.new({
        file_count: Dir.glob(@folder+'/*.xml').count,
      })
      manifest_xml = serialize.to_xml(:indent => 2)
      File.open("#{folder}/manifest.xml", 'w') do |file|
        file.write manifest_xml
      end
    end

    def serialize
      Nokogiri::XML::Builder.new { |xml|
        xml['ns5'].BatchHandlingServiceRequest(NS) do |xml|
          serialize_batch_data(xml)
          serialize_transmission_data(xml)
          serialize_service_data(xml)
          attachments.each do |attachment|
            serialize_attachment(xml, attachment)
          end
        end
      }
    end

    def attachments
      Dir.glob(@folder+'/*.xml').inject([]) do |data, file|
        data << OpenStruct.new({
          checksum: Digest::MD5.file(file).hexdigest,
          binarysize: File.size(file),
          filename: File.basename(file),
          sequence_id: File.basename(file).match(/^\d+/)[0]
        })
      end
    end

    def serialize_batch_data(xml)
      xml['ns2'].BatchMetadata do |xml|
        xml.BatchID '2014-10-06T09:00:00Z'
        xml.BatchPartnerID '02.DC*.SBE.001.001'
        xml.BatchAttachmentTotalQuantity @manifest.file_count
        xml['ns4'].BatchCategoryCode 'IRS_EOY_IND_REQ'
        xml.BatchTransmissionQuantity @manifest.file_count
      end
    end

    def serialize_transmission_data(xml)
      xml['ns2'].TransmissionMetadata do |xml|
        xml.TransmissionAttachmentQuantity @manifest.file_count
        xml.TransmissionSequenceID 1
      end
    end

    def serialize_service_data(xml)
      xml['ns4'].ServiceSpecificData do |xml|
        xml.ReportPeriod do |xml|
          xml['ns3'].YearMonth '2014-01'
        end
      end
    end

    def serialize_attachment(xml, file)
      xml['ns4'].Attachment do |xml|
        xml['ns3'].DocumentBinary do |xml|
          xml['ns2'].ChecksumAugmentation do |xml|
            xml.MD5ChecksumText file.checksum
          end
          xml['ns2'].BinarySizeValue file.binarysize
        end
        xml['ns3'].DocumentFileName file.filename
        xml['ns3'].DocumentSequenceID file.sequence_id
      end
    end
  end
end
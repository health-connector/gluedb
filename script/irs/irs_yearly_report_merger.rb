require 'nokogiri'

module Irs
  class IrsYearlyReportMerger

    attr_reader :consolidated_doc
    attr_reader :xml_docs

    XMLNS = {
        "air5.0" => "urn:us:gov:treasury:irs:ext:aca:air:5.0",
        "irs" => "urn:us:gov:treasury:irs:common",
        "batchreq" => "urn:us:gov:treasury:irs:msg:form1095atransmissionupstreammessage",
        "batchresp" => "urn:us:gov:treasury:irs:msg:form1095atransmissionexchrespmessage",
        "reqack" => "urn:us:gov:treasury:irs:msg:form1095atransmissionexchackngmessage",
        "xsi" => "http://www.w3.org/2001/XMLSchema-instance"
    }

    def initialize(dir)
      @dir = dir
      @output_file_name = 'merged.xml'
      @xml_docs = []
      @consolidated_doc = nil
    end

    def process
      read
      merge
      write
      sanity_check
    end

    def sanity_check
      XmlValidator.validate(File.join(@dir, '..', @output_file_name))
      xml_doc = Nokogiri::XML(File.open(File.join(@dir, '..', @output_file_name)))
      element_count = xml_doc.xpath('//batchreq:Form1095ATransmissionUpstream/air5.0:Form1095AUpstreamDetail', XMLNS).count
      "file count #{@xml_docs.count} elements count #{element_count}"
    end

    def self.total_records_in_transmission(folder)
      @dir = "#{Rails.root}/#{folder}"
      Dir.glob(@dir+'/*.xml').inject([]) do |data, filepath|
        puts "------validating #{filepath}"
        XmlValidator.validate(filepath)
        xml_doc = Nokogiri::XML(File.open(filepath))
        data << xml_doc.xpath('//batchreq:Form1095ATransmissionUpstream/air5.0:Form1095AUpstreamDetail', XMLNS).count
      end
    end

    def read
      Dir.glob(@dir+'/*.xml').each do |file_path|
        @xml_docs << Nokogiri::XML(File.open(file_path))
      end
      @xml_docs
    end

    def merge
      puts @xml_docs.count
      if @consolidated_doc == nil
        xml_doc = @xml_docs[0]
        xml_doc = chop_special_characters(xml_doc)
        @consolidated_doc = xml_doc
      end
      @xml_docs.shift
      @consolidated_doc.xpath('//batchreq:Form1095ATransmissionUpstream', XMLNS).each do |node|
        @xml_docs.each do |xml_doc|
          new_node = xml_doc.xpath('//batchreq:Form1095ATransmissionUpstream/air5.0:Form1095AUpstreamDetail', XMLNS).first
          new_node = chop_special_characters(new_node)
          node.add_child(new_node)
        end
      end
      @consolidated_doc
    end

    def chop_special_characters(node)
      node.xpath("//irs:SSN", XMLNS).each do |ssn_node|
        update_ssn = Maybe.new(ssn_node.content).strip.gsub("-","").value
        ssn_node.content = update_ssn
      end

      ["PersonFirstName", "PersonMiddleName", "PersonLastName", "AddressLine1Txt", "AddressLine2Txt", "CityNm"].each do |ele|
        node.xpath("//irs:#{ele}", XMLNS).each do |xml_tag|
          update_ele = Maybe.new(xml_tag.content).strip.gsub(/(\-{2}|\'|\#|\"|\&|\<|\>)/,"").value
          if xml_tag.content.match(/(\-{2}|\'|\#|\"|\&|\<|\>)/)
            puts xml_tag.content.inspect
            puts update_ele
          end
          xml_tag.content = update_ele
        end
      end

      node.xpath("//air5.0:RecordSequenceNum", XMLNS).each do |number|
        integer_val = Maybe.new(number.content).strip.value.to_i
        number.content = integer_val
      end

      node
    end

    def write
      output_file_path = File.join(@dir, '..', @output_file_name)
      File.open(output_file_path, 'w+') { |file| file.write(@consolidated_doc.to_xml) }
    end
  end
end
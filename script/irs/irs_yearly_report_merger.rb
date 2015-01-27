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

    def read
      Dir.foreach(@dir) do |file_name|
        next if file_name == '.' or file_name == '..' or file_name == @output_file_name
        next unless file_name.split('.').last.eql?'xml'

        file_path = File.join(@dir, file_name)
        xml = File.open(file_path)
        @xml_docs << Nokogiri::XML(xml)
      end
      @xml_docs
    end

    def merge
      if @consolidated_doc == nil
        @consolidated_doc = @xml_docs[0]
      end

      @xml_docs.shift

      @xml_docs.each do |xml_doc|
        @consolidated_doc.xpath('//batchreq:Form1095ATransmissionUpstream', XMLNS).each do |node|
          new_node = xml_doc.xpath('//batchreq:Form1095ATransmissionUpstream/air5.0:Form1095AUpstreamDetail', XMLNS).first
          node.add_child(new_node)
        end
      end

      @consolidated_doc
    end

    def write
      output_file_path = File.join(@dir, @output_file_name)

      File.open(output_file_path, 'w+') { |file| file.write(@consolidated_doc.to_xml) }

    end
  end
end
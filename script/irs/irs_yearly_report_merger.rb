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
      xml_doc = Nokogiri::XML(File.open("#{@dir}/#{@output_file_name}"))
      elements = xml_doc.xpath('//batchreq:Form1095ATransmissionUpstream/air5.0:Form1095AUpstreamDetail', XMLNS).count
      puts "----total docs in folder #{@xml_docs.count}"
      puts "----total docs in merge xml #{elements}"
    end

    def self.count_reports_in_directory
      @dir = "#{Rails.root}/irs_h41/FEP0020DC.DSH.EOYIN.D150127.T180947000.P.IN"
      Dir.glob(@dir+'/*.xml').each do |filepath|
        xml_doc = Nokogiri::XML(File.open(filepath))
        elements = xml_doc.xpath('//batchreq:Form1095ATransmissionUpstream/air5.0:Form1095AUpstreamDetail', XMLNS).count
        puts "----total docs in merge xml #{elements}"
      end
    end

    def read
      Dir.glob(@dir+'/*.xml').each do |file_path|
        @xml_docs << Nokogiri::XML(File.open(file_path))
      end
      @xml_docs
    end

    def merge
      if @consolidated_doc == nil
        xml_doc = @xml_docs[0]
        xml_doc.xpath("//irs:SSN", XMLNS).each do |ssn_node|
          update_ssn = Maybe.new(ssn_node.content).strip.gsub("-","").value
          puts update_ssn.inspect
          ssn_node.content = update_ssn
        end
        @consolidated_doc = xml_doc
      end

      @xml_docs.shift
      
      @consolidated_doc.xpath('//batchreq:Form1095ATransmissionUpstream', XMLNS).each do |node|
        @xml_docs.each do |xml_doc|
          new_node = xml_doc.xpath('//batchreq:Form1095ATransmissionUpstream/air5.0:Form1095AUpstreamDetail', XMLNS).first
          new_node.xpath("//irs:SSN", XMLNS).each do |ssn_node|
            update_ssn = Maybe.new(ssn_node.content).strip.gsub("-","").value
            puts update_ssn.inspect
            ssn_node.content = update_ssn
          end
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
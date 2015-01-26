require 'rails_helper'
require Rails.root.join('script', 'irs', 'irs_yearly_report_merger')
require 'nokogiri'

describe Irs::IrsYearlyReportMerger do

  before(:all) do
    @dir = "/Users/CitadelFirm/Downloads/projects/hbx/irs_xmls"
    @irs_yearly_report_merger = Irs::IrsYearlyReportMerger.new(@dir)
    @xml_docs = @irs_yearly_report_merger.read
  end

  it 'should reads xmls in directory and convert to nokogiri docs' do
    expect(@xml_docs.length).to eq(2)
    expect(@xml_docs[0].class.name).to eq('Nokogiri::XML::Document')
  end

  it 'should merge docs into a valid xml' do
    expect(@irs_yearly_report_merger.merge.class.name).to eq('Nokogiri::XML::Document')
  end

  it 'writes the output file' do
    @irs_yearly_report_merger.write
    output_file = File.open(File.join(@dir, 'merged.xml'))
    expect(output_file.nil?).to be_false
  end
end
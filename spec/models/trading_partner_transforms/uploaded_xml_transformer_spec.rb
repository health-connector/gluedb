require 'rails_helper'

describe TradingPartnerTransforms::UploadedXmlTransformer, :dbclean => :after_each do
  include TradingPartnerTransformsSpecHelpers

  let(:carrier) { FactoryGirl.create(:carrier, :hbx_carrier_id => "20002", :abbrev => "BCBS") }
  let(:plan) { FactoryGirl.create(:plan, :carrier => carrier, :year => 2026, :coverage_type => "health") }
  let(:policy) { FactoryGirl.create(:shop_policy, :plan => plan, :composite_rating_tier => "urn:openhbx:terms:v1:composite_rating_tier#employee_only").tap { |p| bridge_person_for(p) } }
  let(:real_xml) { TradingPartnerTransforms::SourceXmlGenerator.new(policy, "initial").generate }

  def entries_for(zip_path)
    entries = {}
    ::Zip::File.open(zip_path) do |zip|
      zip.each { |entry| entries[entry.name] = entry.get_input_stream.read }
    end
    entries
  end

  describe "#build with one real uploaded xml file" do
    subject { described_class.new([["dep_add_source.xml", real_xml]]) }

    it "echoes the source back and produces x12 and cv1 with no errors" do
      zip_path = subject.build
      begin
        entries = entries_for(zip_path)
        expect(entries["source_xmls/dep_add_source.xml"]).to eq real_xml
        expect(entries.keys.any? { |k| k.start_with?("transformed_x12s/") }).to be_truthy
        expect(entries.keys.any? { |k| k.start_with?("transformed_cv1s/") }).to be_truthy
        expect(entries).not_to have_key("errors.txt")
        expect(subject.errors).to be_empty
      ensure
        FileUtils.rm_f(zip_path)
      end
    end
  end

  describe "#build with a nested path in the uploaded file name" do
    subject { described_class.new([["source_xmls/#{policy.eg_id}_initial.xml", real_xml]]) }

    it "flattens the source entry to just the file's basename" do
      zip_path = subject.build
      begin
        entries = entries_for(zip_path)
        expect(entries.keys).to include("source_xmls/#{policy.eg_id}_initial.xml")
        expect(entries.keys).not_to include("source_xmls/source_xmls/#{policy.eg_id}_initial.xml")
      ensure
        FileUtils.rm_f(zip_path)
      end
    end
  end

  describe "#build with more than one real uploaded xml file" do
    let(:other_policy) { FactoryGirl.create(:shop_policy, :plan => plan, :composite_rating_tier => "urn:openhbx:terms:v1:composite_rating_tier#employee_only").tap { |p| bridge_person_for(p) } }
    let(:other_xml) { TradingPartnerTransforms::SourceXmlGenerator.new(other_policy, "initial").generate }
    subject { described_class.new([["a.xml", real_xml], ["b.xml", other_xml]]) }

    it "transforms every uploaded file" do
      zip_path = subject.build
      begin
        entries = entries_for(zip_path)
        expect(entries.keys.count { |k| k.start_with?("source_xmls/") }).to eq 2
        expect(entries.keys.count { |k| k.start_with?("transformed_x12s/") }).to eq 2
        expect(entries.keys.count { |k| k.start_with?("transformed_cv1s/") }).to eq 2
      ensure
        FileUtils.rm_f(zip_path)
      end
    end
  end

  describe "#build with a mix of a real file and garbage xml" do
    subject { described_class.new([["good.xml", real_xml], ["bad.xml", "not xml at all"]]) }

    it "still echoes both source files, transforms the good one, and records the bad one as an error" do
      zip_path = subject.build
      begin
        entries = entries_for(zip_path)
        expect(entries.keys).to include("source_xmls/good.xml")
        expect(entries.keys).to include("source_xmls/bad.xml")
        expect(entries.keys.count { |k| k.start_with?("transformed_x12s/") }).to eq 1
        expect(entries["errors.txt"]).to include("bad.xml")
        expect(subject.errors.size).to eq 2
      ensure
        FileUtils.rm_f(zip_path)
      end
    end
  end
end

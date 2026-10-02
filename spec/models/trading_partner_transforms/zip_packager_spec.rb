require 'rails_helper'

describe TradingPartnerTransforms::ZipPackager do

  def entries_for(zip_path)
    entries = {}
    ::Zip::File.open(zip_path) do |zip|
      zip.each { |entry| entries[entry.name] = entry.get_input_stream.read }
    end
    entries
  end

  describe ".build" do
    describe "with no errors" do
      let(:file_pairs) { [["source_xmls/a.xml", "<a/>"], ["transformed_x12s/b.xml", "<b/>"]] }

      it "writes every file pair into the zip" do
        zip_path = described_class.build(file_pairs)
        begin
          entries = entries_for(zip_path)
          expect(entries["source_xmls/a.xml"]).to eq "<a/>"
          expect(entries["transformed_x12s/b.xml"]).to eq "<b/>"
        ensure
          FileUtils.rm_f(zip_path)
        end
      end

      it "does not add an errors.txt entry" do
        zip_path = described_class.build(file_pairs)
        begin
          expect(entries_for(zip_path)).not_to have_key("errors.txt")
        ensure
          FileUtils.rm_f(zip_path)
        end
      end

      it "returns a path to a file that actually exists" do
        zip_path = described_class.build(file_pairs)
        begin
          expect(File.exist?(zip_path)).to be_truthy
        ensure
          FileUtils.rm_f(zip_path)
        end
      end
    end

    describe "with errors" do
      let(:file_pairs) { [["source_xmls/a.xml", "<a/>"]] }
      let(:errors) { ["a.xml - transform failed", "b.xml - transform failed"] }

      it "adds an errors.txt entry joining every error with a newline" do
        zip_path = described_class.build(file_pairs, errors)
        begin
          entries = entries_for(zip_path)
          expect(entries["errors.txt"]).to eq "a.xml - transform failed\nb.xml - transform failed"
        ensure
          FileUtils.rm_f(zip_path)
        end
      end

      it "still writes the successful file pairs" do
        zip_path = described_class.build(file_pairs, errors)
        begin
          expect(entries_for(zip_path)["source_xmls/a.xml"]).to eq "<a/>"
        ensure
          FileUtils.rm_f(zip_path)
        end
      end
    end

    describe "with no file pairs and no errors" do
      it "still returns a valid, openable zip" do
        zip_path = described_class.build([])
        begin
          expect(entries_for(zip_path)).to eq({})
        ensure
          FileUtils.rm_f(zip_path)
        end
      end
    end
  end
end

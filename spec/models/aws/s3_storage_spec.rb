require 'rails_helper'

describe Aws::S3Storage do

  let(:subject) { allow_any_instance_of(Aws::S3Storage).to receive(:setup); Aws::S3Storage.new }
  let(:aws_env) { ENV['AWS_ENV'] || "local" }
  let(:object) { double }
  let(:bucket_name) { "bucket1" }
  let(:file_path) { File.dirname(__FILE__) }
  let(:key) { SecureRandom.uuid }
  let(:uri) { "urn:openhbx:terms:v1:file_storage:s3:bucket:#{Settings.abbrev}-gluedb-#{bucket_name}-#{aws_env}##{key}" }
  let(:invalid_url) { "urn:openhbx:terms:v1:file_storage:s3:bucket:" }
  let(:file_content) { "test content" }

  describe "save()" do
    context "successful upload with explicit key" do
      it 'return the URI of saved file' do
        allow(object).to receive(:upload_file).with(file_path, :server_side_encryption => 'AES256').and_return(true)
        allow_any_instance_of(Aws::S3Storage).to receive(:get_object).and_return(object)
        expect(subject.save({ file_path: file_path, bucket_name: bucket_name, key: key })).to eq(uri)
      end
    end

    context "successful upload without explicit key" do
      it 'return the URI of saved file' do
        allow(object).to receive(:upload_file).with(file_path, :server_side_encryption => 'AES256').and_return(true)
        allow_any_instance_of(Aws::S3Storage).to receive(:get_object).and_return(object)
        expect(subject.save(file_path: file_path, bucket_name: bucket_name)).to include("urn:openhbx:terms:v1:file_storage:s3:bucket:")
      end
    end

    context "successful upload for an internal artifact" do
      it "returns the URI of a saved file" do
        allow(object).to receive(:upload_file).with(file_path, :server_side_encryption => 'AES256').and_return(true)
        allow_any_instance_of(Aws::S3Storage).to receive(:get_object).and_return(object)
        expect(subject.save(file_path: file_path, bucket_name: bucket_name, options: { internal_artifact: true })).to include("aca-internal-artifact-transport")
      end
    end
    context "failed upload" do
      it 'returns nil' do
        allow(object).to receive(:upload_file).with(file_path, :server_side_encryption => 'AES256').and_return(nil)
        allow_any_instance_of(Aws::S3Storage).to receive(:get_object).and_return(object)
        expect(subject.save(file_path: file_path, bucket_name: bucket_name)).to be_nil
      end
    end

    context "failed upload with exception" do
      let(:exception) {StandardError.new}

      it 'raises exception' do
        allow(object).to receive(:upload_file).with(file_path, :server_side_encryption => 'AES256').and_raise(exception)
        allow_any_instance_of(Aws::S3Storage).to receive(:get_object).and_return(object)
        expect { subject.save(file_path: file_path, bucket_name: bucket_name) }.to raise_error(exception)
      end
    end

  end

  describe "find()" do
    context "success" do
      it "returns the file contents" do
        allow_any_instance_of(Aws::S3Storage).to receive(:get_object).and_return(object)
        allow_any_instance_of(Aws::S3Storage).to receive(:read_object).with(object).and_return(file_content)
        expect(subject.find(uri)).to eq(file_content)
      end
    end

    context "failure (invalid uri)" do
      it "returns nil" do
        allow_any_instance_of(Aws::S3Storage).to receive(:get_object).and_raise(Exception)
        expect(subject.find(invalid_url)).to be_nil
      end
    end
  end
end

class TradingPartnerTransformsController < ApplicationController
  before_filter :ensure_feature_enabled
  load_and_authorize_resource :class => "VocabUpload"

  # eg_ids can be passed in the query string to pre-fill the form.
  def new
    @transform_request = TradingPartnerTransformRequest.new(:eg_ids => params[:eg_ids])
  end

  # Downloads source XML, X12 and CV1 for the policies. Does not change policy data.
  def create
    @transform_request = TradingPartnerTransformRequest.new(params[:trading_partner_transform_request])

    unless @transform_request.valid?(:generate)
      @transform_request.errors.full_messages.each { |message| flash_message_now(:error, message) }
      render :new
      return
    end

    package_builder = TradingPartnerTransforms::PackageBuilder.new(
      @transform_request.policies,
      @transform_request.transform_reason_code
    )
    zip_path = package_builder.build

    begin
      send_data File.read(zip_path), :filename => @transform_request.zip_file_name, :type => "application/zip", :disposition => "attachment"
    ensure
      FileUtils.rm_f(zip_path)
    end
  end

  # Downloads the source XML only, without the X12 and CV1 step.
  def generate_source_only
    @transform_request = TradingPartnerTransformRequest.new(params[:trading_partner_transform_request])

    unless @transform_request.valid?(:generate)
      @transform_request.errors.full_messages.each { |message| flash_message_now(:error, message) }
      render :new
      return
    end

    package_builder = TradingPartnerTransforms::PackageBuilder.new(
      @transform_request.policies,
      @transform_request.transform_reason_code,
      :source_only => true
    )
    zip_path = package_builder.build

    begin
      send_data File.read(zip_path), :filename => @transform_request.source_zip_file_name, :type => "application/zip", :disposition => "attachment"
    ensure
      FileUtils.rm_f(zip_path)
    end
  end

  # Builds X12 and CV1 from uploaded source XML files. Accepts only .xml
  # files and does not look up policies.
  def transform_uploaded_xmls
    @transform_request = TradingPartnerTransformRequest.new(params[:trading_partner_transform_request])
    uploads = Array(params[:source_xml_files]).reject(&:blank?)

    if uploads.empty?
      flash_message_now(:error, "Choose one or more .xml source XML files to upload")
      render :new
      return
    end

    non_xml = uploads.reject { |upload| upload.original_filename.to_s.downcase.end_with?(".xml") }
    if non_xml.any?
      flash_message_now(:error, "Only .xml files are accepted: #{non_xml.map(&:original_filename).join(', ')}")
      render :new
      return
    end

    source_files = uploads.map { |upload| [upload.original_filename, upload.read] }
    transformer = TradingPartnerTransforms::UploadedXmlTransformer.new(source_files)
    zip_path = transformer.build

    begin
      send_data File.read(zip_path), :filename => uploaded_transform_zip_file_name(uploads), :type => "application/zip", :disposition => "attachment"
    ensure
      FileUtils.rm_f(zip_path)
    end
  end

  # Updates policy data once the user confirms the preview. Does not produce a zip.
  def apply_data_changes
    @transform_request = TradingPartnerTransformRequest.new(params[:trading_partner_transform_request])

    unless @transform_request.valid?(:apply_changes)
      @transform_request.errors.full_messages.each { |message| flash_message_now(:error, message) }
      render :new
      return
    end

    if params[:confirmed] != "true"
      render :confirm
      return
    end

    applier = TradingPartnerTransforms::EndDateApplier.new(@transform_request, current_user.email)
    applier.apply!
    flash_message(:success, "Data changes applied for eg_ids: #{applier.applied_eg_ids.join(', ')}") if applier.applied_eg_ids.any?
    applier.failures.each do |eg_id, message|
      flash_message(:error, "Data changes failed for eg_id #{eg_id}, it was not changed: #{message}")
    end
    redirect_to new_trading_partner_transform_path(:eg_ids => @transform_request.eg_ids)
  end

  private

  def ensure_feature_enabled
    raise CanCan::AccessDenied unless Settings.trading_partner_transforms.enabled
  end

  # Zip name: the ticket number when given, otherwise the uploaded file's
  # name when there is one file, otherwise a generic name.
  def uploaded_transform_zip_file_name(uploads)
    return "#{@transform_request.zip_prefix}transform_xmls.zip" if @transform_request.ticket_number.present?

    if uploads.size == 1
      base = File.basename(uploads.first.original_filename.to_s, ".*")
      "#{base}_transform_xmls.zip"
    else
      "uploaded_source_xml_transforms.zip"
    end
  end
end

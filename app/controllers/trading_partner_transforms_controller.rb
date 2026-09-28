class TradingPartnerTransformsController < ApplicationController
  before_filter :ensure_feature_enabled
  load_and_authorize_resource :class => "VocabUpload"

  # eg_ids can arrive as a query param after a redirect from one of the
  # other actions, so the policies do not need to be typed in twice.
  def new
    @transform_request = TradingPartnerTransformRequest.new(:eg_ids => params[:eg_ids])
  end

  # Generate and Download. Does not change any policy data.
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

  # Generate Source XML Only. Same inputs as Generate and Download, but
  # skips the X12 and CV1 step. Useful when the source XML needs review
  # before the transform is produced.
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

  # Transform Uploaded Source XML. Takes one or more enrollment event XML
  # files, produced earlier by Generate Source XML Only or by hand, and
  # runs the X12 and CV1 step on them directly. Does not look up any
  # policy. Only .xml files are accepted, nothing else.
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

  # Apply Data Changes. Separate from Generate and Download on purpose.
  # This only updates policy records. It never produces a zip.
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

    TradingPartnerTransforms::EndDateApplier.new(@transform_request, current_user.email).apply!
    flash_message(:success, "Data changes applied for eg_ids: #{@transform_request.eg_id_list.join(', ')}")
    redirect_to new_trading_partner_transform_path(:eg_ids => @transform_request.eg_ids)
  end

  private

  def ensure_feature_enabled
    raise CanCan::AccessDenied unless Settings.trading_partner_transforms.enabled
  end

  # Ticket number wins when given, matching the naming used everywhere
  # else in this tool. With no ticket and exactly one file uploaded, the
  # zip is named after that file, for example dep_add_source.xml
  # becomes dep_add_source_transform_xmls.zip. With no ticket and more
  # than one file, fall back to a generic name.
  def uploaded_transform_zip_file_name(uploads)
    ticket_params = params[:trading_partner_transform_request] || {}
    ticket = ticket_params[:ticket_number].to_s.strip
    return "#{ticket.gsub(/[^0-9A-Za-z_\-]/, '_')}_transform_xmls.zip" if ticket.present?

    if uploads.size == 1
      base = File.basename(uploads.first.original_filename.to_s, ".*")
      "#{base}_transform_xmls.zip"
    else
      "uploaded_source_xml_transforms.zip"
    end
  end
end

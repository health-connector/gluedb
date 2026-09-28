class TradingPartnerTransformsController < ApplicationController

  # eg_ids can arrive as a query param after a redirect from one of the
  # other actions, so the policies do not need to be typed in twice.
  def new
    authorize! :manage, :trading_partner_transforms
    @transform_request = TradingPartnerTransformRequest.new(:eg_ids => params[:eg_ids])
  end

  # Generate and Download. Does not change any policy data.
  def create
    authorize! :manage, :trading_partner_transforms
    @transform_request = TradingPartnerTransformRequest.new(params[:trading_partner_transform_request])

    unless @transform_request.valid?(:generate)
      flash[:error] = flash_error_list(@transform_request.errors.full_messages)
      redirect_to new_trading_partner_transform_path(:eg_ids => @transform_request.eg_ids)
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
    authorize! :manage, :trading_partner_transforms
    @transform_request = TradingPartnerTransformRequest.new(params[:trading_partner_transform_request])

    unless @transform_request.valid?(:generate)
      flash[:error] = flash_error_list(@transform_request.errors.full_messages)
      redirect_to new_trading_partner_transform_path(:eg_ids => @transform_request.eg_ids)
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
    authorize! :manage, :trading_partner_transforms
    uploads = Array(params[:source_xml_files]).reject(&:blank?)

    if uploads.empty?
      flash[:error] = flash_error_list(["Choose one or more .xml source XML files to upload"])
      redirect_to new_trading_partner_transform_path
      return
    end

    non_xml = uploads.reject { |upload| upload.original_filename.to_s.downcase.end_with?(".xml") }
    if non_xml.any?
      flash[:error] = flash_error_list(["Only .xml files are accepted: #{non_xml.map(&:original_filename).join(', ')}"])
      redirect_to new_trading_partner_transform_path
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
    authorize! :manage, :trading_partner_transforms
    @transform_request = TradingPartnerTransformRequest.new(params[:trading_partner_transform_request])

    unless @transform_request.valid?(:apply_changes)
      flash[:error] = flash_error_list(@transform_request.errors.full_messages)
      redirect_to new_trading_partner_transform_path(:eg_ids => @transform_request.eg_ids)
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

  # Builds one titled, bulleted error message for the shared layout flash
  # partial to render inside its existing danger alert box. This is the
  # only place errors for this controller get formatted, so the page
  # never shows the same error twice in two different styles.
  def flash_error_list(messages)
    return if messages.empty?
    items = messages.map { |message| "<li>#{ERB::Util.html_escape(message)}</li>" }.join
    %(<p class="tpt-errors-title">Errors</p><ul class="tpt-errors-list">#{items}</ul>).html_safe
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

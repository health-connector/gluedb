class Api::V2::IrsReportsController < ApplicationController

  def index
    page_number = params[:page] || 1

    # f = File.open(Rails.root.to_s + "/individual.xml")
    # doc = Nokogiri::XML(f)

    # individual = Parsers::Xml::IrsReports::Individual.new(doc)
    # @irs_household_groups = [] # Family.page(page_number).per(10)
     xml_data = CanonicalVocabulary::IrsHouseholdSerializer.new.serialize
     send_data xml_data, :disposition => 'inline', :type => 'text/xml'
    end
end

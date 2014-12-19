module Generators::Reports  
  class Renewals < PdfReport

    def initialize(type = 'uqhp')
      @assisted = (type == 'qhp') ? true : false
      template = @assisted ? "#{Rails.root}/qhp_template.pdf" : "#{Rails.root}/uqhp_template.pdf"
      super({:template => template})

      fill_envelope
      fill_enrollment_details
      fill_due_date
    end

    def fill_envelope
      position = cursor - 85

      bounding_box([2, 600], :width => 300) do
        text 'Alan Grayson'
        text '4415 Gwyndale Court'
        text 'Orlando, FL 32837'
      end

      bounding_box([95, 59], :width => 300) do
        text '1704151'
      end
    end

    def fill_enrollment_details
      go_to_page(2)
      bounding_box([80, 538], :width => 200) do
        text "#{Date.today.strftime('%m/%d/%Y')}"
      end

      bounding_box([345, 538], :width => 200) do
        text '1704151'
      end

      bounding_box([2, 490], :width => 300) do
        text 'Alan Grayson'
        text '4415 Gwyndale Court'
        text 'Orlando, FL 32837'
      end 

      bounding_box([29, 400], :width => 200) do
        text 'Alan Grayson:'
      end

      bounding_box([2, 290], :width => 200) do
        text "Alan M Grayson" 
        text "Lolita C Grayson"
        text "Skye K Grayson" 
        text "Star K Grayson"
        text "Sage K Grayson"
      end 

      bounding_box([200, 290], :width => 200) do
        text "Stone K Grayson" 
        text "Storm K Grayson"
      end

      if @assisted
        populate_qhp_policy
      else
        populate_uqhp_policy
      end
    end

    def populate_uqhp_policy
      bounding_box([65, 176], :width => 200) do
        text "HealthyBlue Advantage $1,500"
      end

      bounding_box([350, 145], :width => 200) do
        text "$1195.02"
      end

      bounding_box([65, 120], :width => 350) do
        text "NONE"
      end

      bounding_box([350, 90], :width => 200) do
        text "$0"
      end
    end

    def populate_qhp_policy
      bounding_box([65, 176], :width => 200) do
        text "HealthyBlue Advantage $1,500"
      end

      bounding_box([350, 145], :width => 200) do
        text "$1195.02"
      end

      bounding_box([65, 120], :width => 350) do
        text "NONE"
      end

      bounding_box([350, 90], :width => 200) do
        text "$0"
      end
    end

    def fill_due_date
      go_to_page(6)
      position = @assisted ? [157, 345] : [157, 538]
      bounding_box(position, :width => 200) do
        text "<b>#{(Date.today+90).strftime('%B %d, %Y')}</b>", :inline_format => true
      end
    end
  end
end

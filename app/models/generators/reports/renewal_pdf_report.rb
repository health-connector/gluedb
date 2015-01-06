module Generators::Reports  
  class RenewalPdfReport < PdfReport
    include ActionView::Helpers::NumberHelper

    def initialize(notice,type='uqhp')
      @assisted = (type == 'qhp') ? true : false
      template = @assisted ? "#{Rails.root}/qhp_template.pdf" : "#{Rails.root}/uqhp_template.pdf"
      super({:template => template})

      @margin = [50, 70]

      @notice = notice
      @address = notice.primary_address
      fill_envelope
      fill_enrollment_details
      fill_due_date
    end

    def fill_envelope

      # x_pos = mm2pt(21.83) - @margin[0]
      x_pos = mm2pt(21.83) - @margin[0]
      y_pos = 790.86 - mm2pt(57.15) - 65

      bounding_box([x_pos, y_pos], :width => 300) do
        fill_primary_address
      end
    end

    def fill_primary_address
      text @notice.primary_name
      text @address.street_1
      text @address.street_2 unless @address.street_2.blank?
      text "#{@address.city}, #{@address.state} #{@address.zip}"      
    end

    def fill_enrollment_details
      go_to_page(2)
      bounding_box([80, 538], :width => 200) do
        text "#{Date.today.strftime('%m/%d/%Y')}"
      end

      bounding_box([345, 538], :width => 200) do
        text @notice.primary_identifier
      end

      bounding_box([2, 490], :width => 300) do
        fill_primary_address
      end 

      bounding_box([29, 400], :width => 200) do
        text "#{@notice.primary_name}:"
      end

      bounding_box([2, 290], :width => 200) do
        text @notice.primary_name
        @notice.covered_individuals[0..3].each do |name|
          text name
        end
      end 
      
      if !@notice.covered_individuals[4..7].blank?
        bounding_box([200, 290], :width => 200) do
          @notice.covered_individuals[4..7].each do |name| 
            text name
          end
        end
      end

      @assisted ? fill_qhp_policy : fill_uqhp_policy
    end

    def fill_uqhp_policy
      bounding_box([65, 176], :width => 350) do
        text fill_health_plan_name
      end

      bounding_box([350, 145], :width => 200) do
        text number_to_currency(@notice.health_premium.to_f)
      end

      bounding_box([65, 120], :width => 350) do
        text fill_dental_plan_name
      end

      bounding_box([350, 90], :width => 200) do
        text number_to_currency(@notice.dental_premium.to_f)
      end
    end

    def fill_health_plan_name
      @notice.health_plan_name.blank? ? "None Selected" : @notice.health_plan_name
    end

    def fill_dental_plan_name
      @notice.dental_plan_name.blank? ? "None Selected" : @notice.dental_plan_name
    end

    def fill_qhp_policy
      bounding_box([65, 176], :width => 350) do
        text fill_health_plan_name
      end

      bounding_box([245, 148], :width => 100) do
        text number_to_currency(@notice.health_premium.to_f).gsub(/\$/, ''), :align => :right
        move_down(2)
        text number_to_currency(@notice.health_aptc.to_f).gsub(/\$/, ''), :align => :right
        move_down(15)
        text "<b>#{number_to_currency(@notice.health_responsible_amt.to_f).gsub(/\$/, '')}</b>", :align => :right, :inline_format => true
      end

      go_to_page(3)

      bounding_box([65, 668], :width => 350) do
        text fill_dental_plan_name
      end

      bounding_box([245, 639], :width => 100) do
        text number_to_currency(@notice.dental_premium.to_f).gsub(/\$/, ''), :align => :right
        move_down(2)
        text number_to_currency(@notice.dental_aptc.to_f).gsub(/\$/, ''), :align => :right
        move_down(15)
        text "<b>#{number_to_currency(@notice.dental_responsible_amt.to_f).gsub(/\$/, '')}</b>", :align => :right, :inline_format => true
      end
    end

    def fill_due_date
      go_to_page(6)
      position = @assisted ? [153, 345] : [153, 538]
      bounding_box(position, :width => 200) do
        text "<b>#{(Date.today+90).strftime('%B %d, %Y')}.</b>", :inline_format => true
      end
    end
  end
end

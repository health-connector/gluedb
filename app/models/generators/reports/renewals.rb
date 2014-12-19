module Generators::Reports  
  class Renewals < PdfReport

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
      x_pos = mm2pt(21.83) - @margin[0]
      y_pos = 841.89 - @margin[1] - mm2pt(61.52)

      bounding_box([x_pos, 600], :width => 300) do
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
        text '1704151'
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
      bounding_box([65, 176], :width => 200) do
        text fill_health_plan_name
      end

      bounding_box([350, 145], :width => 200) do
        text "$#{@notice.health_premium}"
      end

      bounding_box([65, 120], :width => 350) do
        text fill_dental_plan_name
      end

      bounding_box([350, 90], :width => 200) do
        text "$#{@notice.dental_premium}"
      end
    end

    def fill_health_plan_name
      @notice.health_plan_name.blank? ? "None Selected" : @notice.health_plan_name
    end

    def fill_dental_plan_name
      @notice.dental_plan_name.blank? ? "None Selected" : @notice.dental_plan_name
    end

    def fill_qhp_policy
      bounding_box([65, 176], :width => 200) do
        text fill_health_plan_name
      end

      bounding_box([245, 148], :width => 100) do
        text "1,195.02", :align => :right
        move_down(2)
        text "395.00", :align => :right
        move_down(15)
        text "<b>800.00</b>", :align => :right, :inline_format => true
      end

      go_to_page(3)

      bounding_box([65, 668], :width => 350) do
        text fill_dental_plan_name
      end

      bounding_box([245, 639], :width => 100) do
        text "0", :align => :right
        move_down(2)
        text "0", :align => :right
        move_down(15)
        text "<b>0</b>", :align => :right, :inline_format => true
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

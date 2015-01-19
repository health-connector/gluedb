module Generators::Reports  
  class IrsPdfReport < PdfReport
    include ActionView::Helpers::NumberHelper

    def initialize(notice)
      template = "#{Rails.root}/f1095a.pdf"
      super({:template => template, :margin => [30, 55]})
      font_size 11

      @notice = notice
      @margin = [30, 70]

      fill_envelope
      fill_subscriber_details
      fill_household_details
      fill_preimum_details
    end

    def fill_envelope
    end

    def fill_subscriber_details
      col1 = mm2pt(-2)
      col2 = mm2pt(51.50)
      col3 = mm2pt(102.50)
      col4 = mm2pt(145.50)
      y_pos = 790.86 - mm2pt(37.15) - 45

      bounding_box([col1, y_pos], :width => 100) do
        #stroke_bound
        text 'DC'
      end

      bounding_box([col2, y_pos], :width => 150) do
        #stroke_bound
        text @notice.policy_id
      end

      bounding_box([col3, y_pos], :width => 200) do
        #stroke_bound
        text @notice.issuer_name
      end

      move_down(12)
      fill_enrollee(@notice.recipient)

      move_down(12)
      if @notice.spouse
        fill_enrollee(@notice.spouse)
      else
        move_down(13)
      end

      move_down(11)
      y_pos = cursor

      bounding_box([col1, y_pos], :width => 100) do
        #stroke_bound
        text @notice.recipient.coverage_start_date
      end

      bounding_box([col2, y_pos], :width => 100) do
        #stroke_bound
        text @notice.recipient.coverage_termination_date.to_s
      end

      bounding_box([col3, y_pos], :width => 200) do
        #stroke_bound
        text @notice.recipient_address.street_1
      end

      move_down(12)
      y_pos = cursor

      bounding_box([col1, y_pos], :width => 120) do
        #stroke_bound
        text @notice.recipient_address.city
      end

      bounding_box([col2, y_pos], :width => 100) do
        #stroke_bound
        text @notice.recipient_address.state
      end

      bounding_box([col3, y_pos], :width => 100) do
        #stroke_bound
        text @notice.recipient_address.zip
      end
    end

    def fill_enrollee(enrollee)
      col1 = mm2pt(-2)
      col3 = mm2pt(102.50)
      col4 = mm2pt(145.50)
      y_pos = cursor

      bounding_box([col1, y_pos], :width => 240) do
        #stroke_bound
        text enrollee.name
      end

      bounding_box([col3, y_pos], :width => 100) do
        #stroke_bound
        text enrollee.ssn
      end

      bounding_box([col4, y_pos], :width => 100) do
        #stroke_bound
        text enrollee.dob
      end    
    end

    def fill_household_details
      col1 = mm2pt(0)
      col2 = mm2pt(67.50)
      col3 = mm2pt(98.50)
      col4 = mm2pt(128.50)
      col5 = mm2pt(159.50)

      y_pos = 472

      @notice.covered_household.each do |individual|
        bounding_box([col1, y_pos], :width => 150) do
          #stroke_bounds
          text individual.name
        end
        bounding_box([col2, y_pos], :width => 100) do
          #stroke_bounds
          text individual.ssn
        end
        bounding_box([col3, y_pos], :width => 100) do
          #stroke_bounds
          text individual.dob
        end
        bounding_box([col4, y_pos], :width => 100) do
          #stroke_bounds
          text individual.coverage_start_date
        end
        bounding_box([col5, y_pos], :width => 100) do
          #stroke_bounds
          # text individual.coverage_termination_date.to_s
          text "12/31/2014"
        end
        y_pos = y_pos - 24
      end      
    end

    def fill_preimum_details
      col1 = mm2pt(36.50)
      col2 = mm2pt(76.50)
      col3 = mm2pt(125.50)
      y_pos = 304

      @notice.monthly_premiums.each_with_index do |monthly_premium, index|
        bounding_box([col1, y_pos], :width => 100) do
          #stroke_bounds
          text "$ "+monthly_premium.premium_amount, :align => :right
        end
        bounding_box([col2, y_pos], :width => 130) do
          #stroke_bounds
          text "$ "+monthly_premium.premium_amount_slcsp, :align => :right
        end
        bounding_box([col3, y_pos], :width => 120) do
          #stroke_bounds
          text monthly_premium.monthly_aptc, :align => :right
        end
        y_pos = y_pos - 24
      end

      premium_total = @notice.monthly_premiums.inject(0.0){|sum, premium|  sum + premium.premium_amount.to_f}
      slcsp_total = @notice.monthly_premiums.inject(0.0){|sum, premium| sum + premium.premium_amount_slcsp.to_f}
      aptc_total = @notice.monthly_premiums.inject(0.0){|sum, premium| sum + premium.monthly_aptc.to_f}

      bounding_box([col1, y_pos], :width => 100) do
        text "$ #{premium_total.round(2)}", :align => :right
      end

      bounding_box([col2, y_pos], :width => 130) do
        text "$ #{slcsp_total.round(2)}", :align => :right
      end

      bounding_box([col3, y_pos], :width => 120) do
        text "", :align => :right
      end
    end
  end
end
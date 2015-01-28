module Generators::Reports  
  class IrsPdfReport < PdfReport
    include ActionView::Helpers::NumberHelper

    def initialize(notice, multiple = false)
      @multiple = multiple
      template = "#{Rails.root}/1095a_template.pdf"

      super({:template => template, :margin => [30, 55]})
      font_size 11

      @notice = notice
      @margin = [30, 70]

      fill_envelope
      fill_coverletter
      go_to_page(5)
      fill_subscriber_details
      fill_household_details
      fill_preimum_details
    end

    def fill_envelope
      x_pos = mm2pt(21.83) - @margin[0]
      y_pos = 790.86 - mm2pt(57.15) - 65

      bounding_box([x_pos, y_pos], :width => 300) do
        fill_recipient_contact
      end
    end

    def fill_coverletter
      go_to_page(3)

      bounding_box([15, 553], :width => 200) do
        text "#{Date.today.strftime('%m/%d/%Y')}"
      end

      bounding_box([15, 525], :width => 300) do
        fill_recipient_contact
      end

      bounding_box([44, 430], :width => 200) do
        text "#{@notice.recipient.name}:"
      end
    end

    def fill_recipient_contact
      text @notice.recipient.name
      text @notice.recipient_address.street_1
      text @notice.recipient_address.street_2 unless @notice.recipient_address.street_2.blank?
      text "#{@notice.recipient_address.city}, #{@notice.recipient_address.state} #{@notice.recipient_address.zip}"      
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
        text @notice.policy_id
      end

      bounding_box([col3, y_pos], :width => 200) do
        text @notice.issuer_name
      end

      move_down(12)
      if @notice.recipient.blank?
        raise "no subscriber!!"
      end
      fill_enrollee(@notice.recipient)

      move_down(12)
      if @notice.spouse && @notice.has_aptc
        fill_enrollee(@notice.spouse)
      else
        move_down(13)
      end

      move_down(11)
      y_pos = cursor

      bounding_box([col1, y_pos], :width => 100) do
        text @notice.recipient.coverage_start_date
      end

      bounding_box([col2, y_pos], :width => 100) do
        text @notice.recipient.coverage_termination_date.to_s
      end

      bounding_box([col3, y_pos], :width => 200) do
        street_address = @notice.recipient_address.street_1
        if !@notice.recipient_address.street_2.blank?
          street_address += ", #{@notice.recipient_address.street_2}"
        end
        text street_address
      end

      move_down(12)
      y_pos = cursor

      bounding_box([col1, y_pos], :width => 120) do
        text @notice.recipient_address.city
      end

      bounding_box([col2, y_pos], :width => 100) do
        text @notice.recipient_address.state
      end

      bounding_box([col3, y_pos], :width => 100) do
        text @notice.recipient_address.zip
      end
    end

    def fill_enrollee(enrollee)
      col1 = mm2pt(-2)
      col3 = mm2pt(102.50)
      col4 = mm2pt(145.50)
      y_pos = cursor

      bounding_box([col1, y_pos], :width => 240) do
        text enrollee.name
      end

      if !enrollee.ssn.blank?
        bounding_box([col3, y_pos], :width => 100) do
          text mask_ssn(enrollee.ssn)
        end
      else
        bounding_box([col4, y_pos], :width => 100) do
          text enrollee.dob
        end
      end
    end

    def fill_household_details
      col1 = mm2pt(0)
      col2 = mm2pt(67.50)
      col3 = mm2pt(98.50)
      col4 = mm2pt(128.50)
      col5 = mm2pt(159.50)

      y_pos = 472

      covered_household = @notice.covered_household[0..4]
      covered_household = @notice.covered_household[5..9] if @multiple

      covered_household.each do |individual|
        bounding_box([col1, y_pos], :width => 150) do
          text individual.name
        end
        if !individual.ssn.blank?
          bounding_box([col2, y_pos], :width => 100) do
            text mask_ssn(individual.ssn)
          end
        else
          bounding_box([col3, y_pos], :width => 100) do
            text individual.dob
          end
        end
        bounding_box([col4, y_pos], :width => 100) do
          text individual.coverage_start_date
        end
        bounding_box([col5, y_pos], :width => 100) do
          text individual.coverage_termination_date
        end
        y_pos = y_pos - 24
      end      
    end

    def fill_preimum_details
      col1 = mm2pt(36.50)
      col2 = mm2pt(76.50)
      col3 = mm2pt(125.50)
      y_pos = 304

      (1..12).each do |index|
        monthly_premium = @notice.monthly_premiums.detect{|p| p.serial == index}
        if monthly_premium
          bounding_box([col1, y_pos], :width => 100) do
            text number_to_currency(monthly_premium.premium_amount), :align => :right
          end

          if @notice.has_aptc
            bounding_box([col2, y_pos], :width => 130) do
              text number_to_currency(monthly_premium.premium_amount_slcsp), :align => :right
            end

            bounding_box([col3, y_pos], :width => 120) do
              text number_to_currency(monthly_premium.monthly_aptc), :align => :right
            end
          end
        end
        y_pos = y_pos - 24
      end

      bounding_box([col1, y_pos], :width => 100) do
        text number_to_currency(@notice.yearly_premium.premium_amount), :align => :right
      end

      if @notice.has_aptc
        bounding_box([col2, y_pos], :width => 130) do
          text number_to_currency(@notice.yearly_premium.slcsp_premium_amount), :align => :right
        end
  
        bounding_box([col3, y_pos], :width => 120) do
          text number_to_currency(@notice.yearly_premium.aptc_amount), :align => :right
        end
      end
    end

    def number_to_ssn(number)
      return unless number
      delimiter = "-"
      number.to_s.gsub!(/(\d{0,3})(\d{2})(\d{4})$/,"\\1#{delimiter}\\2#{delimiter}\\3")
    end

    def mask_ssn(ssn)
      ssn = number_to_ssn(ssn)
      last_digits = ssn.match(/\d{4}$/)[0]
      "***-**-#{last_digits}"
    end
  end
end
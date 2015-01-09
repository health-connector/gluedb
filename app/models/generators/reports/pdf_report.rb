module Generators::Reports  
  class PdfReport < Prawn::Document
    include Prawn::Measurements

    def initialize(options={ })
      if options[:margin].nil?
        options.merge!(:margin => [50, 70])
      end
      
      super(options)
      
      font "Times-Roman"
      font_size 12
    end
    
    def print_date
      text Time.now.strftime("%m/%d/%Y")
    end
    
    def address_block(person)
      address = person.home_address
      
      move_down 5
      print_date
      
      move_down 10
      text person.full_name
      text address.address_1
      text address.address_2 unless address.address_2.blank?
      text "#{address.city}, #{address.state} #{address.zip}"
    end
    
    def footer
    end
    
    def text(text, options = { })
      if !options.has_key?(:align)
        options.merge!({ :align => :justify })
      end

      super text, options
    end
    
    def subheading(sub_heading)
      move_down 20
      text sub_heading, { :style => :bold, :size => 14, :color => "0a558e"}
      move_down 15
    end
    
    def table_with_header(data, options = {})
      add_page_break_if_overflow do
        table(data, :position => :left, :column_widths => { 0 => 180, 1 => 250}) do
          cells.border_width = 0.25
          row(0).background_color = "c4d5e6"
          row(0).border_bottom_width = 0
        end
      end
    end

    def table_without_header(data)
      add_page_break_if_overflow do
        table(data, :position => :left, :column_widths => { 0 => 180, 1 => 100}) do
          cells.border_width = 0.25
          row(0).border_bottom_width = 0
          column(1).style :align => :right
        end
      end
    end

    def add_page_break_if_overflow(&block)
      current_page = page_count
      roll = transaction do
        yield        
        rollback if page_count > current_page
      end
      
      if roll == false
        start_new_page
        yield
      end
    end
    
    def dchbx_address
      text "DC Health Link"
      text "Department of Human Services"
      text "P.O. Box 91560"
      text "Washington, DC 20090"
    end
    
    def list_display(data)      
      data.each do |item|        
        float do
          bounding_box [10, cursor], :width => 10 do
            # text "\u2022"
          end
        end

        bounding_box [0,cursor], :width => 500 do
          text item
        end
        
        move_down(5)        
      end
    end

    def bullet_string(text, bullet_code = "\u2022")
      add_page_break_if_overflow do
        float do
          bounding_box [10, cursor], :width => 10 do
            text bullet_code
          end
        end
        
        bounding_box [20,cursor], :width => (bounds.right - 20) do
          text text, :inline_format => true, :align => :justify
        end
      end
    end
  end
end

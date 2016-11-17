module Handlers
  class EnricherHandler < Base

    def call(context)
      event_list = merge_or_split(context.event_list)
      event_list.map do |element|
        @app.call(duplicate_context(context, element))
      end
    end

    protected

    def duplicate_context(context, event_element)
      new_context = OpenStruct.new
      context.each_pair do |k, v|
        if !(k.to_s == "event_list")
          context[k] = v
        end
      end
      new_context.raw_event_xml = event_element
      new_context
    end

    # Slug until we do actual reduction logic
    def merge_or_split(event_list)
      event_list
    end
  end
end

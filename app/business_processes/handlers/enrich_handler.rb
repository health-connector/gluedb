module Handlers
  class EnrichHandler < Base

    def call(context)
      event_list = merge_or_split(context.event_list)
      event_list.map do |element|
        super(duplicate_context(context, element))
      end
    end

    protected
    def duplicate_context(context, reduced_set)
      new_context = OpenStruct.new
      context.each_pair do |k, v|
        if (k.to_s == "business_process_history")
          context[k] = v.dup
        elsif !(k.to_s == "event_list")
          context[k] = v
        end
      end
      new_context.event_list = reduced_set
      new_context
    end

    # Slug until we do actual reduction logic
    def merge_or_split(event_list)
      event_list
    end
  end
end

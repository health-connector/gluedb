module Parsers
  module Edi
    module Etf
      class EmployerLoop
        def initialize(employer_loop)
          @loop = employer_loop
        end

        def group_id
          @loop[4]
        end

        def name
          @loop[2]
        end

        def fein
          Maybe.new(@loop[4]).strip.gsub(/[^0-9]/, "").value
        end

        def specified_as_group?
          id_qualifier == "94"
        end

        def id_qualifier
          @loop[3]
        end
      end
    end
  end
end
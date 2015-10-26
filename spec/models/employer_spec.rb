require 'rails_helper'

describe Employer do
  [
    :name,
    :fein,
    :hbx_id,
    :sic_code,
    :fte_count,
    :pte_count,
    :open_enrollment_start,
    :open_enrollment_end,
    :plan_year_start,
    :plan_year_end,
    :name_pfx,
    :name_first,
    :name_middle,
    :name_last,
    :name_sfx,
    :notes
  ].each do |attribute|
    it { should respond_to attribute }
  end
end

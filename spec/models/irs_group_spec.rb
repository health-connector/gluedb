require 'rails_helper'
require 'irs_groups/irs_group_builder'

describe IrsGroup do

  before(:each) do
    @family = Family.new
    @family.households.build({is_active:true})
    @irs_group_builder = IrsGroupBuilder.new(@family)
    @irs_group = @irs_group_builder.build
  end

  it 'should set effective start and end date' do
    @family.save
    expect(@irs_group.effective_start_date).to eq(@family.active_household.effective_start_date)
    expect(@irs_group.effective_end_date).to eq(@family.active_household.effective_end_date)
  end

  it 'should set a 16 digit id' do
    @family.save
    expect(@irs_group.id.to_s.length).to eq(16)
  end

end
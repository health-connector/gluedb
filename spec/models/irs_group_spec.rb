require 'rails_helper'
require 'irs_groups/irs_group_builder'

describe IrsGroup do

  before(:each) do
    @application_group = ApplicationGroup.new
    @application_group.households.build({is_active:true})
    @irs_group_builder = IrsGroupBuilder.new(@application_group)
    @irs_group = @irs_group_builder.build
  end

  it 'should set effective start and end date' do
    @application_group.save
    expect(@irs_group.effective_start_date).to eq(@application_group.active_household.effective_start_date)
    expect(@irs_group.effective_end_date).to eq(@application_group.active_household.effective_end_date)
  end

  it 'should set a 16 digit id' do
    @application_group.save
    expect(@irs_group.id.to_s.length).to eq(16)
  end

end
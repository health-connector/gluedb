require 'rails_helper'
require 'irs_groups/irs_group_builder'

describe IrsGroupBuilder do

  before(:each) do
    @application_group = ApplicationGroup.new
    @application_group.households.build({is_active:true})
    @irs_group_builder = IrsGroupBuilder.new(@application_group)
  end

  it 'returns a IrsGroup object' do
    expect(@irs_group_builder.build).to be_a_kind_of(IrsGroup)
  end

  it 'builds a valid IrsGroup object' do
    irs_group = @irs_group_builder.build
    expect(irs_group.valid?).to eq(true)
  end

  it 'returns a IrsGroup object with Id of length 16' do
    irs_group = @irs_group_builder.build
    irs_group.save
    expect(irs_group.id.to_s.length).to eq(16)
  end

  it 'application group household has been assigned the id of the irs group' do
    irs_group = @irs_group_builder.build
    irs_group.save
    expect(irs_group.id).to eq(@application_group.active_household.irs_group_id)
  end
end
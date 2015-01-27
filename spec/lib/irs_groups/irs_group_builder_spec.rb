require 'rails_helper'
require 'irs_groups/irs_group_builder'

describe IrsGroupBuilder do

  before(:each) do
    @family = Family.new({submitted_at:DateTime.now})
    @family.households.build({is_active:true})
    @irs_group_builder = IrsGroupBuilder.new(@family)
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
    @irs_group_builder.save
    expect(irs_group.id.to_s.length).to eq(16)
  end

  it 'application group household has been assigned the id of the irs group' do
    irs_group = @irs_group_builder.build
    @irs_group_builder.save
    expect(irs_group.id).to eq(@family.active_household.irs_group_id)
  end
end
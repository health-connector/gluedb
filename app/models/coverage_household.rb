class CoverageHousehold
  include Mongoid::Document
  include Mongoid::Timestamps

  embedded_in :household

  embeds_many :coverage_household_members
  accepts_nested_attributes_for :coverage_household_members

end

require 'rails_helper'
require File.join(Rails.root, "lib", "name_matcher")

describe NameMatcher do

  before(:all) do
    @nm = NameMatcher.new("luther","pullock jr")
  end

  it 'matches names with roman numerals' do
    expect(NameMatcher.new("luther","pullock iii").match("luther","pullock")).to be_truthy
  end

  it "matches names with roman numerals and jr/sr" do
    expect(NameMatcher.new("luther","pullock iii jr.").match("luther","pullock jr")).to be_truthy
  end

  it "matches identical names" do
    expect(NameMatcher.new("luther","pullock").match("luther","pullock")).to be_truthy
  end

  it "matches names with difference in components" do
    expect(NameMatcher.new("luther r","pullock").match("luther","r pullock")).to be_truthy
  end

  it "fails when 1st and last name is different" do
    expect(NameMatcher.new("lut","pullock").match("luther","r pullock")).to be_falsey
  end

  it "fails when 1st name differs but last name has exact match" do
    expect(NameMatcher.new("lut","pullock").match("luther","pullock")).to be_falsey
  end

  it "matches hyphen separated names" do
    expect(NameMatcher.new("luther","pullock-zen").match("luther","pullock zen")).to be_true
  end

  it "matches names which differ only by a '-' or '.'" do
    expect(NameMatcher.new("luther","j. pullock-zen").match("luther","j pullock zen")).to be_true
  end

  it "matches names which differ only by a '-' or '.' or ','" do
    expect(NameMatcher.new("jeffrey","wieand").match("jeffrey","wieand, jr.")).to be_true
  end

  it "matches names kristopher, white; person has kristoper, white" do
    expect(NameMatcher.new("kristopher","white").match("kristoper","white")).to be_falsey
  end

  it "matches names kevin jones" do
    expect(NameMatcher.new("kevin","jones").match("kevin","jones jr")).to be_truthy
  end

end
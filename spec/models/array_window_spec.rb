require "rails_helper"

describe ArrayWindow do
  let(:item1) { double }
  let(:item2) { double }
  let(:item3) { double }
  let(:yield_slug) { double }

  subject { ArrayWindow.new([item1, item2, item3]) }

  it "yields the items in order" do
    expect(yield_slug).to receive(:call).with(item1, [], [item2, item3])
    expect(yield_slug).to receive(:call).with(item2, [item1], [item3])
    expect(yield_slug).to receive(:call).with(item3, [item1, item2], [])
    subject.each do |items|
      before, item, after = items
      yield_slug.call(before, item, after)
    end
  end
end

# frozen_string_literal: true

RSpec.describe Fixably::ActiveResource::PaginatedCollection do
  let(:collection_wrapper) do
    {
      "limit" => 10,
      "offset" => 5,
      "totalItems" => 100,
      "unexpected" => "value",
      "items" => [
        { "first_name" => "Lawrence", "last_name" => "Terry" },
        { "first_name" => "Chris", "last_name" => "Shields" },
      ],
    }
  end

  it "is an ActiveResource::Collection" do
    expect(described_class.ancestors).to include(::ActiveResource::Collection)
  end

  it "extracts the collection from items" do
    instance = described_class.new(collection_wrapper)
    expect(instance).to eq(
      [
        { "first_name" => "Lawrence", "last_name" => "Terry" },
        { "first_name" => "Chris", "last_name" => "Shields" },
      ]
    )
  end

  it "extracts the limit parameter" do
    instance = described_class.new(collection_wrapper)
    expect(instance.limit).to eq(10)
  end

  it "extracts the offset parameter" do
    instance = described_class.new(collection_wrapper)
    expect(instance.offset).to eq(5)
  end

  it "extracts the total items parameter" do
    instance = described_class.new(collection_wrapper)
    expect(instance.total_items).to eq(100)
  end
end

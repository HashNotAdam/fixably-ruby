# frozen_string_literal: true

# Active Resource defaults to JSON format
RSpec.shared_examples "an Active Resource encoder" do
  it "has an options parameter for compatibility" do
    expect { described_class.new.encode("foobar") }.not_to raise_error
  end

  it "encodes the attributes to the format required by the API" do
    instance = described_class.new
    instance.instance_variable_set(:@attributes, { "firstName" => "Jill" })
    expect(instance.encode).to eq({ "firstName" => "Jill" }.to_json)
  end

  it "removes the ID attribute" do
    instance = described_class.new
    instance.instance_variable_set(
      :@attributes, { "id" => 1, "firstName" => "Jill" }
    )
    expect(instance.encode).to eq({ "firstName" => "Jill" }.to_json)
  end

  it "camelizes the attribute names" do
    instance = described_class.new
    instance.instance_variable_set(:@attributes, { "first_name" => "Jill" })
    expect(instance.encode).to eq({ "firstName" => "Jill" }.to_json)
  end

  context "when the attrs arguement is supplied" do
    it "uses the supplied attributes" do
      instance = described_class.new
      instance.instance_variable_set(:@attributes, { "firstName" => "Jill" })
      result = instance.encode(attrs: { "lastName" => "Wunsch" })
      expect(result).to eq({ "lastName" => "Wunsch" }.to_json)
    end
  end
end

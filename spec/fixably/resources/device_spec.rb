# frozen_string_literal: true

RSpec.describe Fixably::Device do
  include_examples(
    "a resource",
    "device",
    "devices",
    %i[create list show]
  )

  describe "#save" do
    context "when name is nil" do
      subject(:instance) { described_class.new(serial_number: "ABCDE123FGHI") }

      it { is_expected.not_to be_valid }

      it "adds an error to the instance" do
        instance.valid?
        error = instance.errors.full_messages.to_sentence
        expect(error).to eq("Name can't be blank")
      end
    end

    context "when name is blank" do
      subject(:instance) do
        described_class.new(serial_number: "ABCDE123FGHI", name: "")
      end

      it { is_expected.not_to be_valid }

      it "adds an error to the instance" do
        instance.valid?
        error = instance.errors.full_messages.to_sentence
        expect(error).to eq("Name can't be blank")
      end
    end

    context "when both the serial number and IMEI are blank" do
      it "is invalid" do
        instance = described_class.new(name: "Name")
        expect(instance).not_to be_valid

        instance = described_class.new(name: "Name", serial_number: "")
        expect(instance).not_to be_valid
        instance = described_class.new(name: "Name", serial_number: "1")
        expect(instance).to be_valid

        instance = described_class.new(name: "Name", imei_number1: "")
        expect(instance).not_to be_valid
        instance = described_class.new(name: "Name", imei_number1: "1")
        expect(instance).to be_valid
      end

      it "adds an error to the instance" do
        instance = described_class.new(name: "Name")
        instance.valid?
        error = instance.errors.full_messages.to_sentence
        expect(error).to eq("Either serial number or IMEI must be present")
      end
    end
  end
end

# frozen_string_literal: true

RSpec.describe Fixably::ResourceLazyLoader do
  let(:instance) { described_class.new(model: model) }
  let(:model) do
    Class.new(Fixably::ApplicationResource) do
      has_one :single_thing
      has_many :many_things
    end
  end

  it "accepts a class that extends ApplicationResource" do
    expect(instance.model).to be(model)
  end

  it "does not accept an instance of a class extending ApplicationResource" do
    expect { described_class.new(model: model.new) }.to raise_error(
      ArgumentError,
      "The model is expected to be a class that extend ApplicationResource"
    )
  end

  it "does not accept a class that does not extend ApplicationResource" do
    invalid_model = Class.new
    expect { described_class.new(model: invalid_model) }.to raise_error(
      ArgumentError,
      "The model is expected to be a class that extend ApplicationResource"
    )
  end

  describe "#includes" do
    it "adds a has_one association to associations_to_expand" do
      instance.includes(:single_thing)
      expect(instance.associations_to_expand).to include(:single_thing)
    end

    it "adds a has_many association to associations_to_expand" do
      instance.includes(:many_things)
      expect(instance.associations_to_expand).to include(:many_things)
    end

    it "does not accept unknown associations" do
      expect { instance.includes(:unknown_things) }.to raise_error(
        ArgumentError,
        "unknown_things is not a known association of #{model}"
      )
    end

    it "is chainable" do
      instance.includes(:single_thing).includes(:many_things)
      expect(instance.associations_to_expand).to include(
        :single_thing, :many_things
      )
    end

    it "does not store duplicates" do
      instance.includes(:single_thing).includes(:single_thing)
      expect(instance.associations_to_expand.count).to be 1
    end
  end

  describe "#find" do
    before { allow(model).to receive(:find) }

    it "forwards the message onto the model" do
      instance.find(1)
      expect(model).to have_received(:find).with(1, expand: Set.new)
    end

    context "when options are supplied" do
      it "merges expand into the supplied options" do
        instance.find(1, { option1: "A", option2: "B" }, option3: "C")
        expect(model).to have_received(:find).
          with(1, { expand: Set.new, option1: "A", option2: "B" }, option3: "C")
      end
    end

    it "requests to expand any associations passed via the includes method" do
      associations = Set.new
      associations << :single_thing
      associations << :many_things

      instance.includes(:single_thing).includes(:many_things).find(1)
      expect(model).to have_received(:find).with(1, expand: associations)
    end

    context "when an expand option is supplied" do
      it "merges the supplied options with the included associations" do
        associations = Set.new
        associations << :supplied_thing
        associations << :single_thing
        associations << :many_things

        instance.includes(:single_thing).includes(:many_things)
        instance.find(1, expand: [:supplied_thing])
        expect(model).to have_received(:find).with(1, expand: associations)
      end
    end
  end

  describe "#first" do
    before { allow(model).to receive(:first) }

    it "forwards the message onto the model" do
      instance.first
      expect(model).to have_received(:first)
    end

    context "when options are supplied" do
      it "merges expand into the supplied options" do
        instance.first({ option1: "A", option2: "B" }, option3: "C")
        expect(model).to have_received(:first).
          with({ expand: Set.new, option1: "A", option2: "B" }, option3: "C")
      end
    end

    it "requests to expand any associations passed via the includes method" do
      associations = Set.new
      associations << :single_thing
      associations << :many_things

      instance.includes(:single_thing).includes(:many_things).first
      expect(model).to have_received(:first).with(expand: associations)
    end

    context "when an expand option is supplied" do
      it "merges the supplied options with the included associations" do
        associations = Set.new
        associations << :supplied_thing
        associations << :single_thing
        associations << :many_things

        instance.includes(:single_thing).includes(:many_things)
        instance.first(expand: [:supplied_thing])
        expect(model).to have_received(:first).with(expand: associations)
      end
    end
  end

  describe "#last" do
    before { allow(model).to receive(:last) }

    it "forwards the message onto the model" do
      instance.last
      expect(model).to have_received(:last)
    end

    context "when options are supplied" do
      it "merges expand into the supplied options" do
        instance.last({ option1: "A", option2: "B" }, option3: "C")
        expect(model).to have_received(:last).
          with({ expand: Set.new, option1: "A", option2: "B" }, option3: "C")
      end
    end

    it "requests to expand any associations passed via the includes method" do
      associations = Set.new
      associations << :single_thing
      associations << :many_things

      instance.includes(:single_thing).includes(:many_things).last
      expect(model).to have_received(:last).with(expand: associations)
    end

    context "when an expand option is supplied" do
      it "merges the supplied options with the included associations" do
        associations = Set.new
        associations << :supplied_thing
        associations << :single_thing
        associations << :many_things

        instance.includes(:single_thing).includes(:many_things)
        instance.last(expand: [:supplied_thing])
        expect(model).to have_received(:last).with(expand: associations)
      end
    end
  end

  describe "#all" do
    before { allow(model).to receive(:all) }

    it "forwards the message onto the model" do
      instance.all
      expect(model).to have_received(:all)
    end

    context "when options are supplied" do
      it "merges expand into the supplied options" do
        instance.all({ option1: "A", option2: "B" }, option3: "C")
        expect(model).to have_received(:all).
          with({ expand: Set.new, option1: "A", option2: "B" }, option3: "C")
      end
    end

    it "requests to expand any associations passed via the includes method" do
      associations = Set.new
      associations << :single_thing
      associations << :many_things

      instance.includes(:single_thing).includes(:many_things).all
      expect(model).to have_received(:all).with(expand: associations)
    end

    context "when an expand option is supplied" do
      it "merges the supplied options with the included associations" do
        associations = Set.new
        associations << :supplied_thing
        associations << :single_thing
        associations << :many_things

        instance.includes(:single_thing).includes(:many_things)
        instance.all(expand: [:supplied_thing])
        expect(model).to have_received(:all).with(expand: associations)
      end
    end
  end

  describe "#where" do
    before { allow(model).to receive(:where) }

    it "forwards the message onto the model" do
      instance.where
      expect(model).to have_received(:where)
    end

    context "when options are supplied" do
      it "merges expand into the supplied options" do
        instance.where(option1: "A", option2: "B")
        expect(model).to have_received(:where).
          with(expand: Set.new, option1: "A", option2: "B")
      end
    end

    it "requests to expand any associations passed via the includes method" do
      associations = Set.new
      associations << :single_thing
      associations << :many_things

      instance.includes(:single_thing).includes(:many_things).where
      expect(model).to have_received(:where).with(expand: associations)
    end

    context "when an expand option is supplied" do
      it "merges the supplied options with the included associations" do
        associations = Set.new
        associations << :supplied_thing
        associations << :single_thing
        associations << :many_things

        instance.includes(:single_thing).includes(:many_things)
        instance.where(expand: [:supplied_thing])
        expect(model).to have_received(:where).with(expand: associations)
      end
    end
  end
end

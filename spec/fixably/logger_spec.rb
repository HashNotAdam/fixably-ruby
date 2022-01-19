# frozen_string_literal: true

RSpec.describe Fixably::Logger do
  describe "#logger" do
    after { described_class.logger = nil }

    context "when used in a Rails app" do
      context "when Rails responds to logger" do
        let(:logger) { Logger.new(nil) }

        before do
          stub_const("Rails", Struct.new(:logger).new(logger))
        end

        it "uses the Rails logger" do
          expect(described_class.logger).to eq logger
        end
      end

      context "when Rails does not respond to logger" do
        before { stub_const("Rails", Class.new) }

        it "uses the Ruby logger" do
          expect(described_class.logger).to be_a(Logger)
        end

        it "logs to stdout" do
          logger = described_class.logger
          log_location = logger.instance_variable_get(:@logdev).dev
          expect(log_location).to eq($stdout)
        end

        it "sets the log level to WARN" do
          expect(described_class.logger.level).to be(::Logger::WARN)
        end
      end
    end

    context "when used outside of a Rails app" do
      it "uses the Ruby logger" do
        expect(described_class.logger).to be_a(Logger)
      end

      it "sets the log level to WARN" do
        expect(described_class.logger.level).to be(::Logger::WARN)
      end

      it "logs to stdout" do
        logger = described_class.logger
        log_location = logger.instance_variable_get(:@logdev).dev
        expect(log_location).to eq($stdout)
      end
    end

    context "when the logger is set by the user" do
      let(:logger) { Class.new }

      before { described_class.logger = logger }

      it "uses the user's logger" do
        expect(described_class.logger).to be(logger)
      end
    end
  end

  describe "message delegation" do
    let(:logger) { Struct.new(:info).new(nil) }

    before do
      allow(logger).to receive(:info)
      described_class.logger = logger
    end

    it "delegates messages to the logger" do
      described_class.info("Message")
      expect(logger).to have_received(:info).with("Message")
    end
  end
end

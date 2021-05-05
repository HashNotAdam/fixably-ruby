# frozen_string_literal: true

RSpec.describe Fixably::Logger do
  after { described_class.instance_variable_set(:@logger, nil) }

  context "when mounted into a Rails app" do
    before do
      rails_class = Class.new do
        def self.logger
          @logger ||= ::Logger.new($stdout)
        end
      end
      Object.const_set(:Rails, rails_class)
    end

    after do
      Object.__send__(:remove_const, :Rails) if Object.const_defined?(:Rails)
    end

    it "delegates the logging to Rails" do
      expect(described_class.logger).to eq(Rails.logger)
    end
  end

  context "when being used outside of Rails" do
    it "initializes an instance of the Ruby Logger" do
      expect(described_class.logger).to be_a(::Logger)
    end

    it "sets the log level to WARN" do
      expect(described_class.logger.level).to eq(::Logger::WARN)
    end
  end
end

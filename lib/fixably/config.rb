# frozen_string_literal: true

module Fixably
  class Config
    attr_accessor :api_key
    attr_accessor :subdomain

    def require(param)
      value = public_send(param)
      return value unless value.nil? || value.empty?

      require_error(param)
    end

    private

    def require_error(param)
      raise(
        ArgumentError,
        "#{param} is required but hasn't been set.\n" \
          "Fixably.configure do |config|\n" +
          %(  config.#{param} = "value") + "\n" \
          "end"
      )
    end
  end
end

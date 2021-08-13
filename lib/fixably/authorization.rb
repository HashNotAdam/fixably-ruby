# frozen_string_literal: true

module Fixably
  module Authorization
    def headers
      result = super()
      result["Authorization"] = api_key
      result
    end

    private

    def api_key
      Fixably.config.require(:api_key)
    end
  end
end

# frozen_string_literal: true

module Fixably
  class User < ApplicationResource
    schema do
      integer :id
      string :first_name
      string :last_name
      string :email
      string :phone
    end

    def self.find(*arguments)
      raise "Users may only be retrieved by ID" if arguments[0].is_a?(Symbol)

      super(*arguments)
    end

    def destroy
      raise "Destroying users is not supported"
    end

    def save
      if new?
        raise "Creating users is not supported"
      else
        raise "Updating users is not supported"
      end
    end
  end
end

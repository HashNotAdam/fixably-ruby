# frozen_string_literal: true

module Fixably
  class Device < ApplicationResource
    actions %i[create list show]

    validates :name, presence: true
    validate :either_serial_number_or_imei_set

    schema do
      string :serial_number
      string :imei_number1
      string :imei_number2
      string :name
      string :configuration
      string :brand
      string :purchase_country
      date :purchase_date
    end

    def either_serial_number_or_imei_set
      return if serial_number.present? || imei_number1.present?

      errors.add(:base, "Either serial number or IMEI must be present")
    end
  end
end

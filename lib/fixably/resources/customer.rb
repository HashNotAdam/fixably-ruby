# frozen_string_literal: true

module Fixably
  class Customer < ApplicationResource
    actions %i[create list show update]

    validate :either_email_or_phone_set

    schema do
      string :first_name
      string :last_name
      string :company
      string :phone
      string :email
      string :business_id
      string :language
      string :provider
      string :identifier
    end

    has_one :billing_address, class_name: "fixably/customer/billing_address"
    has_one :shipping_address, class_name: "fixably/customer/shipping_address"

    has_many :children, class_name: "fixably/customer/child"

    def either_email_or_phone_set
      return if email.present? || phone.present?

      errors.add(:base, "Either email or phone must be present")
    end

    def remove_on_encode = %w[tags]

    class ShippingAddress < ApplicationResource
      schema do
        string :name
        string :address1
        string :address2
        string :address3
        string :zip
        string :city
        string :state
        string :country
      end
    end

    class BillingAddress < ApplicationResource
      schema do
        string :name
        string :address1
        string :address2
        string :address3
        string :zip
        string :city
        string :state
        string :country
      end
    end

    class Child < Customer
      actions %i[show]
    end
  end
end

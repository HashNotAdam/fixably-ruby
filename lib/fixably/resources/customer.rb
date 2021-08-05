# frozen_string_literal: true

module Fixably
  class Customer < ApplicationResource
    actions %i[create list show]

    validate :either_email_or_phone_set

    schema do
      integer :id
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

    has_many :children, class_name: "fixably/customer"

    def either_email_or_phone_set
      return if email.present? || phone.present?

      errors.add(:base, "Either email or phone must be present")
    end

    def encode(options = nil, attrs: nil)
      attrs ||= attributes
      attrs.delete("tags")

      super(options, attrs: attrs)
    end

    class ShippingAddress < ApplicationResource
      schema do
        integer :id
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
        integer :id
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

    class Children < Customer
      class << self
        protected

        def site_url
          base_url = super
          self.site = "#{base_url}/customers/:customer_id"
        end
      end
    end
  end
end

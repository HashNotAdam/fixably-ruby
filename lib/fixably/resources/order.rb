# frozen_string_literal: true

module Fixably
  class Order < ApplicationResource
    actions %i[create list show]

    schema do
      string :internal_location
      boolean :is_draft
      string :reference
    end

    has_one :contact, class_name: "fixably/order/contact"
    has_one :customer, class_name: "fixably/customer"
    has_one :device, class_name: "fixably/device"
    has_one :handled_by, class_name: "fixably/customer"
    has_one :location, class_name: "fixably/location"
    has_one :ordered_by, class_name: "fixably/customer"
    has_one :queue, class_name: "fixably/queue"
    has_one :status, class_name: "fixably/status"

    has_many :lines, class_name: "fixably/order/line"
    has_many :notes, class_name: "fixably/order/note"
    has_many :tasks, class_name: "fixably/order/task"

    # TODO
    # has_one :store

    ALLOWED_INTERNAL_LOCATIONS =
      %w[CUSTOMER DEALER_SHOP IN_TRANSIT SERVICE STORE].freeze

    validates(
      :internal_location,
      inclusion: {
        in: ALLOWED_INTERNAL_LOCATIONS,
        message: "should be one of " + # rubocop:disable Style/StringConcatenation
          ALLOWED_INTERNAL_LOCATIONS.to_sentence(last_word_connector: " or "),
      },
      allow_nil: true
    )

    protected

    def remove_has_many_associations(attrs)
      reflections.select { |_, reflection| reflection.macro.equal?(:has_many) }.
        keys.
        reject { _1.equal?(:notes) }.
        each { attrs.delete(_1) }
    end

    class Contact < ApplicationResource
      schema do
        string :full_name
        string :company
        string :phone_number
        string :email_address
      end
    end

    class Line < ApplicationResource
      actions %i[list show]
    end

    class Note < ApplicationResource
      actions %i[create list show]

      ALLOWED_TYPES = %w[DIAGNOSIS INTERNAL ISSUE RESOLUTION].freeze

      validates(
        :type,
        inclusion: {
          in: ALLOWED_TYPES,
          message: "should be one of " \
                   "#{ALLOWED_TYPES.to_sentence(last_word_connector: " or ")}",
        }
      )

      schema do
        string :title
        string :text
        string :type
      end

      has_one :created_by, class_name: "fixably/user"
    end

    class Task < ApplicationResource
      actions %i[list show]
    end
  end
end

# frozen_string_literal: true

require_relative "resource"

module Tesla
  # The user of an account
  # @api public
  class User < Resource
    inspect_with :email
    identified_by :email

    # @!method email
    #   The email address of the user
    #   @api public
    #   @return [String, nil] the email address of the user
    #   @example
    #     user.email
    attribute :email

    # @!method full_name
    #   The full name of the user
    #   @api public
    #   @return [String, nil] the full name of the user
    #   @example
    #     user.full_name
    attribute :full_name

    # @!method profile_image_url
    #   The URL of the profile image of the user
    #   @api public
    #   @return [String, nil] the URL of the profile image of the user
    #   @example
    #     user.profile_image_url
    attribute :profile_image_url
  end
end

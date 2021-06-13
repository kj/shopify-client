# frozen_string_literal: true

module ShopifyClient
  class ResponseUserErrors < ResponseErrors
    class << self
      # @param data [Hash] the complete response data
      #
      # @return [ResponseErrors]
      def from_response_data(data)
        errors = find_user_errors(data) || {}

        return new if errors.empty?

        new(errors.to_h do |error|
          [
            error['field'] ? error['field'].join('.') : '.',
            error['message'],
          ]
        end)
      end

      # Find user errors recursively.
      #
      # @param data [Hash]
      #
      # @return [Hash, nil]
      def find_errors(data)
        data.each do |key, value|
          return value if key == 'userErrors'

          if value.is_a?(Hash)
            errors = find_errors(value)

            return errors if errors
          end
        end

        nil
      end
    end
  end
end

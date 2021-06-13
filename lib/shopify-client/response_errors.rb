# frozen_string_literal: true

module ShopifyClient
  class ResponseErrors
    class << self
      # Certain error responses, such as 'Not Found', use a string rather than
      # an object. For consistency, these messages are set under 'resource'.
      #
      # @param data [Hash] the complete response data
      #
      # @return [ResponseErrors]
      def from_response_data(data)
        errors = data['errors']

        return new if errors.nil?

        errors.is_a?(String) ? new('resource' => errors) : new(errors)
      end
    end

    # @param errors [Hash]
    def initialize(errors = {})
      @errors = errors
    end

    # @return [Array<String]
    def messages
      @errors.map do |field, message|
        "#{message} [#{field}]"
      end
    end

    # message_patterns [Array<Regexp, String>]
    #
    # @return [Boolean]
    def message?(message_patterns)
      message_patterns.any? do |pattern|
        case pattern
        when Regexp
          messages.any? { |message| message.match?(pattern) }
        when String
          messages.include?(pattern)
        end
      end
    end

    include Enumerable

    # @see Hash#each
    def each(...)
      @errors.dup.each(...)
    end

    # @return [Hash]
    def to_h
      @errors.dup
    end
  end
end

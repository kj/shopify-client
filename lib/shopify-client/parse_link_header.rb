# frozen_string_literal: true

require 'addressable'

module ShopifyClient
  class ParseLinkHeader
    # Parse a Link header into query params for each pagination link (e.g.
    # :next, :previous).
    #
    # @param link_header [String]
    #
    # @return [Hash]
    def call(link_header)
      link_header.split(',').map do |link|
        url, rel = link.split(';') # rel should be the first param
        url = url[/<(.*)>/, 1]
        rel = rel[/rel="?(\w+)"?/, 1]

        [
          rel.to_sym,
          params(url),
        ]
      end.to_h
    end

    # @param url [String]
    #
    # @return [Hash]
    private def params(url)
      Addressable::URI.parse(url).query_values
    end
  end
end

# frozen_string_literal: true
# typed: false

require "logger"
require "multi_json"

module Optimistic
  module Json
    ##
    # The main parser class
    class Parser
      ##
      # Raised when there is no parser for a given token
      class MissingParser < StandardError
        #: (tokens: String, ?msg: String?) -> void
        def initialize(tokens:, msg: nil)
          super(msg || "No registered parser for `#{tokens[0]}`: #{tokens}")
          @tokens = tokens
        end
      end

      ##
      # Raised when a supported token is found but is invalid
      class InvalidToken < StandardError
        #: (tokens: String, ?msg: String?) -> void
        def initialize(tokens:, msg: nil)
          super(msg || "Invalid token starting with `#{tokens[0]}`: #{tokens}")
          @tokens = tokens
        end
      end

      TOKENS = {
        space: [" ", "\t", "\r", "\n"],
        array: ["["],
        object: ["{"],
        number: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", ".", "-"],
        string: ['"'],
        true: ["t"],
        false: ["f"],
        null: ["n"]
      }.freeze

      #: Logger
      attr_accessor :logger
      #: Hash[String, Method]
      attr_reader :parsers

      #: (?logger: Logger?) -> void
      def initialize(logger: nil)
        @logger = logger || ::Logger.new($stdout)
        @parsers = setup_parsers
      end

      #: (String tokens) -> untyped
      def parse(tokens)
        ::MultiJson.load(tokens)
      rescue ::MultiJson::ParseError => e
        result = parse_any(tokens, e)

        if result[:remainder].length.positive?
          logger.warn("Unable to parse the following JSON: #{result[:remainder]}")

          handle_remaining_tokens(tokens, result[:data], result[:remainder])
        end

        result[:data]
      end

      #: (String tokens, untyped data, String remaining_tokens) -> void
      def handle_remaining_tokens(tokens, data, remaining_tokens)
        logger.info({ tokens: tokens, data: data, remaining_tokens: remaining_tokens })
      end

      private

      #: () -> Hash[String, Method]
      def setup_parsers
        parsers = {}

        ::Optimistic::Json::Parser::TOKENS.each do |type, tokens|
          tokens.each do |token|
            parsers[token] = method("parse_#{type}")
          end
        end

        parsers
      end

      #: (String tokens, StandardError err) -> { data: untyped, remainder: String }
      def parse_any(tokens, err)
        parser = parsers[tokens[0]]

        raise ::Optimistic::Json::Parser::MissingParser.new(tokens: tokens) unless parser

        parser.call(tokens, err)
      end

      #: (String tokens, StandardError err) -> { data: untyped, remainder: String }
      def parse_space(tokens, err)
        tokens = tokens.lstrip
        parse_any(tokens, err)
      end

      #: (String tokens, StandardError err) -> { data: Array[untyped], remainder: String }
      def parse_array(tokens, err)
        # Skip the opening bracket & remove any spaces
        tokens = tokens[1..].lstrip

        data = []

        while tokens.length.positive?
          # Skip the closing bracket
          if tokens[0] == "]"
            tokens = tokens[1..]
            break
          end

          result = parse_any(tokens, err)
          data << result[:data]

          tokens = result[:remainder].lstrip

          # Skip the comma
          tokens = tokens[1..].lstrip if tokens[0] == ","
        end

        { data: data, remainder: tokens }
      end

      #: (String tokens, StandardError err) -> { data: Hash[String, untyped], remainder: String }
      def parse_object(tokens, err)
        tokens = tokens[1..].lstrip
        data = {}

        while tokens.length.positive?
          # Skip the closing brace
          if tokens[0] == "}"
            tokens = tokens[1..]
            break
          end

          # Parse the key
          result = parse_any(tokens, err)
          key = result[:data]
          tokens = result[:remainder].lstrip

          # Skip the colon
          tokens = tokens[1..].lstrip

          # Parse the value
          result = parse_any(tokens, err)
          tokens = result[:remainder].lstrip

          # Set the key/value pair
          data[key] = result[:data]

          # Skip the comma
          tokens = tokens[1..].lstrip if tokens[0] == ","
        end

        { data: data, remainder: tokens }
      end

      #: (String tokens, StandardError _err) -> { data: (Integer | Float | String), remainder: String }
      def parse_number(tokens, _err)
        i = 0
        while i < tokens.length
          current = tokens[i]
          if parsers[current] == method(:parse_number)
            i += 1
            next
          end

          num = tokens[0...i]
          tokens = tokens[i..]

          return { data: number_or_tokens(num), remainder: tokens }
        end

        { data: number_or_tokens(tokens), remainder: "" }
      end

      #: (String tokens) -> (Integer | Float | String)
      def number_or_tokens(tokens)
        return 0 if tokens == "-"

        if tokens.include?(".")
          # Drop trailing dot and parse as float (e.g. "12." => 12.0)
          tokens.end_with?(".") ? Float(tokens[0...-1]) : Float(tokens)
        else
          Integer(tokens)
        end
      rescue ::ArgumentError
        logger.error("Unable to parse number: #{tokens}")
        tokens
      end

      #: (String tokens, StandardError _err) -> { data: String, remainder: String }
      def parse_string(tokens, _err)
        i = 1
        while i < tokens.length
          current = tokens[i]
          if current == "\\"
            i += 2
            next
          end

          if current == '"'
            str = tokens[0..i]
            tokens = tokens[(i + 1)..]

            return { data: ::MultiJson.load(str), remainder: tokens }
          end

          i += 1
        end

        { data: ::MultiJson.load("#{tokens}\""), remainder: "" }
      end

      #: (String tokens, StandardError err) -> { data: TrueClass, remainder: String }
      def parse_true(tokens, err)
        parse_token(tokens, "true", true, err)
      end

      #: (String tokens, StandardError err) -> { data: FalseClass, remainder: String }
      def parse_false(tokens, err)
        parse_token(tokens, "false", false, err)
      end

      #: (String tokens, StandardError err) -> { data: nil, remainder: String }
      def parse_null(tokens, err)
        parse_token(tokens, "null", nil, err)
      end

      #: [T] (String tokens, String token_str, T token_val, StandardError _err) -> { data: T, remainder: String }
      def parse_token(tokens, token_str, token_val, _err)
        i = token_str.length

        while i >= 1
          return { data: token_val, remainder: tokens[i..] } if tokens.start_with?(token_str.slice(0, i))

          i -= 1
        end

        raise ::Optimistic::Json::Parser::InvalidToken.new(tokens: tokens)
      end
    end
  end
end

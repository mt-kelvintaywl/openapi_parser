class OpenAPIParser::SchemaValidator
  class StringValidator < Base
    include ::OpenAPIParser::SchemaValidator::Enumable

    def initialize(validator, coerce_value, datetime_coerce_class)
      super(validator, coerce_value)
      @datetime_coerce_class = datetime_coerce_class
    end

    def coerce_and_validate(value, schema, **_keyword_args)
      return OpenAPIParser::ValidateError.build_error_result(value, schema) unless value.kind_of?(String)

      value, err = check_enum_include(value, schema)
      return [nil, err] if err

      value, err = pattern_validate(value, schema)
      return [nil, err] if err

      unless @datetime_coerce_class.nil?
        value, err = coerce_date_time(value, schema)
        return [nil, err] if err
      end

      [value, nil]
    end

    private

      # @param [OpenAPIParser::Schemas::Schema] schema
      def coerce_date_time(value, schema)
        return parse_date_time(value, schema) if ['date-time', 'date'].include?(schema.format)

        [value, nil]
      end

      def parse_date_time(value, schema)
        begin
          return @datetime_coerce_class.parse(value), nil
        rescue ArgumentError => e
          raise e unless e.message =~ /invalid date/
        end

        OpenAPIParser::ValidateError.build_error_result(value, schema)
      end

      # @param [OpenAPIParser::Schemas::Schema] schema
      def pattern_validate(value, schema)
        # pattern support string only so put this
        return [value, nil] unless schema.pattern
        return [value, nil] if value =~ /#{schema.pattern}/

        [nil, OpenAPIParser::InvalidPattern.new(value, schema.pattern, schema.object_reference)]
      end
  end
end

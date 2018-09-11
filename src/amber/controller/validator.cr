class Hash(K, V)
  # Fetch *key* or set it to *value*.
  #
  # ```
  # h = {"foo" => "bar"}
  # h.fetch_or_set("foo", "baz"); pp h
  # # {"foo" => "bar"}
  # h.fetch_or_set("bar", "baz"); pp h
  # # {"foo" => "bar", "bar" => "baz"}
  # ```
  def fetch_or_set(key, value)
    if has_key?(key)
      self.[key]
    else
      self.[key] = value
    end
  end
end

module Validator
  VERSION           = "0.1.0"
  TYPES             = [Nil, String, Bool, Int32, Int64, Float32, Float64, Time, Bytes]
  TIME_FORMAT_REGEX = /\d{4,}-\d{2,}-\d{2,}\s\d{2,}:\d{2,}:\d{2,}/
  DATETIME_FORMAT   = "%F %X%z"

  # `Any` is a union of all types in `TYPES`
  {% begin %}
    alias Any = Union({{*TYPES}})
  {% end %}

  # Gently check if the including type is valid.
  def valid?
    validate
    errors.empty?
  end

  # Roughly check if the including type is valid, raising `Error` otherwise.
  def valid!
    valid? || raise Error.new(errors)
  end

  getter errors = Hash(String, Array(String)).new

  # Raised when the including type has validation errorss after calling `valid!`.
  class Error < Exception
    # A hash of invalid attributes, similar to `Validations#errors`.
    getter errors : Hash(String, Array(String))

    def initialize(@errors)
    end
  end

  macro included
    CONTENT_FIELDS = {} of Nil => Nil
    FIELD_OPTIONS = {} of Nil => Nil

    def initialize(**args : Object)
      set_attributes(args.to_h)
    end

    def initialize(args : Hash(Symbol | String, Any))
      set_attributes(args)
    end

    def initialize(args : HTTP::Params)
      set_attributes(args)
    end

    def initialize
    end

    {% unless @type.has_method?("validate") %}
      # Run validations, clearing `#errors` before.
      def validate
        errors.clear
      end
    {% end %}
    macro finished
      __process_params
    end
  end

  macro invalidate(attribute, message)
    errors.fetch_or_set({{attribute}}, Array(String).new).push({{message}})
  end

  macro param(attribute, **options)
    {% FIELD_OPTIONS[attribute.var] = options %}
    {% CONTENT_FIELDS[attribute.var] = options || {} of Nil => Nil %}
    {% CONTENT_FIELDS[attribute.var][:type] = attribute.type %}
  end

  macro param!(attribute, **options)
    param {{attribute}}, {{options.double_splat(", ")}}raise_on_nil: true
  end

  private macro __process_params
    def set_attributes(args : Hash(String | Symbol, Any))
      args.each do |k, v|
        cast(k, v.as(Any))
      end
    end

    def set_attributes(**args)
      set_attributes(args.to_h)
    end

    {% for name, options in FIELD_OPTIONS %}
      {% type = options[:type] %}
      {% property_name = name.id %}
      {% suffixes = options[:raise_on_nil] ? ["?", ""] : ["", "!"] %}
      {% if options[:json_options] %}
         @[JSON::Field({{**options[:json_options]}})]
      {% end %}
      {% if options[:yaml_options] %}
         @[YAML::Field({{**options[:yaml_options]}})]
      {% end %}

      {% if options[:comment] %}
         {{options[:comment].id}}
      {% end %}
      property{{suffixes[0].id}} {{name.id}} : Union({{type.id}} | Nil)

      def {{name.id}}{{suffixes[1].id}}
        raise {{@type.name.stringify}} + "#" + {{name.stringify}} + " cannot be nil" if @{{name.id}}.nil?
        @{{name.id}}.not_nil!
      end

      def {{property_name}}{{suffixes[1].id}}
        raise {{@type.name.stringify}} + "#" + {{property_name.stringify}} + " cannot be nil" if @{{property_name}}.nil?
        @{{property_name}}.not_nil!
      end
    {% end %}

    private def cast(name, value : Any)
      {% unless CONTENT_FIELDS.empty? %}
        case name.to_s
          {% for _name, _options in CONTENT_FIELDS %}
            {% type = _options[:type] %}
          when "{{_name.id}}"

            return @{{_name.id}} = nil if value.nil?
            {% if type.id == Int32.id %}
              @{{_name.id}} = value.is_a?(String) ? value.to_i32(strict: false) : value.is_a?(Int64) ? value.to_i32 : value.as(Int32)
            {% elsif type.id == Int64.id %}
              @{{_name.id}} = value.is_a?(String) ? value.to_i64(strict: false) : value.as(Int64)
            {% elsif type.id == Float32.id %}
              @{{_name.id}} = value.is_a?(String) ? value.to_f32(strict: false) : value.is_a?(Float64) ? value.to_f32 : value.as(Float32)
            {% elsif type.id == Float64.id %}
              @{{_name.id}} = value.is_a?(String) ? value.to_f64(strict: false) : value.as(Float64)
            {% elsif type.id == Bool.id %}
              @{{_name.id}} = ["1", "yes", "true", true].includes?(value)
            {% elsif type.id == Time.id %}
              if value.is_a?(Time)
                @{{_name.id}} = value
              elsif value.to_s =~ TIME_FORMAT_REGEX
                @{{_name.id}} = Time.parse_utc(value.to_s, DATETIME_FORMAT)
              end
            {% else %}
              @{{_name.id}} = value.to_s
            {% end %}
          {% end %}
        end
      {% end %}
    end

    def validate
      previous_def
      {% for name, options in FIELD_OPTIONS %}
        {% property_name = name.id %}
        unless {{property_name}}.nil?
          value = {{property_name}}.not_nil!

          {% if options[:is] %}
            invalidate({{property_name.stringify}}, "must be equal to {{options[:is]}}") unless value == {{options[:is]}}
          {% end %}

          {% if options[:gte] %}
            invalidate({{property_name.stringify}}, "must be greater than or equal to {{options[:gte]}}") unless value >= {{options[:gte]}}
          {% end %}

          {% if options[:lte] %}
            invalidate({{property_name.stringify}}, "must be less than or equal to {{options[:lte]}}") unless value <= {{options[:lte]}}
          {% end %}

          {% if options[:gt] %}
            invalidate({{property_name.stringify}}, "must be greater than {{options[:gt]}}") unless value > {{options[:gt]}}
          {% end %}

          {% if options[:lt] %}
            invalidate({{property_name.stringify}}, "must be less than {{options[:lt]}}") unless value < {{options[:lt]}}
          {% end %}

          {% if options[:in] %}
            invalidate({{property_name.stringify}}, "must be in {{options[:in]}}") unless {{options[:in]}}.includes?(value)
          {% end %}

          {% if options[:size] %}
            invalidate({{property_name.stringify}}, "must have size in {{options[:size]}}") unless {{options[:size]}}.includes?(value.size)
          {% end %}

          {% if options[:regex] %}
            invalidate({{property_name.stringify}}, "must match " + {{options[:regex].stringify}}) unless ({{options[:regex]}}).match(value)
          {% end %}
        end
      {% end %}
    end
  end
end

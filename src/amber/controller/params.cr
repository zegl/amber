module Controller::Params
  alias Key = String | Symbol
  TYPES = [Nil, String, Bool, Int32, Int64, Float32, Float64, Time, Bytes]

  {% begin %}
    alias Any = Union({{*TYPES}})
  {% end %}

  macro included
    CONTENT_FIELDS = {} of Nil => Nil
    FIELDS = {} of Nil => Nil
  end

  macro param(decl, **options)
    {% CONTENT_FIELDS[decl.var] = options || {} of Nil => Nil %}
    {% CONTENT_FIELDS[decl.var][:type] = decl.type %}
  end

  # specify the raise-on-nil fields you want to define and types
  macro param!(decl, **options)
    param {{decl}}, {{options.double_splat(", ")}}raise_on_nil: true
  end

  macro __process_fields(class_name)
    class {{class_name}}Params
      # Create the properties
      {% for name, options in FIELDS %}
        {% type = options[:type] %}
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
      {% end %}

      # keep a hash of the fields to be used for mapping
      def self.fields : Array(String)
        @@fields ||= {{ FIELDS.empty? ? "[] of String".id : FIELDS.keys.map(&.id.stringify) }}
      end

      def self.content_fields : Array(String)
        @@content_fields ||= {{ CONTENT_FIELDS.empty? ? "[] of String".id : CONTENT_FIELDS.keys.map(&.id.stringify) }}
      end

      # keep a hash of the params that will be passed to the adapter.
      def values
        parsed_params = [] of Any
        {% for name, options in CONTENT_FIELDS %}
          parsed_params << {{name.id}}
        {% end %}
        return parsed_params
      end

      def to_h
        fields = {} of String => Params::Any

        {% for name, options in FIELDS %}
          {% type = options[:type] %}
          {% if type.id == Time.id %}
            fields["{{name}}"] = {{name.id}}.try(&.to_s(Granite::DATETIME_FORMAT))
          {% elsif type.id == Slice.id %}
            fields["{{name}}"] = {{name.id}}.try(&.to_s(""))
          {% else %}
            fields["{{name}}"] = {{name.id}}
          {% end %}
        {% end %}

        return fields
      end

      def [](name : Params::Key) : Params::Any
        {% begin %}
          case name.to_s
          {% for name, options in FIELDS %}
            when "{{ name }}" then @{{ name.id }}
          {% end %}
          else
            raise "Cannot read attribute #{name}, invalid attribute"
          end
        {% end %}
      end

      def set_attributes(args : Hash(String | Symbol, Type))
        args.each do |k, v|
          cast_to_field(k, v.as(Type))
        end
      end

      # Casts params and sets fields
      # Casts params and sets fields
      private def cast_to_field(name, value : Type)
        {% unless FIELDS.empty? %}
          case name.to_s
            {% for _name, options in FIELDS %}
              {% type = options[:type] %}
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
                  @{{_name.id}} = Time.parse_utc(value.to_s, Granite::DATETIME_FORMAT)
                end
              {% else %}
                @{{_name.id}} = value.to_s
              {% end %}
            {% end %}
          end
        {% end %}
      rescue ex
        errors << Granite::Error.new(name, ex.message)
      end
    end 
  end
end
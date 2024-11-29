module Gemini
  # A datatype containing media that is part of a multi-part `Content` message.
  #
  # Union field `data`. `data` can be only one of the following:
  #
  # * **text**: string - Inline text.
  # * **inlineData**: object (Blob) - Inline media bytes.
  # * **functionCall**: object (FunctionCall) - A predicted FunctionCall returned from the model that contains a string
  #   representing the `FunctionDeclaration#name` with the arguments and their values.
  # * **functionResponse**: object (FunctionResponse) - The result output of a `FunctionCall` that contains a string
  #   representing the `FunctionDeclaration#name` and a structured JSON object containing any output from the function
  #   is used as context to the model.
  # * **fileData**: object (FileData) - URI based data.
  # * **executableCode**: object (ExecutableCode) - Code generated by the model that is meant to be executed.
  # * **codeExecutionResult**: object (CodeExecutionResult) - Result of executing the ExecutableCode.
  #
  # See: https://ai.google.dev/api/caching#Part
  struct Part
    def initialize(@data)
    end

    macro one_of(name)
          def {{name.var.id}} : {{name.type}}
            @{{name.var.id}}
          end

          def {{name.var.id}}=(@{{name.var.id}} : {{name.type}})
          end

          {% for type in name.type.types.map(&.stringify) %}
            {% field = type.underscore %}

            # if `#data` type is `{{ type.id }}` will return value, or nil if not
            def {{field.id}}?
              data.as({{type.id}}) if data.is_a?({{type.id}})
            end

            # Do not yield if `#data` is a diferent type
            def {{field.id}}?(&)
              value = {{field.id}}?

              return if value.nil?
              yield value
            end

            # Same as `#{{ field.id }}?` but raise error if nil
            def {{field.id}}
              {{field.id}}?.not_nil!
            end
          {% end %}

          # Custom JSON deserializable
          def initialize(pull : JSON::PullParser)
            pull.read_begin_object
            {% begin %}
              case key = pull.read_object_key
              {% for type in name.type.types.map(&.stringify) %}
                when {{type.camelcase(lower: true)}}
                {% if type.downcase == "text" %}
                  @data = pull.read_string.rstrip
                {% else %}
                  @data = {{type.id}}.from_json(pull.read_raw)
                {% end %}
              {% end %}
              else
                raise "eloquent -- Undefined #{self.class} JSON field: #{key}"
              end
            {% end %}
            pull.read_end_object
          end
        end

    # Custom JSON serializable
    def to_json(json : JSON::Builder)
      json.object do
        if text = text?
          json.field "text", text
        else
          json.field data.to_json_object_key do
            data.to_json(json)
          end
        end
      end
    end

    one_of data : (Text | FunctionCall | FunctionResponse)
  end

  # The base structured datatype containing multi-part content of a message.
  #
  # See: https://ai.google.dev/api/caching#Content
  struct Content
    include JSON::Serializable
    # The producer of the content. *(Optional)*
    property role : Role?
    # Ordered Parts that constitute a single message.
    # Parts may have different MIME types.
    property parts : Array(Part)

    # Create using existing parts or new empty array
    def initialize(@parts = [] of Part, @role = nil)
    end

    # Create content with a single part
    def initialize(part : Part, @role = nil)
      @parts = [part]
    end

    # Create content with a text part already
    def initialize(text : String, @role = nil)
      initialize(Part.new(text), @role)
    end

    # Remove empty texts `Part` from JSON to fix: "Unable to submit request because it has an empty text parameter."
    def after_initialize
      @parts.select! do |part|
        !(part.text? && part.text? &.empty?)
      end
    end

    enum Role
      User
      Model
      Function
    end
  end

  # The Schema object allows the definition of input and output data types. These types can be objects, but also
  # primitives and arrays. Represents a select subset of an OpenAPI 3.0 schema object.
  #
  # See: https://ai.google.dev/api/caching#Schema
  class Schema
    include JSON::Serializable
    # Data type. *(Required)*
    property type : Type
    # The format of the data. *(Optional)*
    # Supported formats:
    # * **NUMBER**: float, double
    # * **INTEGER**: int32, int64
    # * **STRING**: enum
    property format : String?
    # A brief description of the parameter. This could contain examples of use. Parameter description may be formatted
    # as Markdown. *(Optional)*
    property description : String?
    # Indicates if the value may be null. *(Optional)*
    property? nullable : Bool?
    # Possible values of the element of `Type::STRING` with enum format. For example we can define an Enum Direction as:
    #
    # ```
    # {
    #   type: STRING,
    #   format: enum,
    #   enum: ["EAST", NORTH", "SOUTH", "WEST"]
    # }
    # ```
    # *(Optional)*
    @[JSON::Field(key: "enum")]
    property enumeration : Array(String)?
    # Maximum number of the elements for `Type::ARRAY`. *(Optional)*
    @[JSON::Field(key: "maxItems")]
    property max_items : String?
    # Minimum number of the elements for `Type::ARRAY`. *(Optional)*
    @[JSON::Field(key: "minItems")]
    property min_items : String?
    # Properties of `Type`. *(Optional)*
    property properties : Hash(String, Schema)?
    # Required properties of `Type`. *(Optional)*
    property required : Array(String)?
    # Schema of the elements of `Type::ARRAY`. *(Optional)*
    property items : Schema?

    def initialize(
      @type,
      @format = nil,
      @description = nil,
      @nullable = nil,
      @enumeration = nil,
      @max_items = nil,
      @min_items = nil,
      @properties = nil,
      @required = nil,
      @items = nil
    )
    end

    # Type contains the list of OpenAPI data types as defined by https://spec.openapis.org/oas/v3.0.3#data-types
    enum Type
      TYPE_UNSPECIFIED # Not specified, should not be used.
      STRING           # String type.
      NUMBER           # Number type.
      INTEGER          # Integer type.
      BOOLEAN          # Boolean type.
      ARRAY            # Array type.
      OBJECT           # Object type.
    end
  end

  # Defines the reason why the model stopped generating tokens.
  #
  # See: https://ai.google.dev/api/generate-content#FinishReason
  enum FinishReason
    FINISH_REASON_UNSPECIFIED # Default value. This value is unused.
    STOP                      # Natural stop point of the model or provided stop sequence.
    MAX_TOKENS                # The maximum number of tokens as specified in the request was reached.
    SAFETY                    # The response candidate content was flagged for safety reasons.
    RECITATION                # The response candidate content was flagged for recitation reasons.
    LANGUAGE                  # The response candidate content was flagged for using an unsupported language.
    OTHER                     # Unknown reason.
    BLOCKLIST                 # Token generation stopped because the content contains forbidden terms.
    PROHIBITED_CONTENT        # Token generation stopped for potentially containing prohibited content.
    SPII                      # Token generation stopped because the content potentially contains SPII.
    MALFORMED_FUNCTION_CALL   # The function call generated by the model is invalid.
  end

  # `Part` inline text data type
  alias Text = String

  # The category of a rating.
  #
  # See: https://ai.google.dev/api/generate-content#harmcategory
  enum HarmCategory
    HARM_CATEGORY_UNSPECIFIED       # Category is unspecified.
    HARM_CATEGORY_DEROGATORY        # PaLM - Negative or harmful comments targeting identity and/or protected attr.
    HARM_CATEGORY_TOXICITY          # PaLM - Content that is rude, disrespectful, or profane.
    HARM_CATEGORY_VIOLENCE          # PaLM - Describes scenarios depicting violence against an individual or group.
    HARM_CATEGORY_SEXUAL            # PaLM - Contains references to sexual acts or other lewd content.
    HARM_CATEGORY_MEDICAL           # PaLM - Promotes unchecked medical advice.
    HARM_CATEGORY_DANGEROUS         # PaLM - Promotes, facilitates or encourages harmful acts.
    HARM_CATEGORY_HARASSMENT        # Gemini - Harassment content.
    HARM_CATEGORY_HATE_SPEECH       # Gemini - Hate speech and content.
    HARM_CATEGORY_SEXUALLY_EXPLICIT # Gemini - Sexually explicit content.
    HARM_CATEGORY_DANGEROUS_CONTENT # Gemini - Dangerous content.
    HARM_CATEGORY_CIVIC_INTEGRITY   # Gemini - Content that may be used to harm civic integrity.
  end

  # Block at and beyond a specified harm probability.
  #
  # See: https://ai.google.dev/api/generate-content#HarmBlockThreshold
  enum HarmBlockThreshold
    HARM_BLOCK_THRESHOLD_UNSPECIFIED # Threshold is unspecified.
    BLOCK_LOW_AND_ABOVE              # Content with NEGLIGIBLE will be allowed.
    BLOCK_MEDIUM_AND_ABOVE           # Content with NEGLIGIBLE and LOW will be allowed.
    BLOCK_ONLY_HIGH                  # Content with NEGLIGIBLE, LOW, and MEDIUM will be allowed.
    BLOCK_NONE                       # All content will be allowed.
    OFF                              # Turn off the safety filter.
  end

  # The probability that a piece of content is harmful.
  #
  # See: https://ai.google.dev/api/generate-content#HarmProbability
  enum HarmProbability
    HARM_PROBABILITY_UNSPECIFIED # Probability is unspecified.
    NEGLIGIBLE                   # Content has a negligible chance of being unsafe.
    LOW                          # Content has a low chance of being unsafe.
    MEDIUM                       # Content has a medium chance of being unsafe.
    HIGH                         # Content has a high chance of being unsafe.
  end

  # Specifies the reason why the prompt was blocked.
  #
  # See: https://ai.google.dev/api/generate-content#BlockReason
  enum BlockReason
    BLOCK_REASON_UNSPECIFIED # Default value. This value is unused.
    SAFETY                   # Prompt was blocked due to safety reasons.
    OTHER                    # Prompt was blocked due to unknown reasons.
    BLOCKLIST                # Prompt was blocked due to the terms which are included from the blocklist.
    PROHIBITED_CONTENT       # Prompt was blocked due to prohibited content.
  end

  # Safety rating for a piece of content.
  #
  # See: https://ai.google.dev/api/generate-content#safetyrating
  struct SafetyRating
    include JSON::Serializable
    getter category : HarmCategory
    getter probability : HarmProbability
    getter? blocked = false

    def initialize(@category, @probability)
    end
  end

  # Safety setting, affecting the safety-blocking behavior.
  #
  # See: https://ai.google.dev/api/generate-content#safetysetting
  struct SafetySetting
    include JSON::Serializable
    getter category : HarmCategory
    getter threshold : HarmBlockThreshold

    def initialize(@category, @threshold)
    end
  end

  # Simplified error response
  struct Error
    include JSON::Serializable
    getter code : Int32
    getter message : String
    getter status : String
  end
end

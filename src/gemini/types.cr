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
      property {{name.var.id}} : {{name.type}}

      {% for type in name.type.types.map(&.stringify) %}
        {% field = type.underscore %}

        # if `#{{name.var.id}}` type is `{{type.id}}` will return value, or nil if not
        def {{field.id}}?
          {{name.var.id}}.as({{type.id}}) if {{name.var.id}}.is_a?({{type.id}})
        end

        # Do not yield if `#{{name.var.id}}` is a diferent type
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
      def initialize(pull : ::JSON::PullParser)
        location = pull.location

        pull.read_begin_object
        case key = pull.read_object_key
          {% for type in name.type.types.map(&.stringify) %}
            when {{type.camelcase(lower: true)}}
              {% if type.downcase == "text" %}
                @{{name.var.id}} = pull.read_string.rstrip
              {% else %}
                @{{name.var.id}} = {{type.id}}.from_json(pull.read_raw)
              {% end %}
          {% end %}
        else
          raise ::JSON::SerializableError.new("Unknown one of type: #{key}", {{@type.id.stringify}}, key, *location, nil)
        end
        pull.read_end_object
      end
    end

    # Custom JSON serializable
    def to_json(json : ::JSON::Builder)
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
    # Possible values of the element of `Type::String` with enum format. For example we can define an Enum Direction as:
    #
    # ```
    # Schema.new(
    #   type: :string,
    #   format: "enum",
    #   enum: ["EAST", NORTH", "SOUTH", "WEST"]
    # )
    # ```
    # *(Optional)*
    @[JSON::Field(key: "enum")]
    property enumeration : Array(String)?
    # Maximum number of the elements for `Type::Array`. *(Optional)*
    @[JSON::Field(key: "maxItems")]
    property max_items : String?
    # Minimum number of the elements for `Type::Array`. *(Optional)*
    @[JSON::Field(key: "minItems")]
    property min_items : String?
    # Properties of `Type`. *(Optional)*
    property properties : Hash(String, Schema)?
    # Required properties of `Type`. *(Optional)*
    property required : Array(String)?
    # Schema of the elements of `Type::Array`. *(Optional)*
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
      TypeUnspecified # Not specified, should not be used.
      String          # String type.
      Number          # Number type.
      Integer         # Integer type.
      Boolean         # Boolean type.
      Array           # Array type.
      Object          # Object type.
    end
  end

  # Defines the reason why the model stopped generating tokens.
  #
  # See: https://ai.google.dev/api/generate-content#FinishReason
  enum FinishReason
    FinishReasonUnspecified # Default value. This value is unused.
    Stop                    # Natural stop point of the model or provided stop sequence.
    MaxTokens               # The maximum number of tokens as specified in the request was reached.
    Safety                  # The response candidate content was flagged for safety reasons.
    Recitation              # The response candidate content was flagged for recitation reasons.
    Language                # The response candidate content was flagged for using an unsupported language.
    Other                   # Unknown reason.
    Blocklist               # Token generation stopped because the content contains forbidden terms.
    ProhibitedContent       # Token generation stopped for potentially containing prohibited content.
    SPII                    # Token generation stopped because the content potentially contains SPII.
    MalformedFunctionCall   # The function call generated by the model is invalid.
  end

  # `Part` inline text data type
  alias Text = String

  # The category of a rating.
  #
  # See: https://ai.google.dev/api/generate-content#harmcategory
  enum HarmCategory
    HarmCategoryUnspecified      # Category is unspecified.
    HarmCategoryDerogatory       # PaLM - Negative or harmful comments targeting identity and/or protected attr.
    HarmCategoryToxicity         # PaLM - Content that is rude, disrespectful, or profane.
    HarmCategoryViolence         # PaLM - Describes scenarios depicting violence against an individual or group.
    HarmCategorySexual           # PaLM - Contains references to sexual acts or other lewd content.
    HarmCategoryMedical          # PaLM - Promotes unchecked medical advice.
    HarmCategoryDangerous        # PaLM - Promotes, facilitates or encourages harmful acts.
    HarmCategoryHarassment       # Gemini - Harassment content.
    HarmCategoryHateSpeech       # Gemini - Hate speech and content.
    HarmCategorySexuallyExplicit # Gemini - Sexually explicit content.
    HarmCategoryDangerousContent # Gemini - Dangerous content.
    HarmCategoryCivicIntegrity   # Gemini - Content that may be used to harm civic integrity.
  end

  # Block at and beyond a specified harm probability.
  #
  # See: https://ai.google.dev/api/generate-content#HarmBlockThreshold
  enum HarmBlockThreshold
    HarmBlockThresholdUnspecified # Threshold is unspecified.
    BlockLowAndAbove              # Content with NEGLIGIBLE will be allowed.
    BlockMediumAndAbove           # Content with NEGLIGIBLE and LOW will be allowed.
    BlockOnlyHigh                 # Content with NEGLIGIBLE, LOW, and MEDIUM will be allowed.
    BlockNone                     # All content will be allowed.
    Off                           # Turn off the safety filter.
  end

  # The probability that a piece of content is harmful.
  #
  # See: https://ai.google.dev/api/generate-content#HarmProbability
  enum HarmProbability
    HarmProbabilityUnspecified # Probability is unspecified.
    Negligible                 # Content has a negligible chance of being unsafe.
    Low                        # Content has a low chance of being unsafe.
    Medium                     # Content has a medium chance of being unsafe.
    High                       # Content has a high chance of being unsafe.
  end

  # Specifies the reason why the prompt was blocked.
  #
  # See: https://ai.google.dev/api/generate-content#BlockReason
  enum BlockReason
    BlockReasonUnspecified # Default value. This value is unused.
    Safety                 # Prompt was blocked due to safety reasons.
    Other                  # Prompt was blocked due to unknown reasons.
    Blocklist              # Prompt was blocked due to the terms which are included from the blocklist.
    ProhibitedContent      # Prompt was blocked due to prohibited content.
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

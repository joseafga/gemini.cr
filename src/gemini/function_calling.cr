module Gemini
  # Tool details that the model may use to generate response.
  #
  # [API Reference](https://ai.google.dev/api/caching#Tool)
  struct Tool
    include JSON::Serializable
    # A list of `FunctionDeclarations` available to the model that can be used for function calling. *(Optional)*
    @[JSON::Field(key: "functionDeclarations")]
    property function_declarations : Array(FunctionDeclaration)?

    # Enables the model to execute code as part of generation. *(Optional)*
    # @[JSON::Field(key: "codeExecution")]
    # TODO: property code_execution : CodeExecution

    def initialize(@function_declarations = nil)
    end
  end

  # Structured representation of a function declaration as defined by the OpenAPI 3.03 specification.
  #
  # [API Reference](https://ai.google.dev/api/caching#FunctionDeclaration)
  struct FunctionDeclaration
    include JSON::Serializable
    # The name of the function. *(Required)*
    property name : String
    # A brief description of the function. *(Required)*
    property description : String
    # Describes the parameters to this function. *(Optional)*
    property parameters : Schema?

    def initialize(@name, @description, @parameters = nil)
    end

    def initialize(@name, @description, parameters : NamedTuple)
      @parameters = Schema.new(**parameters)
    end
  end

  # A predicted `FunctionCall` returned from the model that contains a string representing the `FunctionDeclaration#name`
  # with the arguments and their values.
  struct FunctionCall
    include JSON::Serializable
    # The name of the function to call. *(Required)*
    getter name : String
    # The function parameters and values in JSON object format. *(Optional)*
    getter args : JSON::Any?

    def to_json_object_key
      "functionCall"
    end
  end

  # This should contain the result of a `FunctionCall` made based on model prediction.
  #
  # [API Reference](https://ai.google.dev/api/caching#FunctionResponse)
  struct FunctionResponse
    include JSON::Serializable
    # The name of the function to call. *(Required)*
    property name : String
    # The function response in JSON object format. *(Required)*
    property response : JSON::Any

    def initialize(@name, @response)
    end

    def to_json_object_key
      "functionResponse"
    end
  end

  # The Tool configuration containing parameters for specifying Tool use in the request.
  #
  # [API Reference](https://ai.google.dev/api/caching#ToolConfig)
  struct ToolConfig
    include JSON::Serializable
    # Function calling config. *(Optional)*
    @[JSON::Field(key: "functionCallingConfig")]
    property function_calling_config : FunctionCallingConfig?
  end

  struct FunctionCallingConfig
    include JSON::Serializable
    # Specifies the mode in which function calling should execute. *(Optional)*
    property mode : Mode?

    # A set of function names that, when provided, limits the functions the model will call. *(Optional)*
    @[JSON::Field(key: "allowedFunctionNames")]
    property allowed_function_names : Array(String)?

    # Defines the execution behavior for function calling by defining the execution mode.
    #
    # [API Reference](https://ai.google.dev/api/caching#Mode)
    enum Mode
      ModeUnspecified # Unspecified function calling mode. This value should not be used.
      Auto            # Model decides to predict either a function call or a natural language response.
      Any             # Model is constrained to always predicting a function call only.
      None            # Model will not predict any function call.
    end
  end
end

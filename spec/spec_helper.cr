require "spec"
require "../src/gemini"

Gemini.configure do |config|
  config.api_key = ENV["GEMINI_API_KEY"]
end

SAMPLES = {
  "citation_metadata_00" => %q({
    "candidates": [
      {
        "content": {
          "parts": [
            {
              "text": "Artificial intelligence (AI) is a broad field encompassing many techniques, but at its core, it aims to create systems that can perform tasks that typically require human intelligence..."
            }
          ],
          "role": "model"
        },
        "finishReason": "STOP",
        "citationMetadata": {
          "citationSources": [
            {
              "startIndex": 24,
              "endIndex": 28,
              "uri": "https://example.com/path/to/article"
            },
            {
              "startIndex": 76,
              "endIndex": 91,
              "uri": "https://some.site/path/to/something"
            }
          ]
        },
        "avgLogprobs": -0.20354270935058594
      }
    ],
    "usageMetadata": {
      "promptTokenCount": 5,
      "candidatesTokenCount": 704,
      "totalTokenCount": 709
    },
    "modelVersion": "gemini-1.5-flash"
  }),

  "prohibited_content_00" => %q({
    "promptFeedback": {
      "blockReason": "PROHIBITED_CONTENT"
    },
    "usageMetadata": {
      "promptTokenCount": 7,
      "totalTokenCount": 7
    }
  }),

  "finish_reason_safety_00" => %q({
    "candidates": [
      {
        "finishReason": "SAFETY",
        "index": 0,
        "safetyRatings": [
          {
            "category": "HARM_CATEGORY_SEXUALLY_EXPLICIT",
            "probability": "MEDIUM"
          },
          {
            "category": "HARM_CATEGORY_HATE_SPEECH",
            "probability": "NEGLIGIBLE"
          },
          {
            "category": "HARM_CATEGORY_HARASSMENT",
            "probability": "NEGLIGIBLE"
          },
          {
            "category": "HARM_CATEGORY_DANGEROUS_CONTENT",
            "probability": "NEGLIGIBLE"
          }
        ]
      }
    ],
    "usageMetadata": {
      "promptTokenCount": 137,
      "totalTokenCount": 137
    },
    "modelVersion": "gemini-1.5-flash-latest"
  }),

  "error_00" => %q({
    "error": {
      "code": 400,
      "message": "Invalid JSON payload received. Unknown name \"pars\" at 'system_instruction': Cannot find field.\nInvalid JSON payload received. Unknown name \"xyz\": Cannot find field.",
      "status": "INVALID_ARGUMENT",
      "details": [
        {
          "@type": "type.googleapis.com/google.rpc.BadRequest",
          "fieldViolations": [
            {
              "field": "system_instruction",
              "description": "Invalid JSON payload received. Unknown name \"pars\" at 'system_instruction': Cannot find field."
            },
            {
              "description": "Invalid JSON payload received. Unknown name \"xyz\": Cannot find field."
            }
          ]
        }
      ]
    }
  }),

  "error_01" => %q({
    "error": {
      "code": 503,
      "message": "The service is currently unavailable.",
      "status": "UNAVAILABLE"
    }
  }),
}

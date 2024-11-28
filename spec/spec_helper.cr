require "spec"
require "../src/gemini"

Gemini.configure do |config|
  config.api_key = ENV["GEMINI_API_KEY"]
end

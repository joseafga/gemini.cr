require "spec"
require "../src/gemini"

Gemini.configure do |config|
  config.api_key = ENV["GEMINI_API_KEY"]
end

module Samples
  extend self
  PATH = Path[__DIR__] / "samples"

  def load_json(filename) : String
    File.read("#{PATH}/#{filename}.json")
  end
end

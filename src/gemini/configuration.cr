module Gemini
  class_getter config = Configuration.new

  # Customize settings using a block.
  #
  # ```
  # Gemini.configure do |config|
  #   config.api_key = "123asd"
  # end
  # ```
  def self.configure(&) : Nil
    yield config
  end

  class Configuration
    property api_key : String = ""
  end
end

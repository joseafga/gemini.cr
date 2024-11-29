# Gemini.cr

Google Gemini API written in Crystal.

It is not complete, it was created for use in another project, but it may be usable.

## Installation

1. Add the dependency to your `shard.yml`:

   ```yaml
   dependencies:
     gemini:
       github: joseafga/gemini.cr
   ```

2. Run `shards install`

## Usage

```crystal
require "gemini"

Gemini.configure do |config|
  config.api_key = "GEMINI_API_KEY"
end

model = Gemini::GenerativeModel.new("gemini-1.5-flash")
response = model.generate_content("Explain how AI works")

puts response.text
```

## Contributing

1. Fork it (<https://github.com/joseafga/gemini.cr/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [José Almeida](https://github.com/joseafga) - creator and maintainer

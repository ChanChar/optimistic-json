# Optimistic::Json

A Ruby implementation of [`best-effort-json-parser`](https://github.com/beenotung/best-effort-json-parser) which attempts to parse incomplete JSON in a best-effort manner.

## Installation

Install the gem and add to the application's Gemfile by executing:

    $ bundle add optimistic-json

If bundler is not being used to manage dependencies, install the gem by executing:

    $ gem install optimistic-json

## Usage

```ruby
parser = Optimistic::Json::Parser.new

parser.parse('["oops", "this", "is", "missing the end bracket')
# => ["oops", "this", "is", "missing the end bracket"]

parser.parse('{ "maybe_a_float": 12.')
# => {"maybe_a_float"=>12.0}

parser.parse('[1, 2, {"a": "apple')
# => [1, 2, {"a"=>"apple"}]
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, run `gem bump --version <minor|major|#.#.#>`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ChanChar/optimistic-json. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/ChanChar/optimistic-json/blob/main/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Optimistic::Json project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/ChanChar/optimistic-json/blob/main/CODE_OF_CONDUCT.md).

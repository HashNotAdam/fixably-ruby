# Fixably

The Fixably Ruby library provides access to the Fixably API for Ruby
applications with automatic integration into Ruby on Rails.

Support is only provided for Ruby >= 3.0

## Installation

Add this line to your application's Gemfile:

```ruby
gem "fixably"
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install fixably

## Configuration

Before you begin, you will need to setup API credentials in Fixably at
https://[your-domain].fixably.com/en/settings/integrations

You need to set your API key and subdomain in the Fixably configuration. The
subdomain is the part before .fixably.com when you are using Fixable. For
example, if you accessed Fixably via https://demo.fixably.com/, then your
subdomain is "demo".

```ruby
require "fixably"

Fixably.configure do |config|
  config.api_key = ENV["fixably_api_key"]
  config.subdomain = "demo"
end
```

In a Rails application, this is best done in an initializer. For example,
`config/initializers/fixably.rb`:
```ruby
Fixably.configure do |config|
  config.api_key = Rails.application.credentials.fixably["api_key"]
  config.subdomain = Rails.application.credentials.fixably["subdomain"]
end
```

## Contributing

Bug reports and pull requests are welcome on
[GitHub](https://github.com/HashNotAdam/fixably-ruby).
This project is intended to be a safe, welcoming space for collaboration, and
contributors are expected to adhere to the
[code of conduct](https://github.com/HashNotAdam/fixably-ruby/blob/master/CODE_OF_CONDUCT.md).

If you would like to add a feature or fix a bug:
- create an issue so we can discuss your thoughts;
- fork the project;
- start a feature/bugfix branch;
- commit your changes (be sure to include tests); and
- create a pull request to merge your branch into main.

## Testing

Since it is necessary to authenticate with Fixably to test API resources,
credentials are required. The dotenv gem is loaded when tests are run and will
look for a .env file in the root directory. A .env.example file has been
supplied so you copy it to .env and replace the example values:

```sh
cp .env.example .env
```

Making production API calls while testing can have undesirable side-effects so
[VCR](https://github.com/vcr/vcr) is used to record the responses from Fixably
and reply them in subsequent test runs.

Please remember to remove any personal details from the cassette. For example,
replace "[your-subdomain].fixably.com" with "demo.fixably.com".

The VCR recording mode is set to :none, which does not allow new recordings to
occur. This avoids unexpected live requests to Fixably. If you are creating or
updating a test, you can temporarily set a different record mode for that test:
```ruby
it "does important things" do
  VCR.use_cassette("important things", record: :once) do
    do_some_things
    expect(important_things)
  end
end
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fixably project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/HashNotAdam/fixably-ruby/blob/master/CODE_OF_CONDUCT.md).

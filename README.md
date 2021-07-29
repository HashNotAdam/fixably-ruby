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

## Usage

This gem utilises Active Resource under the hood to provide a Rails-like
interface.

```ruby
customers = Fixably::Customer.all
customer = Fixably::Customer.find(1000)
customer = Fixably::Customer.first
customer = Fixably::Customer.last

customers = Fixably::Customer.where(first_name: "HashNotAdam")
customer = customers.first
customer.first_name = "Adam"
customer.save!

customer = Fixably::Customer.create!(
  first_name: "Adam",
  last_name: "Rice",
  email: "development@hashnotadam.com"
)
```

Where there are known required fields, you can test validity or catch errors if
using the bang functions.

```ruby
customer = Fixably::Customer.new(first_name: "HashNotAdam")
customer.valid? # => false
customer.errors.full_messages.to_sentence # => Either email or phone must be present

customer.save # => false
customer.save! # Exception: Failed. (ActiveResource::ResourceInvalid)

customer = Fixably::Customer.create(first_name: "HashNotAdam")
customer.persisted? # => false

customer = Fixably::Customer.create!(first_name: "HashNotAdam") # Exception: Failed. (ActiveResource::ResourceInvalid)
```

If you need to know the attributes of a model, you can request the schema. It
should be noted that the schema only includes fields that Fixably accept when
creating or updating record. For example, if you load a customer, the API will
include tags but Fixably does not support modifying the tags attribute via the
API.

```ruby
Fixably::Customer.schema
# =>
# {"id"=>"integer",
#  "first_name"=>"string",
#  "last_name"=>"string",
#  "company"=>"string",
#  "phone"=>"string",
#  "email"=>"string",
#  "business_id"=>"string",
#  "language"=>"string",
#  "provider"=>"string",
#  "identifier"=>"string"}
```

Currently supported resources:
- Fixably::Customer

## Link expansion

Fixably actively avoid sending information about associations or even the data
for a collection ([Fixably docs](https://docs.fixably.com/?http#link-expansion)).
For example, if you were to send a request for a collection of customers, you
would receive something like:
```ruby
{
  "limit": 25,
  "offset": 0,
  "totalItems": 100,
  "items": [
    { "href": "https://subdomain.fixably.com/api/v3/customers/1001" },
    { "href": "https://subdomain.fixably.com/api/v3/customers/1002" },
    { "href": "https://subdomain.fixably.com/api/v3/customers/1003" },
    ...
  ]
}
```

This gem will always pass "expand=items" with requests which expands the first
layer of information. If you would also like to load associations, you can
use the `includes` method with the name of the association. For example:

```ruby
customers = Fixably::Customer.includes(:children).all
# expand=items,children(items)
```

## Pagination

When making a request that could return multiple results, you will receive a
paginated collection. You can pass `limit` and `offset` parameters to manually
manage pagination or use the helper methods:
```ruby
customers = Fixably::Customer.where(company: "Education Advantage") # PaginatedCollection
customers.limit # => 25
customers.offset # => 0

customers.each.count # => 25

all_customers = []
customers.paginated_each { all_customers << _1 }
all_customers.count # => 100

all_customers = customers.paginated_map
all_customers.count # => 100
```

Remember to be respectful when using this feature; requesting all records has
the potential to send a lot of requests. If you need to download a lot of data,
it is probably worth your time to tweak the limit to pull in bigger batches:
```ruby
customers = Fixably::Customer.all(limit: 100)
customers.limit # => 100
customers.offset # => 0

customers.each.count # => 25
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

Be aware that this gem monkey patches Active Resource. As such, you may need to
familiarise yourself with `lib/fixably/active_resource/base.rb`.

## Testing

The test suite does not make any requests, however, it does test up to the point
that the request would be made. This means that many tests will fail unless
a subdomain and API key are configured.

The dotenv gem is loaded when tests are run and will look for a .env file in the
root directory. A .env.example file has been supplied so you copy it to .env and
replace the example values:

```sh
cp .env.example .env
```

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Fixably project's codebases, issue trackers, chat
rooms and mailing lists is expected to follow the
[code of conduct](https://github.com/HashNotAdam/fixably-ruby/blob/master/CODE_OF_CONDUCT.md).

# Fixably::Customer

## List customers

```ruby
Fixably::Customer.all
Fixably::Customer.where(first_name: "Adam")
```

### Include associations in a list

**Children**
```ruby
Fixably::Customer.includes(:children).all
Fixably::Customer.includes(:children).where(first_name: "Adam")
```

## Get a customer

```ruby
Fixably::Customer.find(1_000)
Fixably::Customer.first
Fixably::Customer.last
```

## Create a customer

```ruby
customer = Fixably::Customer.create(
  first_name: "Adam",
  last_name: "Rice",
  email: "development@hashnotadam.com"
)
customer.valid? # => true
customer.persisted? # => true

# Raises an error on failure
Fixably::Customer.create!(
  first_name: "Adam",
  last_name: "Rice",
  email: "development@hashnotadam.com"
)

customer = Fixably::Customer.new(
  first_name: "Adam",
  last_name: "Rice",
  email: "development@hashnotadam.com"
)
customer.save
customer.valid? # => true
customer.persisted? # => true

customer = Fixably::Customer.new(
  first_name: "Adam",
  last_name: "Rice",
  email: "development@hashnotadam.com"
)
# Raises an error on failure
customer.save!
```

## Update a customer

```ruby
customer = Fixably::Customer.find(1_000)
customer.first_name = "Adam"

customer.save
customer.valid? # => true
customer.persisted? # => true

# Raises an error on failure
customer.save!
```

## Destroy a customer

The Fixably API does not allow customers to be destroyed

# Fixably::Order

## List orders

```ruby
Fixably::Order.all
Fixably::Order.where(is_closed: false)
Fixably::Order.where(updated_at: "2000-01-01")
Fixably::Order.where(updated_at: ["2000-01-01",]) # >= 2000-01-01
Fixably::Order.where(updated_at: [,"2000-01-01"]) # <= 2000-01-01
Fixably::Order.where(updated_at: ["2000-01-01","2000-02-01"]) # 2000-01-01 <> 2000-02-01
```

### Include associations in a list

**Notes**
```ruby
Fixably::Order.includes(:notes).all
Fixably::Order.includes(:notes).where(internal_location: "SERVICE")
```

**Tasks**
```ruby
Fixably::Order.includes(:tasks).all
Fixably::Order.includes(:tasks).where(internal_location: "SERVICE")
```

## Get a customer

```ruby
Fixably::Order.find(1_000)
Fixably::Order.first
Fixably::Order.last
```

## Create an order

```ruby
order = Fixably::Order.create(internal_location: "SERVICE")
customer.valid? # => true
customer.persisted? # => true

# Raises an error on failure
Fixably::Order.create!(internal_location: "SERVICE")

order = Fixably::Order.new(internal_location: "SERVICE")
order.save
order.valid? # => true
order.persisted? # => true

order = Fixably::Order.new(internal_location: "SERVICE")
# Raises an error on failure
order.save!
```

## Update an order

```ruby
customer = Fixably::Customer.first
order = Fixably::Order.find(1_000)
order.internal_location = "SERVICE"

order.save
order.valid? # => true
order.persisted? # => true

# Raises an error on failure
order.save!
```

## Destroy an order

The Fixably API does not allow orders to be destroyed

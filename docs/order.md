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

**Contact**
```ruby
Fixably::Order.includes(:contact).all
Fixably::Order.includes(:contact).where(internal_location: "SERVICE")
```

**Customer**
```ruby
Fixably::Order.includes(:customer).all
Fixably::Order.includes(:customer).where(internal_location: "SERVICE")
```

**Device**
```ruby
Fixably::Order.includes(:device).all
Fixably::Order.includes(:device).where(internal_location: "SERVICE")
```

**Handled by**
```ruby
Fixably::Order.includes(:handled_by).all
Fixably::Order.includes(:handled_by).where(internal_location: "SERVICE")
```

**Location**
```ruby
Fixably::Order.includes(:location).all
Fixably::Order.includes(:location).where(internal_location: "SERVICE")
```

**Ordered by**
```ruby
Fixably::Order.includes(:ordered_by).all
Fixably::Order.includes(:ordered_by).where(internal_location: "SERVICE")
```

**Queue**
```ruby
Fixably::Order.includes(:queue).all
Fixably::Order.includes(:queue).where(internal_location: "SERVICE")
```

**Status**
```ruby
Fixably::Order.includes(:status).all
Fixably::Order.includes(:status).where(internal_location: "SERVICE")
```

**Lines**
```ruby
Fixably::Order.includes(:lines).all
Fixably::Order.includes(:lines).where(internal_location: "SERVICE")
```

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

## Get an order

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

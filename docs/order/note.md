# Fixably::Order::Note

## List order notes

```ruby
Fixably::Order::Note.all(order_id: 1_000)
```

### Include associations in a list

**Created by**
```ruby
Fixably::Order.includes(:created_by).all(order_id: 1_000)
```

## Get an order note

```ruby
Fixably::Order::Note.find(1_000, order_id: 1_000)
Fixably::Order::Note.first(order_id: 1_000)
Fixably::Order::Note.last(order_id: 1_000)
```

## Create an order note

```ruby
order = Fixably::Order.find(1_000)
note = Fixably::Order::Note.new(text: "New note", type: "INTERNAL")
order.notes << note

note.valid? # => true
note.persisted? # => true
```

## Update an order note

The Fixably API does not allow order notes to be updated

## Destroy an order note

The Fixably API does not allow order notes to be destroyed

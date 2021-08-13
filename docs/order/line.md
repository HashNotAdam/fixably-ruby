# Fixably::Order::Line

## List order lines

```ruby
Fixably::Order::Line.all(order_id: 1000)
```

## Get an order line

```ruby
Fixably::Order::Line.find(1000, order_id: 1000)
Fixably::Order::Line.first(order_id: 1000)
Fixably::Order::Line.last(order_id: 1000)
```

## Create an order line

The Fixably API does not allow order lines to be created

## Update an order line

While supported by Fixably, this feature has not yet been implemented

## Destroy an order line

The Fixably API does not allow notes to be destroyed

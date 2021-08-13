# Fixably::Order::Task

## List order tasks

```ruby
Fixably::Order::Task.all(order_id: 1000)
```

## Get an order task

```ruby
Fixably::Order::Task.find(1000, order_id: 1000)
Fixably::Order::Task.first(order_id: 1000)
Fixably::Order::Task.last(order_id: 1000)
```

## Create an order task

The Fixably API does not allow order tasks to be created

## Update an order task

While supported by Fixably, this feature has not yet been implemented

## Destroy an order task

The Fixably API does not allow notes to be destroyed

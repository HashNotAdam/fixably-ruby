# Fixably::Queue

## List queue

```ruby
Fixably::Queue.all
Fixably::Queue.where(name: "Mac")
```

### Include associations in a list

**Statuses**
```ruby
Fixably::Queue.includes(:statuses).all
Fixably::Queue.includes(:statuses).where(name: "Mac")
```

## Get a queue

```ruby
Fixably::Queue.find(1_000)
Fixably::Queue.first
Fixably::Queue.last
```

## Create a queue

The Fixably API does not allow queues to be created

## Update a queue

The Fixably API does not allow queues to be updated

## Destroy a queue

The Fixably API does not allow queues to be destroyed

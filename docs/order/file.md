# Fixably::Order::File

## List order files

```ruby
Fixably::Order::File.all(order_id: 1_000)
```

Fixably leaves quarantined files out of the list. Each file's `url` is a download link that lasts an hour, so list the files again for a fresh one.

### Include associations in a list

**Created by**
```ruby
Fixably::Order::File.includes(:created_by).all(order_id: 1_000)
```

## Get an order file

The Fixably API does not allow an order file to be fetched on its own

## Create an order file

While supported by Fixably, this feature has not yet been implemented

## Update an order file

The Fixably API does not allow order files to be updated

## Destroy an order file

The Fixably API does not allow order files to be destroyed

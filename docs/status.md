# Fixably::Status

## List status

```ruby
Fixably::Status.all
Fixably::Status.where(serial_number: "ABCDE123FGHI")
```

### Include associations in a list

**Custom**
```ruby
Fixably::Status.includes(:custom).all
Fixably::Status.includes(:custom).where(serial_number: "ABCDE123FGHI")
```

**Queue**
```ruby
Fixably::Status.includes(:queue).all
Fixably::Status.includes(:queue).where(serial_number: "ABCDE123FGHI")
```

## Get a status

```ruby
Fixably::Status.find(1_000)
Fixably::Status.first
Fixably::Status.last
```

## Create a status

The Fixably API does not allow statuses to be created

## Update a status

The Fixably API does not allow statuses to be updated

## Destroy a status

The Fixably API does not allow statuses to be destroyed

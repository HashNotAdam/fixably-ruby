# Fixably::Device

## List devices

```ruby
Fixably::Device.all
Fixably::Device.where(serialNumber: "ABCDE123FGHI")
```

## Get a device

```ruby
Fixably::Device.find(1_000)
Fixably::Device.first
Fixably::Device.last
```

## Create a device

```ruby
device = Fixably::Device.create(
  name: "My device",
  serial_number: "ABCDE123FGHI"
)
device.valid? # => true
device.persisted? # => true

# Raises an error on failure
Fixably::Device.create!(
  name: "My device",
  serial_number: "ABCDE123FGHI"
)

device = Fixably::Device.new(
  name: "My device",
  serial_number: "ABCDE123FGHI"
)
device.save
device.valid? # => true
device.persisted? # => true

device = Fixably::Device.new(
  name: "My device",
  serial_number: "ABCDE123FGHI"
)
# Raises an error on failure
device.save!
```

## Update a customer

The Fixably API does not allow devices to be destroyed

## Destroy a customer

The Fixably API does not allow customers to be destroyed

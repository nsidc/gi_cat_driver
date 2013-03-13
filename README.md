# GI-Cat Driver

The GI-Cat driver is a ruby wrapper for GI-Cat services.  Remotely configure administration options for a GI-Cat instance.

## Installation

Add this line to your application's Gemfile:

    gem 'gi_cat_driver'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gi_cat_driver

## Usage

To start using the gem create a new instance

```ruby
gi_cat = GiCatDriver::GiCat.new('http://www.company.com/api/gi-cat', 'admin', 'password')
```
Please note you must provide a URL to a running GI-Cat instance as well as the administrator username and password.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

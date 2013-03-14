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

Assuming you have a GI-Cat application running at http://www.company.com/api/gi-cat/ 
and an administrative login of username='admin', password='password' create a new GiCat
to start using the gem.

```ruby
gi_cat = GiCatDriver::GiCat.new('http://www.company.com/api/gi-cat', 'admin', 'password')
```
Note you must provide a URL to a running GI-Cat instance as well as the administrator username and password.

## API Documentation

Main API methods are

```ruby
GiCatDriver
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request

## License

GI-Cat Driver is licensed under the MIT license. See [LICENSE.txt][license].

[license]: https://raw.github.com/nsidc/gi_cat_driver/master/LICENSE.txt

## Credit

This software was developed by the National Snow and Ice Data Center, sponsored by the National Science Foundation grant number OPP-10-16048.

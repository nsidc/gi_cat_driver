# GI-Cat Driver

The GI-Cat driver is a ruby API wrapper for GI-Cat services.  Remotely configure administration options for a GI-Cat instance.

## Requirements

* Ruby 1.9.3
* rest-client
* nokogiri

## Installation

Add this line to your application's Gemfile:

    gem 'gi_cat_driver'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install gi_cat_driver

## Quick Start Guide

Connect to an existing GI-Cat instance using the following code:

```Ruby
gi_cat = GiCatDriver::GiCat.new("http://www.mycompany.com/api/gi-cat/", ADMIN_USERNAME, ADMIN_PASSWORD)
```

The gi_cat variable can now be used to access various methods to control GI-Cat:

```Ruby
gi_cat.enable_profile "MY_PROFILE_NAME"
```

## Documentation

Annotated source code documentation is available at http://nsidc.github.com/gi_cat_driver/

Rubydoc API documentation is available at http://rubydoc.info/gems/gi_cat_driver/

## Version History

* 0.0.8
  * Minor refactoring
* 0.0.7
  * Code documentation
* 0.0.6
  * Dropped ruby version to 1.9.3-p194
* 0.0.5
  * Added methods to initiate and monitor harvesting with GI-Cat
* 0.0.4
* 0.0.2
  * Added code documentation
  * Removed functionality dependent on NSIDC internal systems
* 0.0.1
  * Initial release


## Versioning

This gem follows the principles of [Semantic Versioning 2.0.0](http://semver.org/)

## Releasing

1. Commit all code to master branch
2. ????????????

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

This software was developed by the National Snow and Ice Data Center,
sponsored by the National Science Foundation grant number OPP-10-16048.

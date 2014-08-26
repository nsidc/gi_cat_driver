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
* 0.3.1
  * Remove Gemfile.lock
* 0.3.0
  * When a profile is removed all of its child accessors are also removed
* 0.2.8
  * Removed constant variables causing errors in the console output
* 0.2.6
  * Fix for creating accessors to enable the profile and save the configuration
* 0.2.5
  * Added new methods to enable and disable published profilers (GI-Cat interfaces) for a profile
* 0.2.4
  * Added new methods to create and delete accessors (GI-Cat resources) for a profile
* 0.2.3
  * Changed the harvest to be sequential. (one resource won't start harvest till the current one is completed or timeout)
* 0.2.2
  * Added new methods to create and delete profiles
  * Fixed harvester request headers and now work properly
* 0.2.1
  * Fixed harvester requests to use Faraday
* 0.2.0
  * Introduced Faraday gem to replace rest-client and webmock for testing requests
  * Implemented tests for methods that use fixtures to mock response data
* 0.1.12
  * Fixed typo in check for harvest status
* 0.1.11
  * Added sleep to harvest method to limit console output
* 0.1.10
  * Fixed rocco rake task
* 0.1.9
  * Added rake task to generate rocco docs
* 0.1.8
  * Changed harvest api so the timeout is configurable
* 0.1.7
  * Minor change: updated a private function name
* 0.1.6
  * Extended timeout default to handle a large amount of data in harvest
* 0.1.5
  * Improved output of harvesting to provide better information about what is happening
* 0.1.3
  * Added timeout for harvest procedure
* 0.1.2
  * Additional harvesting output
  * Harvester resources now handled dynamically
* 0.1.1
  * Added parameter to ESIP OpenSearch query builder
  * Added log output for GI-Cat harvest procedures
* 0.1.0
  * Release stable version of gem features that invoke GI-Cat
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

1. Make sure to increment the version number (See the section about versioning above) and append a description of your changes to the Version History section above.
2. Generate the documentation with 'rake rocco'.  To update the gh-pages branch on GitHub I suggest cloning that branch as a new project, then copy the generated docs to that new project and push.
3. Commit changes into the master branch of the repo on 'sourcecontrol.nsidc.org'. This will trigger a Jenkins job to run the tests.
4. Assuming the change is merged with the master branch and you are ready to release them to GitHub run 'git push https://github.com/nsidc/gi_cat_driver.git master'
      * There is a Jenkins job that can push master to GitHub if you are confident you wont have merge conflicts.
      * Note: You must have permissions on the GitHub repository through the NSIDC organization.
5. Make sure to release the new gem version to RubyGems by running 'rake release'
      * Note: You must be configured as an owner of the 'gi_cat_driver'a gem on RubyGems.
      * Also Note: RubyGems will not allow you to release the same version of a gem more than once.

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

## How to contact NSIDC ###

User Services and general information:  
Support: http://support.nsidc.org  
Email: nsidc@nsidc.org

Phone: +1 303.492.6199  
Fax: +1 303.492.2468

Mailing address:  
National Snow and Ice Data Center  
CIRES, 449 UCB  
University of Colorado  
Boulder, CO 80309-0449 USA

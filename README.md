Description
===========

This is a massive simplification/refactor of the original [jenkins cookbook](http://community.opscode.com/cookbooks/jenkins)
written by these awesome people:

```ruby
Original Author:: Doug MacEachern (<dougm@vmware.com>)
Contributor:: AJ Christensen <aj@junglist.gen.nz>
Contributor:: Fletcher Nichol <fnichol@nichol.ca>
Contributor:: Roman Kamyk <rkj@go2.pl>
Contributor:: Darko Fabijan <darko@renderedtext.com>
```

I plan on rewriting this README once it's closer to release.

TODO
====

* test coverage including test-kitchen/jamie integration tests
* reevalute LWRPs and see if Jenkins REST API can be better leveraged.
* LWRPs for defining pipelines
* complete rewrite of README based on recent changes

Proposed Test Scenarios
=======================

* Ensure Jenkins is running and accessible when:
  * initially installed
  * plugin is added/updated
  * new version of WAR is downloaded

* running and accessible includes:
  * webui is accessible
  * jenkins_job can successfully create a new job via API.

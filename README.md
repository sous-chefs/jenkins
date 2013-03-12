Description
===========

This is a massive simplification/refactor of the original [jenkins cookbook](http://community.opscode.com/cookbooks/jenkins). This README will be rewritten before the next release.

Requirements
============

## Platform:

* Ubuntu
* RHEL/CentOS

Attributes
==========

* `node['jenkins']['http_proxy']['server_auth_method']` - Authentication with
  the server can be done with cas (using `apache2::mod_auth_cas`), or htauth
  (basic). The default is htauth (basic).
* `node['jenkins']['http_proxy']['cas_login_url']` - Login url for cas if using
  cas authentication.
* `node['jenkins']['http_proxy']['cas_validate_url']` - Validation url for cas
  if using cas authentication.
* `node['jenkins']['http_proxy']['cas_validate_server']` - Whether to validate
  the server cert. Defaults to off.
* `node['jenkins']['http_proxy']['cas_root_proxy_url']` - If set, sets the url
  that the cas server redirects to after auth.

TODO

Recipes
=======

TODO

Resource/Provider
=================

TODO

Usage
=====

TODO

Testing
=======

TODO

License and Author
==================

|                      |                                          |
|:---------------------|:-----------------------------------------|
| **Original Author**  | Doug MacEachern (<dougm@vmware.com>)     |
| **Contributor**      | AJ Christensen <aj@junglist.gen.nz>      |
| **Contributor**      | Fletcher Nichol <fnichol@nichol.ca>      |
| **Contributor**      | Roman Kamyk <rkj@go2.pl>                 |
| **Contributor**      | Darko Fabijan <darko@renderedtext.com>   |
| **Contributor**      | Seth Chisamore <schisamo@opscode.com>    |
|                      |                                          |
| **Copyright**        | Copyright (c) 2010 VMware, Inc.          |
| **Copyright**        | Copyright (c) 2011 Fletcher Nichol       |
| **Copyright**        | Copyright (c) 2013 Opscode, Inc.         |

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

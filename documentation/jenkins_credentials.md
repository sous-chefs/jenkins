# jenkins_credentials

## NOTES

- Install version 1.6 or higher of the [credentials plugin](https://wiki.jenkins-ci.org/display/JENKINS/Credentials+Plugin) to use the Jenkins credentials resource.

- In version `4.0.0` of this cookbook this resource was changed so that credentials are referenced by their ID instead of by their name. If you are upgrading your nodes from an earlier version of this cookbook ( <= 3.1.1 ), use the credentials resource and do not have explicit IDs assigned to credentials, you will need to go into the Jenkins UI, find the auto-generated UUIDs for your credentials, and add them to your cookbook resources.

## Actions

- :create
- :delete

Both actions operate on the credential resources idempotently. It also supports why-run mode.

`jenkins_credentials` is a base resource that is not used directly. Instead there are resources for each specific type of credentials supported.

## Properties

Use of the credential resource requires a unique `id` property. The resource uses this ID to find the credential for future modifications, and it is an immutable resource once the resource is created within Jenkins. This ID is also how you reference the credentials in other Groovy scripts (i.e. Pipeline code).

The `username` property (also the name property) corresponds to the username of the credentials on the target node.

You may also specify a `description` which is useful in credential identification.

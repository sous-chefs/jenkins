# jenkins_view

This resource manages Jenkins view

## Actions

- :create
- :delete

The resource is fully idempotent and convergent as long as you're not using free hand code. It also supports whyrun mode.

The `:create` action requires an array of jobs:

```ruby
jenkins_view 'ham' do
  jobs [ "pig", "giraffe" ]
end
```

The `:delete` action deleted a configured view:

```ruby
jenkins_view 'ham' do
  action :delete
end
```

It is possible to pass a snippet of groovy code in order to create more sophisticated views, the idea is to override the `create_view` and `configure_view` groovy closures.

```ruby
code = <<-GROOVY
create_view = { name ->
  // Return a new view
  return new BuildPipelineView(...)
}

configure_view = { view ->
  // Configure view
  view.setCssUrl("")
}
GROOVY

jenkins_view 'pipline_view' do
  code    code
  action :create
end
```

Please note that if you pass `code`, it will always run the `:create` action as the provider cannot determine when a change has to be made and when not.

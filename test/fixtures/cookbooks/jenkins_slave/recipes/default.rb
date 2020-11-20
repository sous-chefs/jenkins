include_recipe '::create_jnlp'
include_recipe '::create_ssh'

include_recipe '::connect'
include_recipe '::online'

include_recipe '::offline'
include_recipe '::disconnect'

include_recipe '::delete_jnlp'
include_recipe '::delete_ssh'

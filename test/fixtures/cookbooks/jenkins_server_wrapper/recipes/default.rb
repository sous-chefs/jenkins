apt_update 'update' if platform_family?('debian')

include_recipe 'java::default'
include_recipe 'jenkins::master'

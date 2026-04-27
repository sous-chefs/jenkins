property :slave_name, String, name_property: true

property :description, String,
         default: lazy { |r| "Jenkins agent #{r.slave_name}" }

property :remote_fs, String, default: '/home/jenkins'
property :executors, Integer, default: 1
property :usage_mode, String, equal_to: %w(exclusive normal), default: 'normal'
property :labels, Array, default: []
property :availability, String, equal_to: %w(always demand)
property :in_demand_delay, Integer, default: 0
property :idle_delay, Integer, default: 1
property :environment, Hash
property :offline_reason, String
property :user, String, regex: [Chef::Config[:user_valid_regex]], default: 'jenkins'
property :jvm_options, String
property :java_path, String

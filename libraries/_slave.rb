# attr_writer :exists
# attr_writer :connected
# attr_writer :online

module Jenkins
  module Cookbook
    module Slave
      #
      # Determine if the slave exists on the master. This value is set by
      # the provider when the current resource is loaded.
      #
      # @return [Boolean]
      #
      def exists?
        !@exists.nil? && @exists
      end

      #
      # Determine if the slave is connected to the master. This value is
      # set by the provider when the current resource is loaded.
      #
      # @return [Boolean]
      #
      def connected?
        !@connected.nil? && @connected
      end

      #
      # Determine if the slave is online. This value is set by the
      # provider when the current resource is loaded.
      #
      # @return [Boolean]
      #
      def online?
        !@online.nil? && @online
      end

      def merge_preserved_labels!
        new_resource.labels |= current_resource.labels.select { |i| i[/^prsrv_/] }
      end

      def do_create
        # Preserve some labels...
        merge_preserved_labels!
        if current_resource.exists? && correct_config?
          Chef::Log.info("#{new_resource} exists - skipping")
        else
          converge_by("Create #{new_resource}") do
            executor.groovy! <<-EOH.gsub(/^ {12}/, '')
              import hudson.model.*
              import hudson.slaves.*
              import jenkins.model.*
              import jenkins.slaves.*

              props = []
              availability = #{convert_to_groovy(new_resource.availability)}
              usage_mode = #{convert_to_groovy(new_resource.usage_mode)}
              env_map = #{convert_to_groovy(new_resource.environment)}
              labels = #{convert_to_groovy(new_resource.labels.sort.join(' '))}

              // Compute the usage mode
              if (usage_mode == 'normal') {
                mode = Node.Mode.NORMAL
              } else {
                mode = Node.Mode.EXCLUSIVE
              }

              // Compute the retention strategy
              if (availability == 'demand') {
                retention_strategy =
                  new RetentionStrategy.Demand(
                    #{new_resource.in_demand_delay},
                    #{new_resource.idle_delay}
                )
              } else if (availability == 'always') {
                retention_strategy = new RetentionStrategy.Always()
              } else {
                retention_strategy = RetentionStrategy.NOOP
              }

              // Create an entry in the prop list for all env vars
              if (env_map != null) {
                env_vars = new hudson.EnvVars(env_map)
                entries = env_vars.collect {
                  k,v -> new EnvironmentVariablesNodeProperty.Entry(k,v)
                }
                props << new EnvironmentVariablesNodeProperty(entries)
              }

              // Launcher
              #{launcher_groovy}

              // Build the slave object
              slave = new DumbSlave(
                #{convert_to_groovy(new_resource.name)},
                #{convert_to_groovy(new_resource.description)},
                #{convert_to_groovy(new_resource.remote_fs)},
                #{convert_to_groovy(new_resource.executors.to_s)},
                mode,
                labels,
                launcher,
                retention_strategy,
                props
              )

              // Create or update the slave in the Jenkins instance
              nodes = new ArrayList(Jenkins.instance.getNodes())
              ix = nodes.indexOf(slave)
              (ix >= 0) ? nodes.set(ix, slave) : nodes.add(slave)
              Jenkins.instance.setNodes(nodes)
            EOH
          end
        end
      end
    end
  end
end

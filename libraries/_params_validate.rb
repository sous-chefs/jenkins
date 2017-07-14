#
# Cookbook:: jenkins
# Library:: params_validate
#
# Author:: Seth Vargo <sethvargo@gmail.com>
#
# Copyright:: 2013-2017, Chef Software, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# This workaround is only needed on Chef versions prior to 12.0.0:
#
#   https://github.com/chef/chef/pull/1559
#
if Gem::Requirement.new('< 12.0').satisfied_by?(Gem::Version.new(Chef::VERSION))
  require 'chef/mixin/params_validate'
  class Chef
    module Mixin::ParamsValidate
      def set_or_return(symbol, arg, validation)
        iv_symbol = "@#{symbol}".to_sym
        if arg.nil? && instance_variable_defined?(iv_symbol) == true
          ivar = instance_variable_get(iv_symbol)
          if ivar.is_a?(DelayedEvaluator)
            validate({ symbol => ivar.call }, { symbol => validation })[symbol] # rubocop:disable BracesAroundHashParameters
          else
            ivar
          end
        else
          if arg.is_a?(DelayedEvaluator)
            val = arg
          else
            val = validate({ symbol => arg }, { symbol => validation })[symbol] # rubocop:disable BracesAroundHashParameters

            # Handle the case where the "default" was a DelayedEvaluator
            val = val.call(self) if val.is_a?(DelayedEvaluator) # rubocop:disable BlockNesting
          end
          instance_variable_set(iv_symbol, val)
        end
      end
    end
  end

  require 'chef/resource/lwrp_base'
  class Chef
    class Resource::LWRPBase
      def self.lazy(&block)
        DelayedEvaluator.new(&block)
      end
    end
  end
end

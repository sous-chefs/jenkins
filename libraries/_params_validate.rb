#
# Cookbook Name:: jenkins
# Hack:: params_validate
#
# Author:: Seth Vargo <sethvargo@gmail.com>
#
# Copyright 2013-2014, Chef Software, Inc.
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
# HACK: https://github.com/opscode/chef/pull/1559
# This file can be removed when PR #1559 is merged.
#
require 'chef/mixin/params_validate'
class Chef
  module Mixin::ParamsValidate
    def set_or_return(symbol, arg, validation)
      iv_symbol = "@#{symbol.to_s}".to_sym
      if arg == nil && self.instance_variable_defined?(iv_symbol) == true
        ivar = self.instance_variable_get(iv_symbol)
        if(ivar.is_a?(DelayedEvaluator))
          validate({ symbol => ivar.call }, { symbol => validation })[symbol]
        else
          ivar
        end
      else
        if(arg.is_a?(DelayedEvaluator))
          val = arg
        else
          val = validate({ symbol => arg }, { symbol => validation })[symbol]

          # Handle the case where the "default" was a DelayedEvaluator
          if val.is_a?(DelayedEvaluator)
            val = val.call(self)
          end
        end
        self.instance_variable_set(iv_symbol, val)
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

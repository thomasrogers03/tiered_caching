#--
# Copyright 2015 Thomas RM Rogers
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#++

require 'yaml'
require 'logger'
require 'concurrent'

module TieredCaching
  def self.root
    @root ||= File.dirname(__FILE__)
  end
end

require 'tiered_caching/cache_line'
require 'tiered_caching/cache_master'
require 'tiered_caching/cached_object'
require 'tiered_caching/replicating_store'
require 'tiered_caching/async_store'
require 'tiered_caching/serializing_store'
require 'tiered_caching/safe_connection_pool'
require 'tiered_caching/hash_store'
require 'tiered_caching/logging'
require 'tiered_caching/redis_store'

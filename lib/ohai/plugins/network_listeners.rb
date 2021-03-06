#
# Author:: Doug MacEachern <dougm@vmware.com>
# Copyright:: Copyright (c) 2009 VMware, Inc.
# License:: Apache License, Version 2.0
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

Ohai.plugin(:NetworkListeners) do
  provides "network/listeners"

  depends "network", "counters/network"

  collect_data do
    begin
      require "sigar"
      flags = Sigar::NETCONN_TCP | Sigar::NETCONN_SERVER

      network Mash.new unless network
      listeners = Mash.new

      sigar = Sigar.new
      sigar.net_connection_list(flags).each do |conn|
        port = conn.local_port
        addr = conn.local_address.to_s
        if addr == "0.0.0.0" || addr == "::"
          addr = "*"
        end
        listeners[port] = Mash.new
        listeners[port][:address] = addr
        begin
          pid = sigar.proc_port(conn.type, port)
          # workaround for a failure of proc_state to throw
          # after the first 0 has been supplied to it
          #
          # no longer required when hyperic/sigar#48 is fixed
          throw ArgumentError.new("No such process") if pid == 0
          listeners[port][:pid] = pid
          listeners[port][:name] = sigar.proc_state(pid).name
        rescue
        end
      end

      network[:listeners] = Mash.new
      network[:listeners][:tcp] = listeners
    rescue LoadError
      Ohai::Log.debug("Could not load sigar gem. Skipping NetworkListeners plugin")
    end
  end
end

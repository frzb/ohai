#
# Author:: Gunter Miegel (<gunter.miegel@rgsqd.de>)
# Copyright:: Copyright (c) 2016 Gunter Miegel #!frzb
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

Ohai.plugin(:Scsi) do
  provides 'scsi/logical_units', 'scsi/hosts'

  # TODO: Better use more generic /proc/scsi/scsi.
  collect_data(:linux) do
    scsi Mash.new
    scsi[:logical_units] = Mash.new
    scsi[:hosts]         = Mash.new
    if File.exist?('/usr/bin/lsscsi')
      lsscsi_logical_units = shell_out('/usr/bin/lsscsi --verbose').stdout.lines
      # Tricky: Each entity  is spanning over 2 lines.
      (0..lsscsi_logical_units.length - 2).step(2).each do |index|
        /^\[(\S+)\]\s+(\S+)\s+(\S+)\s+(\S+\s+\S+)\s+(\S+)\s+(\S+)/ =~ lsscsi_logical_units[index]
        id = Regexp.last_match(1)
        scsi[:logical_units][id]           = Mash.new
        scsi[:logical_units][id][:type]    = Regexp.last_match(2)
        scsi[:logical_units][id][:vendor]  = Regexp.last_match(3)
        scsi[:logical_units][id][:model]   = Regexp.last_match(4)
        scsi[:logical_units][id][:rev]     = Regexp.last_match(5)
        scsi[:logical_units][id][:dev]     = Regexp.last_match(6)
        /.*\s+(\S+)\s+\[(\S+)\]/ =~ lsscsi_logical_units[index + 1]
        scsi[:logical_units][id][:dir]     = Regexp.last_match(1)
        scsi[:logical_units][id][:symlink] = Regexp.last_match(2)
      end

      lsscsi_hosts = shell_out('/usr/bin/lsscsi --hosts --verbose').stdout.lines
      # Tricky: Each entity  is spanning over 3 lines.
      (0..lsscsi_hosts.length - 3).step(3).each do |index|
        /^\[(\S+)\]\s+(\S+)/ =~ lsscsi_hosts[index]
        id = Regexp.last_match(1)
        scsi[:hosts][id]              = Mash.new
        scsi[:hosts][id][:type]       = Regexp.last_match(2)
        /.*dir:\s+(\S+)/ =~ lsscsi_hosts[index + 1]
        scsi[:hosts][id][:dir]        = Regexp.last_match(1)
        /.*device\s+dir:\s+(\S+)/ =~ lsscsi_hosts[index + 2]
        scsi[:hosts][id][:device_dir] = Regexp.last_match(1)
      end
    else
      Ohai::Log.debug('Executable \'/usr/bin/lsscsii\' missing.')
      Ohai::Log.debug('Can\'t obtain SCSI subsystem information.')
    end
  end
end

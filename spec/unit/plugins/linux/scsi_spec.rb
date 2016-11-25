# TODO add license header
#  reference /home/gm/github/ohai/spec/unit/plugins/linux/mdadm_spec.rb

require File.expand_path(File.dirname(__FILE__) + "/../../../spec_helper.rb")

# TODO verify is lssci has trailingtrailing  whitespaces/tabs
describe Ohai::System, "Linux SCSI plugin" do
  before(:each) do
    @lsscsi = <<-SCSI
[2:0:0:0]    disk    ATA      VBOX HARDDISK    1.0   /dev/sda
      dir: /sys/bus/scsi/devices/2:0:0:0  [/sys/devices/pci0000:00/0000:00:0d.0/ata3/host2/target2:0:0/2:0:0:0]
SCSI
    @lsscsi_hosts = <<-SCSI_HOSTS
[0]    ata_piix
  dir: /sys/class/scsi_host//host0
  device dir: /sys/devices/pci0000:00/0000:00:01.1/ata1/host0
[1]    ata_piix
  dir: /sys/class/scsi_host//host1
  device dir: /sys/devices/pci0000:00/0000:00:01.1/ata2/host1
[2]    ahci
  dir: /sys/class/scsi_host//host2
  device dir: /sys/devices/pci0000:00/0000:00:0d.0/ata3/host2
SCSI_HOSTS
   @plugin = get_plugin("linux/scsi")
   allow(@plugin).to receive(:collect_os).and_return(:linux)
   allow(@plugin).to receive(:shell_out).with("/usr/bin/lsscsi --hosts --verbose").and_return(mock_shell_out(0, @lsscsi_hosts, ""))
   allow(@plugin).to receive(:shell_out).with("/usr/bin/lsscsi --verbose").and_return(mock_shell_out(0, @lsscsi, ""))
  end

  describe "Gathering information from lssci --verbose" do

    it "should not raise an error" do
      expect { @plugin.run }.not_to raise_error
    end

    it "should find type" do
      @plugin.run
      expect(@plugin[:scsi][:logical_units]['2:0:0:0'][:type]).to eq("disk")
    end

  end

end

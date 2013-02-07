default["rithis-guests"]["iso"] = {
    "ubuntu-12.04-server-amd64" => "http://www.ubuntu.com/start-download?distro=server&bits=64&release=lts"
}

default["rithis-guests"]["networks"]["default"] = {
    "nat" => true,
    "bridge" => "virbr0",
    "ip" => {
        "address" => "192.168.122.1",
        "netmask" => "255.255.255.0"
    },
    "dhcp_range" => {
        "start" => "192.168.122.2",
        "end" => "192.168.122.254"
    },
    "dhcp_hosts" => []
}

default["rithis-guests"]["domains"] = {}

default["rithis-guests"]["iso_directory"] = "/var/iso"
default["rithis-guests"]["lvm_group"] = "virvg"

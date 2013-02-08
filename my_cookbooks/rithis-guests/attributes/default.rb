default["rithis-guests"]["iso"] = {
    "ubuntu-12.04-server-amd64" => "http://www.ubuntu.com/start-download?distro=server&bits=64&release=lts"
}

default["rithis-guests"]["networks"]["default"] = {
    "forward" => {
        "mode" => "nat"
    },
    "vpn" => false,
    "bridge" => "virbr0",
    "mac" => "52:54:00:00:00:01",
    "network" => "192.168.122.0/24",
    "hosts" => []
}

default["rithis-guests"]["domains"] = {}

default["rithis-guests"]["iso_directory"] = "/var/iso"
default["rithis-guests"]["lvm_group"] = "virvg"

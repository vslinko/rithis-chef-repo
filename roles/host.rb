name "host"

run_list(
    "role[node]",
    "recipe[chef-server]",
    "recipe[ntp]",
    "recipe[openvpn]",
    "recipe[openvpn::users]",
    "recipe[rithis-guests]"
)

override_attributes(
    "ntp" => {
        "servers" => %w{ntp1.hetzner.de ntp2.hetzner.com ntp3.hetzner.net}
    },
    "openvpn" => {
        "routes" => ["push 'route 192.168.122.0 255.255.255.0'"],
        "script_security" => 2,
        "key" => {
            "country" => "RU",
            "province" => "Moscow",
            "city" => "Moscow",
            "org" => "Rithis Studio, LLC",
            "email" => "webmaster@rithis.com"
        }
    },
    "rithis-guests" => {
        "networks" => {
            "default" => {
                "vpn" => true
            }
        }
    }
)

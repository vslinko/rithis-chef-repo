name "host"
run_list "role[node]", "recipe[chef-server]", "recipe[ntp]"

override_attributes(
    "ntp" => {
        "servers" => %w{ntp1.hetzner.de ntp2.hetzner.com ntp3.hetzner.net}
    }
)

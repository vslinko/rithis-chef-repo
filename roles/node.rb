name "node"

run_list(
    "recipe[apt]",
    "recipe[git]",
    "recipe[sudo]",
    "recipe[ubuntu]",
    "recipe[users::sysadmins]",
    "recipe[zsh]"
)

override_attributes(
    "authorization" => {
        "sudo" => {
            "passwordless" => true,
            "sudoers_defaults" => "env_reset"
        }
    },
    "ubuntu" => {
        "archive_url" => "http://mirror.hetzner.de/ubuntu/packages",
        "security_url" => "http://mirror.hetzner.de/ubuntu/security",
        "include_source_packages" => false
    }
)

include_recipe "lvm"

iso_directory = node["rithis-guests"]["iso_directory"]
vg = node["rithis-guests"]["lvm_group"]

package "qemu-kvm"
package "libvirt-bin"

chef_gem "ipaddress" do
    action :install
end

require "ipaddress"

directory iso_directory do
    mode 00755
end

node["rithis-guests"]["iso"].each do |name, url|
    iso_path = "#{iso_directory}/#{name}.iso"
    
    remote_file iso_path do
        backup false
        mode 00644
        source url
        not_if do
            File.exists?(iso_path)
        end
    end
end

node["rithis-guests"]["networks"].each do |name, network|
    network["name"] = name
    definition = "/etc/libvirt/qemu/networks/#{name}.definition.xml"

    ip = IPAddress::IPv4.new network["network"]
    network["ip"] = {
        "address" => ip.first.address,
        "netmask" => ip.first.netmask
    }
    network["dhcp_range"] = {
        "start" => ip.hosts[1].address,
        "end" => ip.last.address
    }

    template definition do
        backup false
        source "network.xml.erb"
        mode 00644
        variables :network => network
        notifies :run, "execute[virsh-net-redefine-#{name}]"
    end

    execute "virsh-net-redefine-#{name}" do
        command <<-EOH
            virsh net-list | grep '#{name}' && virsh net-destroy #{name} || true
            virsh net-list --all | grep '#{name}' && virsh net-undefine #{name} || true
            virsh net-define #{definition}
            virsh net-start #{name}
            virsh net-autostart #{name}
        EOH
        action :nothing
    end

    if network["vpn"]
        input = "FORWARD -d #{network["network"]} -i tun0 -o #{network["bridge"]} -j ACCEPT"
        output = "FORWARD -s #{network["network"]} -i #{network["bridge"]} -o tun0 -j ACCEPT"

        execute "allow-input-vpn-#{name}" do
            command "iptables -I #{input}"
            action :nothing
        end

        execute "allow-output-vpn-#{name}" do
            command "iptables -I #{output}"
            action :nothing
        end

        ruby_block "check-vpn-forwarding-#{name}" do
            block do
                iptables = `iptables-save`
                unless iptables.include? input
                    notifies :run, resources(:execute => "allow-input-vpn-#{name}")
                end
                unless iptables.include? output
                    notifies :run, resources(:execute => "allow-output-vpn-#{name}")
                end
            end
        end
    end
end

node["rithis-guests"]["domains"].each do |name, domain|
    domain["name"] = name
    domain["iso"] ||= "ubuntu-12.04-server-amd64"
    domain["iso_path"] = "#{iso_directory}/#{domain["iso"]}.iso"
    definition = "/etc/libvirt/qemu/#{name}.definition.xml"

    target = "vda"
    domain["disks"].each do |disk|
        lvm_logical_volume disk["name"] do
            group vg
            size disk["size"]
        end

        disk["source"] = "/dev/#{vg}/#{disk["name"]}"
        disk["target"] = target
        disk["bootable"] = target == "vda"
        target = target.next
    end

    template definition do
        backup false
        source "domain.xml.erb"
        mode 00644
        variables :domain => domain
        notifies :run, "execute[virsh-redefine-#{name}]"
    end

    execute "virsh-redefine-#{name}" do
        command <<-EOH
            virsh list | grep '#{name}' && virsh shutdown #{name}; sleep 5 || true
            virsh list | grep '#{name}' && virsh destroy #{name}; sleep 3 || true
            virsh list --all | grep '#{name}' && virsh undefine #{name} || true
            virsh define #{definition}
            virsh start #{name}
            virsh autostart #{name}
        EOH
        action :nothing
    end
end

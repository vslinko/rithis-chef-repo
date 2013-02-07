include_recipe "lvm"

iso_directory = node["rithis-guests"]["iso_directory"]
vg = node["rithis-guests"]["lvm_group"]

package "qemu-kvm"
package "libvirt-bin"

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
end

node["rithis-guests"]["domains"].each do |name, domain|
    domain["name"] = name
    domain["disk"] = "/dev/#{vg}/#{name}"
    domain["iso"] ||= "ubuntu-12.04-server-amd64"
    domain["iso_path"] = "#{iso_directory}/#{domain["iso"]}.iso"
    definition = "/etc/libvirt/qemu/#{name}.definition.xml"

    lvm_logical_volume name do
        group vg
        size domain["disk_size"]
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

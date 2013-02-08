name "rithis-guests"
version "0.0.2"

%w{ubuntu}.each do |os|
    supports os
end

%w{lvm}.each do |cookbook|
    depends cookbook
end

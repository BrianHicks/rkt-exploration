num_instances = 3
vm_names = (1..num_instances).map { |i| "rkt-%02d" % [i] }
ips = (1..num_instances).map { |i| "10.0.1.#{100+i}" }

Vagrant.configure('2') do |config|
  # grab Centos 7 official image
  config.vm.box = "centos/7"

  (1..num_instances).each do |i|
    config.vm.define vm_names[i-1] do |host|
      host.vm.provider :virtualbox do |vb, override|
        # add more ram, the default isn't enough for the build
        vb.customize ["modifyvm", :id, "--memory", "1024"]
      end

      host.vm.synced_folder ".", "/vagrant", type: "rsync"

      host.vm.hostname = vm_names[i-1]
      host.vm.network :private_network, ip: ips[i-1]

      # tell the hosts about each other
      host.vm.provision :shell, :inline => "[ -d /etc/meta ] || mkdir /etc/meta", :privileged => true
      host.vm.provision :shell, :inline => "echo -en '#{ips.join("\n")}' > /etc/meta/leader_ips", :privileged => true
      host.vm.provision :shell, :inline => "echo #{ips[i-1]} > /etc/meta/private_ip", :privileged => true
      host.vm.provision :shell, :inline => "echo #{vm_names[i-1]} > /etc/meta/hostname", :privileged => true

      ["base.sh", "install-rkt.sh", "install-acbuild.sh", "install-etcd.sh", "install-calico.sh"].map do |script|
        host.vm.provision :shell, :privileged => true, :path => "scripts/#{script}"
      end
    end
  end
end

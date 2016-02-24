Vagrant.configure('2') do |config|
    # grab Centos 7 official image
    config.vm.box = "centos/7"

    # fix issues with slow dns http://serverfault.com/a/595010
    config.vm.provider :virtualbox do |vb, override|
        vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ["modifyvm", :id, "--natdnsproxy1", "on"]
        # add more ram, the default isn't enough for the build
        vb.customize ["modifyvm", :id, "--memory", "1024"]
    end

    config.vm.synced_folder ".", "/vagrant", type: "rsync"

    ["base.sh", "install-rkt.sh", "install-acbuild.sh"].map do |script|
      config.vm.provision :shell, :privileged => true, :path => "scripts/#{script}"
    end
end

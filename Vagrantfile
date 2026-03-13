# -*- mode: ruby -*-
# vi: set ft=ruby :

# VM array
# Массив виртмашин
virt_machines=[
  {
    :hostname => "StarcevDA-3",
    :ip => "192.168.123.14"
  },
  {
    :hostname => "StarcevDA-4",
    :ip => "192.168.123.15"
  },
  {
    :hostname => "StarcevDA-5",
    :ip => "192.168.123.16"
  }
]

# Show VM GUI
# Показывать гуй виртмашины
HOST_SHOW_GUI = false 

# VM RAM
# Оперативная память ВМ
HOST_MEMMORY = "1024" 

# VM vCPU
# Количество ядер ВМ
HOST_CPUS = 1

# Network adapter to bridge - убираем, так как используем существующие ВМ
# HOST_BRIDGE = "Intel(R) Wireless-AC 9560"

# Which box to use - можно оставить любой, но он не будет использоваться
HOST_VM_BOX = "generic/ubuntu2004" 

################################################
# Parameters passed to provision script
# Параметры передаваемые в скрипт инициализации
################################################

# Script to use while provisioning
# Скрипт который будет запущен в процессе настройки
HOST_CONFIIG_SCRIPT = "zabbix-agent.sh" 

# Additional user
# Дополнительный пользователь
HOST_USER = 'test'

# Additional user pass. Root pass will be same
# Пароль дополнительного пользователя. Пароль рута будет таким же
HOST_USER_PASS = '123456789' 

# Run apt dist-upgrade
# Выполнить apt dist-upgrade
HOST_UPGRADE = 'false' 

# IP адрес Zabbix сервера
ZABBIX_SERVER_IP = '192.168.123.10'

Vagrant.configure("2") do |config|
  # Отключаем проверку бокса (так как используем существующие ВМ)
  config.vm.box_check_update = false
  
  virt_machines.each do |machine|
    config.vm.define machine[:hostname] do |node|
      # Не указываем box, так как ВМ уже созданы вручную
      # config.vm.box = HOST_VM_BOX
      
      node.vm.hostname = machine[:hostname]
      
      # Используем существующие ВМ в VirtualBox
      node.vm.provider "virtualbox" do |vb|
        vb.name = machine[:hostname]
        vb.gui = HOST_SHOW_GUI
        vb.memory = HOST_MEMMORY
        vb.cpus = HOST_CPUS
        
        # Настройки для уже существующей ВМ
        vb.customize ["modifyvm", :id, "--nic1", "hostonly"]
        vb.customize ["modifyvm", :id, "--hostonlyadapter1", "VirtualBox Host-Only Ethernet Adapter #2"]
        vb.customize ["modifyvm", :id, "--nic2", "nat"]
        vb.customize ["modifyvm", :id, "--cableconnected1", "on"]
        vb.customize ["modifyvm", :id, "--cableconnected2", "on"]
      end
      
      # Настройка сети внутри ВМ
      node.vm.provision "shell", run: "always", inline: <<-SHELL
        # Настройка интерфейсов
        sudo dhclient enp0s3 2>/dev/null || true
        sudo dhclient enp0s8 2>/dev/null || true
      SHELL
      
      # Скрипт установки Zabbix-агента
      node.vm.provision "shell", 
        path: HOST_CONFIIG_SCRIPT, 
        args: [ 
          HOST_USER, 
          HOST_USER_PASS, 
          HOST_UPGRADE, 
          machine[:hostname], 
          machine[:ip], 
          ZABBIX_SERVER_IP
        ], 
        run: "once"
    end
  end
end
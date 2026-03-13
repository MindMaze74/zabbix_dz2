#!/bin/bash
# repo override
#kz
sed -i 's/us.archive.ubuntu.com/mirror.hoster.kz/g' /etc/apt/sources.list
#ru
#sed -i 's/us.archive.ubuntu.com/mirror.linux-ia64.org/g' /etc/apt/sources.list

# Создание пользователя test
useradd $1 -s /bin/bash -d /home/test
mkdir /home/test
chown -R test:test /home/test
echo ''$1'    ALL=(ALL:ALL) NOPASSWD: ALL' >> /etc/sudoers

# Установка паролей для root и test
usermod --password $(openssl passwd -6 $2) root
usermod --password $(openssl passwd -6 $2) $1

# Опциональное обновление системы
if [ $3 == "true" ]; then apt update && apt upgrade -y; else echo "Обновление пропущено"; fi

# Настройка hosts файла
rm -Rf /etc/hosts
echo "127.0.0.1	localhost.localdomain	localhost" >> /etc/hosts
echo "$5	$4.localdomain	$4" >> /etc/hosts

echo "*******************************************************************************"
echo "************************** INSTALLING ZABBIX-AGENT ****************************"
echo "*******************************************************************************"

# Установка Zabbix-agent для Ubuntu 20.04/22.04
wget https://repo.zabbix.com/zabbix/6.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_6.0-4%2Bubuntu20.04_all.deb
dpkg -i zabbix-release_6.0-4+ubuntu20.04_all.deb
apt update 
apt install zabbix-agent -y

# Настройка конфигурации Zabbix-агента
sed -i "s/Server=127.0.0.1/Server=$6/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/^# ServerActive=.*/ServerActive=$6/g" /etc/zabbix/zabbix_agentd.conf
sed -i "s/^Hostname=.*/Hostname=$4/g" /etc/zabbix/zabbix_agentd.conf

# Добавление пользовательских параметров
echo "UserParameter=custom.system.uptime,uptime | awk '{print \$3}' | sed 's/,//'" >> /etc/zabbix/zabbix_agentd.conf
echo "UserParameter=custom.system.hostname,hostname" >> /etc/zabbix/zabbix_agentd.conf
echo "UserParameter=custom.system.kernel,uname -r" >> /etc/zabbix/zabbix_agentd.conf
echo "UserParameter=custom.disk.root,df -h / | awk 'NR==2 {print \$5}'" >> /etc/zabbix/zabbix_agentd.conf
echo "UserParameter=custom.process.ssh,ps aux | grep -c sshd" >> /etc/zabbix/zabbix_agentd.conf
echo "UserParameter=custom.users,who | wc -l" >> /etc/zabbix/zabbix_agentd.conf

# Оригинальные пользовательские параметры из шаблона
echo 'UserParameter=custom_echo[*],echo $1' >> /etc/zabbix/zabbix_agentd.conf
echo 'UserParameter=my_script[*], python3 /etc/zabbix/test_python_script.py $1 $2' > /etc/zabbix/zabbix_agentd.d/test_user_parameter.conf

# Перезапуск и включение автозапуска
systemctl restart zabbix-agent
systemctl enable zabbix-agent

# Создание Python-скрипта для пользовательских проверок
if [[ ! -f /etc/zabbix/test_python_script.py ]]
then
    echo 'import sys' >> /etc/zabbix/test_python_script.py
    echo 'import os' >> /etc/zabbix/test_python_script.py
    echo 'import re' >> /etc/zabbix/test_python_script.py
    echo 'if (sys.argv[1] == "-ping"): # Если -ping' >> /etc/zabbix/test_python_script.py
    echo '        result=os.popen("ping -c 1 " + sys.argv[2]).read() # Делаем пинг по заданному адресу' >> /etc/zabbix/test_python_script.py
    echo '        result=re.findall(r"time=(.*) ms", result) # Выдёргиваем из результата время' >> /etc/zabbix/test_python_script.py
    echo '        print(result[0]) # Выводим результат в консоль' >> /etc/zabbix/test_python_script.py
    echo 'elif (sys.argv[1] == "-simple_print"): # Если simple_print ' >> /etc/zabbix/test_python_script.py
    echo '        print(sys.argv[2]) # Выводим в консоль содержимое sys.argv[2]' >> /etc/zabbix/test_python_script.py
    echo 'else: # Во всех остальных случаях' >> /etc/zabbix/test_python_script.py
    echo '        print(f"unknown input: {sys.argv[1]}") # Выводим непонятый запрос в консоль.' >> /etc/zabbix/test_python_script.py
fi

# Проверка статуса
echo "Проверка статуса Zabbix Agent:"
systemctl status zabbix-agent --no-pager | grep Active

echo "*******************************************************************************"
echo "********************************* END *****************************************"
echo "*******************************************************************************"
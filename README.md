# Настройка сервера Hetzner для инфраструктуры студии

## Заказ сервера и установка системы

При заказе нового сервера нужно выбрать галочку `Rescue system` (система
восстановления) вместо выбора операционной системы. Это позволит настроить
разбивку жесткого диска.

Через некоторое время после заказа придет письмо с доступом к системе
восстановления. В этом письме будут IP адрес нового сервера и пароль
от пользователя root. Допустим IP адрес нашего сервера `144.76.18.85`.
Присоеденитесь к нему:

```
$ ssh root@144.76.18.85
```

Запустите процесс установки системы:

```
root@rescue ~ # installimage
```

Выберите систему `Ubuntu`. Выберите версию `Ubuntu-1204-precise-64-minimal`.
После предупреждения откроется редактор с настройкой процесса установки.
В этом файле удалите следующие строчки используя клавишу `F8`:

```
HOSTNAME Ubuntu-1204-precise-64-minimal
PART swap swap 16G
PART /boot ext3 512M
PART / ext4 1024G
PART /home ext4 all
```

Вместо удаленных строчек впишите следующие:

```
HOSTNAME host0.n.rithis.com
PART /boot ext2 512M
PART lvm sysvg 36G
PART lvm virvg all
LV sysvg root / ext3 32G
LV sysvg swap swap swap all
```

Сохраните настройки используя клавишу `F10`. Согласитесь с двумя
предупреждениями. После этого начнется установка:

```

                Hetzner Online AG - installimage

  Your server will be installed now, this will take some minutes
             You can abort at any time with CTRL+C ...

         :  Reading configuration                           done 
   1/15  :  Deleting partitions                             done 
   2/15  :  Test partition size                             done 
   3/15  :  Creating partitions and /etc/fstab              done 
   4/15  :  Creating software RAID level 1                  done 
   5/15  :  Creating LVM volumes                            busy   No volume groups found
                                                            done 
   6/15  :  Formatting partitions
         :    formatting /dev/md/0 with ext2                done 
         :    formatting /dev/sysvg/root with ext3          done 
         :    formatting /dev/sysvg/swap with swap          done 
   7/15  :  Mounting partitions                             done 
   8/15  :  Extracting image (local)                        done 
   9/15  :  Setting up network for eth0                     done 
  10/15  :  Executing additional commands
         :    Generating new SSH keys                       done 
         :    Generating mdadm config                       done 
         :    Generating ramdisk                            done 
         :    Generating ntp config                         done 
         :    Setting hostname                              done 
  11/15  :  Setting up miscellaneous files                  done 
  12/15  :  Setting root password                           done 
  13/15  :  Installing bootloader grub                      done 
  14/15  :  Running some ubuntu specific functions          done 
  15/15  :  Clearing log files                              done 

                  INSTALLATION COMPLETE
   You can now reboot and log in to your new system with
  the same password as you logged in to the rescue system.

```

Перезагрузите сервер:

```
root@rescue ~ # reboot
```

После перезагрузки сервер будет с нужной версией ОС и правильной разбивкой
дисков.

## Создание пользователя

Если вы используете Linux или OS X, то удалите запись о ssh-ключе сервера:

```
$ mv ~/.ssh/known_hosts{,.temp}
$ grep -v 144.76.18.85 ~/.ssh/known_hosts.temp > ~/.ssh/known_hosts
$ rm ~/.ssh/known_hosts.temp
```

Присоеденитесь к серверу:

```
$ ssh root@144.76.18.85
```

Создайте своего пользователя, например `vyacheslav`, задайте ему пароль
и сделайте его администратором системы:

```
root@host0 ~ # useradd -ms /bin/bash vyacheslav
root@host0 ~ # passwd vyacheslav
root@host0 ~ # adduser vyacheslav admin
```

Удалите пароль пользователя root и отключитесь от сервера.

```
root@host0 ~ # passwd -d root
root@host0 ~ # exit
```

## Обновление системы

Зайдите под созданным пользователем:

```
$ ssh 144.76.18.85
```

Обновите систему:

```
vyacheslav@host0:~$ sudo aptitude update
vyacheslav@host0:~$ sudo aptitude upgrade -y
```

Перезагрузите сервер:

```
vyacheslav@host0:~$ sudo reboot
```

## Установка Chef

Присоеденитесь к серверу:

```
$ ssh 144.76.18.85
```

Добавьте репозиторий Opscode:

```
vyacheslav@host0:~$ echo "deb http://apt.opscode.com/ `lsb_release -cs`-0.10 main" | sudo tee /etc/apt/sources.list.d/opscode.list
vyacheslav@host0:~$ gpg --keyserver keys.gnupg.net --recv-keys 83EF826A
vyacheslav@host0:~$ gpg --export packages@opscode.com | sudo tee /etc/apt/trusted.gpg.d/opscode-keyring.gpg > /dev/null
vyacheslav@host0:~$ sudo aptitude update
vyacheslav@host0:~$ sudo aptitude install opscode-keyring
```

Установите Chef:

```
vyacheslav@host0:~$ sudo aptitude install chef chef-server-api chef-expander
```

Во время установки нужно будет ввести адрес сервера Chef — введите
`http://host0.n.rithis.com:4000`. Пароль для AMPQ введите произвольный.

Настройте Knife на сервере:

```
vyacheslav@host0:~$ mkdir -p ~/.chef
vyacheslav@host0:~$ sudo cp /etc/chef/validation.pem /etc/chef/webui.pem ~/.chef
vyacheslav@host0:~$ sudo chown -R vyacheslav ~/.chef
vyacheslav@host0:~$ knife configure --initial --defaults --server-url http://host0.n.rithis.com:4000 --admin-client-key ~/.chef/webui.pem --validation-key ~/.chef/validation.pem --repository ""
vyacheslav@host0:~$ rm ~/.chef/webui.pem
```

Скачайте cookbooks на свою систему:

```
vyacheslav@host0:~$ exit
$ git clone git://github.com/rithis/rithis-chef-repo.git
$ cd rithis-chef-repo
$ sudo bundle install
$ librarian-chef install
```

Настройте Knife на своей системе:

```
$ rm -r ~/.chef
$ scp -r 144.76.18.85:.chef ~/.chef
$ rm ~/.chef/knife.rb
$ knife configure --defaults --server-url http://144.76.18.85:4000 --admin-client-key ~/.chef/webui.pem --validation-key ~/.chef/validation.pem --repository "$(pwd)"
```

Загрузите настройки на сервер:

```
$ knife cookbook upload --all
$ knife role from file roles/*
$ knife data bag create users
$ knife data bag from file users data_bag/users/*
```

Настройте систему:

```
$ knife bootstrap 144.76.18.85 --run-list 'role[host]' --ssh-user vyacheslav --sudo
```

Скопируйте файлы для аутентификации для OpenVPN на свою систему:

```
$ scp -r 144.76.18.85:vpn ~/VPN
```

Подключитесь к OpenVPN установленному на сервере. Используйте ваш любимый
OpenVPN клиент. Настройки подключения (названия могут не совпадать с вашим
клиентом):

<table>
  <tr>
    <th>Name</th>
    <td>host0.n.rithis.com</td>
  </tr>
  <tr>
    <th>Address</th>
    <td>144.76.18.85</td>
  </tr>
  <tr>
    <th>Port</th>
    <td>1194</td>
  </tr>
  <tr>
    <th>Protocol</th>
    <td>udp</td>
  </tr>
  <tr>
    <th>Device</th>
    <td>tun</td>
  </tr>
  <tr>
    <th>CA</th>
    <td>~/VPN/ca.crt</td>
  </tr>
  <tr>
    <th>Cert</th>
    <td>~/VPN/vyacheslav.crt</td>
  </tr>
  <tr>
    <th>Key</th>
    <td>~/VPN/vyacheslav.key</td>
  </tr>
  <tr>
    <th>Enable DNS support</th>
    <td>Yes</td>
  </tr>
  <tr>
    <th>DNS servers</th>
    <td>192.168.122.1</td>
  </tr>
  <tr>
    <th>DSN domain</th>
    <td>n.rithis.com</td>
  </tr>
</table>

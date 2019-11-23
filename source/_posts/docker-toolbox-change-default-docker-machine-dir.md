---
title: Windows Docker Toolbox替换默认docker machine的存储位置
date: 2019-11-07 21:20:29
tags:
- docker
- windows
categories:
- docker
---

### 需求说明 ###
安装完Docker Toolbox后，默认docker machine的存储位置为<code>C:\Users\39260\.docker\machine\machines</code>，
随着对虚机的使用会导虚拟硬盘所占空间越来越大，严重了会导致C盘空间空间告警！

<!-- more -->

### 设置默认docker machine存储目录 ###
1.选择一块空间充足的磁盘，新建虚机存储目录，这里选择目录为<code>H:\VM\machines</code>，
并将目录添加到系统环境变量<code>MACHINE_STORAGE_PATH</code>
2.添加环境变量<code>VBOX_INSTALL_PATH</code>,其值为<code>virtual安装目录</code>，这里为<code>C:\Program Files\Oracle\VirtualBox</code>
3.复制boot2docker.iso到<code>H:\VM\machines\cache</code>

### 新建docker machine ###
1.停止并删除已有虚机
```
PS C:\Users\39260> docker-machine.exe stop default
PS C:\Users\39260> docker-machine.exe rm default
```
2.以**管理员**身份运行<code>Docker QuickStart Terminal</code>,并等待所有设置完成，这步很重要！
3.等待出现下列显示即可关闭<code>Docker QuickStart Terminal</code>终端，并在没有管理员权限的情况下再次运行。
```
Running pre-create checks...
Creating machine...
(default) Copying H:\VM\machines\cache\boot2docker.iso to H:\VM\machines\machines\default\boot2docker.iso...
(default) Creating VirtualBox VM...
(default) Creating SSH key...
(default) Starting the VM...
(default) Check network to re-create if needed...
(default) Windows might ask for the permission to configure a dhcp server. Sometimes, such confirmation window is minimized in the taskbar.
(default) Waiting for an IP...
Waiting for machine to be running, this may take a few minutes...
Detecting operating system of created instance...
Waiting for SSH to be available...
Detecting the provisioner...
Provisioning with boot2docker...
Copying certs to the local machine directory...
Copying certs to the remote machine...
Setting Docker configuration on the remote daemon...

This machine has been allocated an IP address, but Docker Machine could not
reach it successfully.

SSH for the machine should still work, but connecting to exposed ports, such as
the Docker daemon port (usually <ip>:2376), may not work properly.

You may need to add the route manually, or use another related workaround.

This could be due to a VPN, proxy, or host file configuration issue.

You also might want to clear any VirtualBox host only interfaces you are not using.
Checking connection to Docker...
Docker is up and running!
To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: H:\Docker Toolbox\docker-machine.exe env default



                        ##         .
                  ## ## ##        ==
               ## ## ## ## ##    ===
           /"""""""""""""""""\___/ ===
      ~~~ {~~ ~~~~ ~~~ ~~~~ ~~~ ~ /  ===- ~~~
           \______ o           __/
             \    \         __/
              \____\_______/

docker is configured to use the default machine with IP 192.168.99.100
For help getting started, check out the docs at https://docs.docker.com

Start interactive shell

39260@pureven MINGW64 ~
```

### 验证 ###
boot2docker用户名和密码：

| 用户名 | 密码 | 进入方式 |
| :----: | :----: | :----:|
| docker | tcuser | ssh |
| root |  | command:sudo -i(docker用户下执行) |

1.打开<code>Git Bash</code>,启动虚拟机default
```
39260@pureven MINGW64 ~
$ docker-machine.exe  start default
Starting "default"...
(default) Check network to re-create if needed...
(default) Windows might ask for the permission to configure a dhcp server. Sometimes, such confirmation window is minimized in the taskbar.
(default) Waiting for an IP...
Machine "default" was started.
Waiting for SSH to be available...
Detecting the provisioner...
Started machines may have new IP addresses. You may need to re-run the `docker-machine env` command.

```
2.执行<code>docker-machine create --driver=virtualbox pureven</code>，创建虚拟机pureven
```
39260@pureven MINGW64 ~
$ docker-machine.exe create --driver=virtualbox pureven
Running pre-create checks...
Creating machine...
(pureven) Copying H:\VM\machines\cache\boot2docker.iso to H:\VM\machines\machines\pureven\boot2docker.iso...
(pureven) Creating VirtualBox VM...
(pureven) Creating SSH key...
(pureven) Starting the VM...
(pureven) Check network to re-create if needed...
(pureven) Windows might ask for the permission to configure a dhcp server. Sometimes, such confirmation window is minimized in the taskbar.
(pureven) Waiting for an IP...
Waiting for machine to be running, this may take a few minutes...
Detecting operating system of created instance...
Waiting for SSH to be available...
Detecting the provisioner...
Provisioning with boot2docker...
Copying certs to the local machine directory...
Copying certs to the remote machine...
Setting Docker configuration on the remote daemon...

This machine has been allocated an IP address, but Docker Machine could not
reach it successfully.

SSH for the machine should still work, but connecting to exposed ports, such as
the Docker daemon port (usually <ip>:2376), may not work properly.

You may need to add the route manually, or use another related workaround.

This could be due to a VPN, proxy, or host file configuration issue.

You also might want to clear any VirtualBox host only interfaces you are not using.
Checking connection to Docker...
Docker is up and running!
To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: H:\Docker Toolbox\docker-machine.exe env pureven

```

### 注意事项 ###
1.改变docker machine的存储位置之后会导致<code>Windows PowerShell</code>无法使用<code>docker-machine</code>,目前尚未解决！可使用<code>Git Bash</code>代替。

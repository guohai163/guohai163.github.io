---
layout: post
title:  "在RHEL系统上通过源码安装GITLAB"
date:   2016-2-1 20:59:06
categories: rhel gitlab source mysql
---
#从源码安装Gitlab

　　Gitlab有著名的一键安装包，点一下脚本自动会帮你装ruby、Redis、Postgresql、Gitlab好方便，而且还会帮你解决Sidekiq无限消耗资源定期重启。有这么多优点为毛还要从源码安装Gitlab。1.CE版本无法使用Mysql库来存储用户数据 2.能了解他的``工作机理和细节呗``。
    官方的文档一直在使用Ubuntu来做例子，但在我们的生产环境全都是RHEL的机器所以这篇文档也以RHEL来进行讲解。此文档写于2015年1月31日，软件版本均为当时最新版本。

#安装总览
  0. 更新仓库源
  1. 安装必须的软件包
  2. 安装Ruby 2.3
  3. 安装Go语言 1.5.3
  4. 创建系统用户
  5. 安装数据库Mysql 5.5.46
  6. 安装Redis 2.8.23
  7. 安装GitLab 8.4.stable
  8. 安装Nginx

#0. 更新仓库源

RHEL操作系统默认仓库源在线更新是收费的，如果没有注册还能使用。我们使用CentOS的YUM源来进行。在中国大陆地区因GFW各种被禁。无奈我们使用网易源来安装各种YUM包。
    #删除源仓库
    rpm -qa |grep yum|xargs rpm -e --nodeps
    mkdir /tmp/yum && cd /tmp/yum

    wget -O /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6 http://mirrors.163.com/centos/6/os/x86_64/RPM-GPG-KEY-CentOS-6
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6

    wget http://mirrors.163.com/centos/6/os/x86_64/Packages/yum-3.2.29-69.el6.centos.noarch.rpm
    wget http://mirrors.163.com/centos/6/os/x86_64/Packages/yum-metadata-parser-1.1.2-16.el6.x86_64.rpm
    wget http://mirrors.163.com/centos/6/os/x86_64/Packages/yum-plugin-fastestmirror-1.1.30-30.el6.noarch.rpm
    wget http://mirrors.163.com/centos/6/os/x86_64/Packages/python-iniparse-0.3.1-2.1.el6.noarch.rpm
    #yum和yum-plugin-fastestmirror需要一起安装，这两个包存在依赖关系，分开安装会失败
    rpm -ivh python-iniparse-0.3.1-2.1.el6.noarch.rpm
    rpm -ivh yum-metadata-parser-1.1.2-16.el6.x86_64.rpm
    rpm -ivh yum-3.2.29-69.el6.centos.noarch.rpm yum-plugin-fastestmirror-1.1.30-30.el6.noarch.rpm
    #替换仓库
    wget -O /etc/yum.repos.d/CentOS6-Base-163.repo http://mirrors.163.com/.help/CentOS6-Base-163.repo
    #编辑文件CentOS-Base-163.repo，替换整个文件的$releasever为6
    #加载扩展名源EPEL
    wget -O /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6 http://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-6
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-6
    rpm -Uvh http://dl.fedoraproject.org/pub/epel/epel-release-latest-6.noarch.rpm

    #添加PUIAS仓库
    wget -O /etc/yum.repos.d/PUIAS_6_computational.repo https://gitlab.com/gitlab-org/gitlab-recipes/raw/master/install/centos/PUIAS_6_computational.repo

    wget -O /etc/pki/rpm-gpg/RPM-GPG-KEY-puias http://springdale.math.ias.edu/data/puias/6/x86_64/os/RPM-GPG-KEY-puias
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-puias
    #查看结果
    yum repolist
    #如果报错可以考虑把PUIAS的仓库从mirrorlist改为使用baseurl
    #最后结果应为
    仓库标识                仓库名称                                          状态
    PUIAS_6_computational   PUIAS computational Base $releasever - x86_64      3,270
    base                    CentOS-6 - Base - 163.com                          6,575
    epel                    Extra Packages for Enterprise Linux 6 - x86_64    12,004
    extras                  CentOS-6 - Extras - 163.com                           50
    updates                 CentOS-6 - Updates - 163.com                       1,218
    repolist: 23,117



#1.安装必须的软件包
安装需要如下的软件包

    yum -y update
    yum -y groupinstall 'Development Tools'
    yum -y install readline readline-devel ncurses-devel gdbm-devel glibc-devel tcl-devel openssl-devel curl-devel expat-devel db4-devel byacc sqlite-devel libyaml libyaml-devel libffi libffi-devel libxml2 libxml2-devel libxslt libxslt-devel libicu libicu-devel system-config-firewall-tui redis sudo wget crontabs logwatch logrotate perl-Time-HiRes git cmake libcom_err-devel.i686 libcom_err-devel.x86_64 nodejs
    #此步一定要确定所有的包都安装正确，否则下面会报莫明错误。

可选章节：安装Git，截至2016年1月RHEL通过YUM安装的GIT版本已经为1.8.3.1，可以跳过本步。否则

  	# Install dependencies
    yum -y install zlib-devel perl-CPAN gettext curl-devel expat-devel gettext-devel openssl-devel

  	# Download and compile from source
  	cd /tmp
  	curl -O --progress https://www.kernel.org/pub/software/scm/git/git-2.7.0.tar.gz
  	tar xzf git-2.7.0.tar.gz
  	cd git-2.7.0/
  	./configure
  	make prefix=/usr/local all
  	# Install into /usr/local/bin
  	make prefix=/usr/local install
    #在第5步的时候要编辑 config/gitlab.yml 文件修改git路径,  bin_path to /usr/local/bin/git

接下来我们还要安装一个邮件服务器，官方推荐使用postfix

	yum install -y postfix
	#Then select 'Internet Site' and press enter to confirm the hostname.

#2.安装Ruby
Ruby官方要求使用2.1以上版本，如果系统带低版本，请卸载`sudo apt-get remove rubyx.x`。我们使用源码进行安装

	mkdir /tmp/ruby && cd /tmp/ruby
	curl -O --progress https://cache.ruby-lang.org/pub/ruby/2.3/ruby-2.3.0.tar.gz
	tar xzf ruby-2.3.0.tar.gz
	cd ruby-2.3.0
	./configure --disable-install-rdoc
	make
	make install

Gitlab的包使用bundler进行依赖关系管理，所以还得安装。如果在国内的用户请先修改Ruby的源服务器

	gem sources --add https://ruby.taobao.org/ --remove https://rubygems.org/
	#Check ruby source list
	gem sources -l

	gem install bundler --no-ri --no-rdoc

#3.安装Go语言支持
在GitLab8.0以后HTTP请求开始依赖Go编译，所以我们要进行安装，这里要注意Go会区分操作系统位数

	mkdir /tmp/golang && cd /tmp/golang
	curl -O --progress https://storage.googleapis.com/golang/go1.5.3.linux-amd64.tar.gz
	tar -C /usr/local -xzf go1.5.3.linux-amd64.tar.gz
	#32bit OS install
	#curl -O --progress https://storage.googleapis.com/golang/go1.5.3.linux-386.tar.gz
	tar -C /usr/local -xzf go1.5.3.linux-386.tar.gz
	sudo ln -sf /usr/local/go/bin/{go,godoc,gofmt} /usr/local/bin/

#4.创建系统用户

  adduser --system --shell /bin/bash --comment 'GitLab' --create-home --home-dir /home/git/ git
  #修改git用户的PATH路径
  visudo
  Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin
  #修改为
  Defaults    secure_path = /sbin:/bin:/usr/sbin:/usr/bin:/usr/local/bin



#5.安装数据库
官方默认推荐为PostgreSQLDB但因为没有使用经验备份经验，这里我们改用MySQL.但官方CE一键包不支持MYSQL这也是我们从源码安装的原因之一

	# Install the database packages
  yum install -y mysql-server mysql-devel
  chkconfig mysqld on
  service mysqld start

  mysql_secure_installation

	# Login to MySQL
	mysql -u root -p

	# Type the MySQL root password

	# Create a user for GitLab
	# do not type the 'mysql>', this is part of the prompt
	# change $password in the command below to a real password you pick
	mysql> CREATE USER 'git'@'localhost' IDENTIFIED BY '$password';

	# Ensure you can use the InnoDB engine which is necessary to support long indexes
	# If this fails, check your MySQL config files (e.g. `/etc/mysql/*.cnf`, `/etc/mysql/conf.d/*`) for the setting "innodb = off"
	mysql> SET storage_engine=INNODB;

	# Create the GitLab production database
	mysql> CREATE DATABASE IF NOT EXISTS `gitlabhq_production` DEFAULT CHARACTER SET `utf8` COLLATE `utf8_unicode_ci`;

	# Grant the GitLab user necessary permissions on the database
	mysql> GRANT SELECT, INSERT, UPDATE, DELETE, CREATE, CREATE TEMPORARY TABLES, DROP, INDEX, ALTER, LOCK TABLES ON `gitlabhq_production`.* TO 'git'@'localhost';

	# Quit the database session
	mysql> \q

	# Try connecting to the new database with the new user
	sudo -u git -H mysql -u git -p -D gitlabhq_production

	# Type the password you replaced $password with earlier

	# You should now see a 'mysql>' prompt

	# Quit the database session
	mysql> \q

	# You are done installing the database and can go back to the rest of the installation.

#6.安装Redis

  #设置REDIS为开机启动
  chkconfig redis on

修改 /etc/redis.conf 文件，在末尾增加

  unixsocket /var/run/redis/redis.sock
  unixsocketperm 0770

  #重启redis服务
  service redis restart
  #添加git用户到redis用户组
  usermod -aG redis git


#7.安装GitLab

	cd /home/git
	sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-ce.git -b 8-5-stable gitlab

	#configure it
	cd /home/git/gitlab

	# Copy the example GitLab config
	sudo -u git -H cp config/gitlab.yml.example config/gitlab.yml

	# Update GitLab config file, follow the directions at top of file
	sudo -u git -H editor config/gitlab.yml

	# Copy the example secrets file
	sudo -u git -H cp config/secrets.yml.example config/secrets.yml
	sudo -u git -H chmod 0600 config/secrets.yml

	# Make sure GitLab can write to the log/ and tmp/ directories
	chown -R git log/
	chown -R git tmp/
	chmod -R u+rwX,go-w log/
	chmod -R u+rwX tmp/

	# Make sure GitLab can write to the tmp/pids/ and tmp/sockets/ directories
	chmod -R u+rwX tmp/pids/
	chmod -R u+rwX tmp/sockets/

	# Make sure GitLab can write to the public/uploads/ directory
  sudo -u git -H mkdir public/uploads
	chmod -R u+rwX  public/uploads

	# Change the permissions of the directory where CI build traces are stored
	chmod -R u+rwX builds/

	# Change the permissions of the directory where CI artifacts are stored
	chmod -R u+rwX shared/artifacts/

	# Copy the example Unicorn config
	sudo -u git -H cp config/unicorn.rb.example config/unicorn.rb

	# Find number of cores
	nproc

	# Enable cluster mode if you expect to have a high load instance
	# Set the number of workers to at least the number of cores
	# Ex. change amount of workers to 3 for 2GB RAM server
	sudo -u git -H editor config/unicorn.rb

	# Copy the example Rack attack config
	sudo -u git -H cp config/initializers/rack_attack.rb.example config/initializers/rack_attack.rb

	# Configure Git global settings for git user, used when editing via web editor
	sudo -u git -H git config --global core.autocrlf input

	# Configure Redis connection settings
	sudo -u git -H cp config/resque.yml.example config/resque.yml

	# Change the Redis socket path if you are not using the default Debian / Ubuntu configuration
	sudo -u git -H editor config/resque.yml

###Configure GitLab DB Settings
下面的步骤因为我们使用Mysql来安装。

	sudo -u git cp config/database.yml.mysql config/database.yml
	# Update username/password in config/database.yml
	# Change 'secure password' with the value you have given to $password
	sudo -u git -H editor config/database.yml

	sudo -u git -H chmod o-rwx config/database.yml

###安装 Gems

	sudo -u git -H bundle install --deployment --without development test postgres aws kerberos

###安装GitLab Shell
此处请一定要修改配置文件里的gitlab_url节点，否则在提交时会报错，禁止提交

	# Run the installation task for gitlab-shell (replace `REDIS_URL` if needed):
	sudo -u git -H bundle exec rake gitlab:shell:install REDIS_URL=unix:/var/run/redis/redis.sock RAILS_ENV=production

	# By default, the gitlab-shell config is generated from your main GitLab config.
	# You can review (and modify) the gitlab-shell config as follows:
	sudo -u git -H editor /home/git/gitlab-shell/config.yml
###安装gitlab-workhorse
	cd /home/git
	sudo -u git -H git clone https://gitlab.com/gitlab-org/gitlab-workhorse.git
	cd gitlab-workhorse
	sudo -u git -H git checkout 0.5.4
	sudo -u git -H make

###初始化数据库

	# Go to GitLab installation folder

	cd /home/git/gitlab

	sudo -u git -H bundle exec rake gitlab:setup RAILS_ENV=production

	# Type 'yes' to create the database tables.

	# When done you see 'Administrator account created:'
  login.........root
  password......5iveL!fe

###安装初始化脚本

    cp lib/support/init.d/gitlab /etc/init.d/gitlab
    chkconfig --add gitlab

    chkconfig gitlab on

    cp lib/support/logrotate/gitlab /etc/logrotate.d/gitlab

    sudo -u git -H bundle exec rake gitlab:env:info RAILS_ENV=production

    sudo -u git -H bundle exec rake assets:precompile RAILS_ENV=production
    #启动服务
    service gitlab start

#8. 配置WebServer

这里官方建议使用nginx，当然如果你对apache足够熟悉也可以改用apache。

    yum -y install nginx
    chkconfig nginx on
    #如果你的机器上没能IPV6地址，一定要注释掉IPV6协议部分
    cp lib/support/nginx/gitlab /etc/nginx/conf.d/gitlab.conf
    #添加用户nginx到git组
    usermod -a -G git nginx
    chmod g+rx /home/git/

*如果这时访问报502并且在错误日志中提示 failed (13: Permission denied) 请关闭selinux*

    setenforce 0

#9. 测试

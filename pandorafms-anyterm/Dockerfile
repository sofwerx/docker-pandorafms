FROM centos:centos6

RUN { \
	echo '[EPEL]'; \
	echo 'name = CentOS Epel'; \
	echo 'baseurl = http://dl.fedoraproject.org/pub/epel/6/x86_64'; \
	echo 'enabled=1'; \
	echo 'gpgcheck=0'; \
} > /etc/yum.repos.d/extra_repos.repo

RUN { \
        echo '[artica_pandorafms]'; \
        echo 'name=CentOS6 - PandoraFMS official repo'; \
        echo 'baseurl=http://artica.es/centos6'; \
        echo 'gpgcheck=0'; \
        echo 'enabled=1'; \
} > /etc/yum.repos.d/pandorafms.repo

RUN yum -y update
RUN yum install -y anytermd

RUN /usr/sbin/useradd -d /home/pandora -s /bin/false -M -g 0 pandora

ENV PORT=8022

EXPOSE 8022

# Usage: anytermd [options]
# Available options:
#     --help                     Show this help message
#  -c|--command <cmd>            Command to run in terminal (default /bin/bash)
#  -d|--device <dev>             Device to connect to (e.g. serial port)
#  -p|--port <port>              Port number to listen on (default 8080)
#  -u|--user <user>              User to run as
#  -a|--auth none|null|trivial   Authorisation scheme to use (default none)
#  -s|--charset                  Character set to use (default ASCII)
#  -f|--foreground               Run in foreground (by default, backgrounds itself)
#     --diff                     Send only differences to browser (default)
#  -n|--nodiff                   Send whole screen to browser each time
#  -m|--max-sessions             Maximum number of simultaneous sessions (default 20)
#     --max-http-connections     Maximum number of simultaneous HTTP connections (default unlimited)
#     --local-only               Accept connections only from localhost
#     --name                     Name used for logging and pid file (default anytermd)

CMD anytermd -f -p $PORT -u pandora -c ssh


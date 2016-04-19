FROM alpine:latest 

MAINTAINER gigabeer@gmail.com

ENV UPDATED_AT 2016-04-19

RUN apk upgrade --update --available && \
apk add --no-cache \
bash \
supervisor \
fping \
tzdata \
rsyslog \
apache2 \
smokeping

RUN cp /usr/share/zoneinfo/Asia/Tokyo /etc/localtime && \
apk del tzdata && \
rm -rf /var/cache/apk/*

RUN echo $'PS1="[\u@\h \W]# "\n\
PATH=$PATH:$HOME/bin\n\
export PATH PS1' > /root/.bashrc && \
echo $'if [ -f ~/.bashrc ]; then\n\
  . ~/.bashrc\n\
fi' > /root/.bash_profile

RUN sed -i -e '/^$ModLoad imklog.so.*/d' \
-e '/^\*.emerg.*\*/d' \
-e '/^#.*/d' -e '/^$/d' /etc/rsyslog.conf

RUN sed -i -e 's/ServerTokens OS/ServerTokens Prod/' \
-e 's/ServerSignature On/ServerSignature Off/' \
-e 's/\#\(LoadModule cgi_module.*\)/\1/' \
-e 's/lib\/apache2\(\/mod_cgi\.so\)/modules\1/' /etc/apache2/httpd.conf && \
echo 'PidFile /run/apache2/httpd.pid' >> /etc/apache2/httpd.conf && \
/bin/bash -c "mkdir -p /run/apache2"

RUN echo $'Alias /cache /var/lib/smokeping/cache\n\
Alias /data /var/lib/smokeping/data\n\
Alias /cropper /usr/share/webapps/smokeping/cropper\n\
Alias /img /usr/share/webapps/smokeping/img\n\
ScriptAlias /smokeping.cgi /usr/share/webapps/smokeping/smokeping.cgi\n\
<Files smokeping.cgi>\n\
  AddHandler cgi-script .cgi\n\
  Options +ExecCGI\n\
  Require all granted\n\
</Files>\n\
<DirectoryMatch /usr/share/webapps/smokeping/(cropper|img)>\n\
  Require all granted\n\
</DirectoryMatch>\n\
<DirectoryMatch /var/lib/smokeping/(cache|data)>\n\
  Require all granted\n\
</DirectoryMatch>' >> /etc/apache2/conf.d/smokeping.conf

ADD config /etc/smokeping/config

RUN /bin/bash -c "mkdir -p /var/lib/smokeping/{cache,data}" && \
/bin/bash -c "chown apache.smokeping /var/lib/smokeping/{cache,data}"

ADD supervisord.conf /etc/supervisord.conf

EXPOSE 80

ENTRYPOINT ["/usr/bin/supervisord","-n","-c","/etc/supervisord.conf"]

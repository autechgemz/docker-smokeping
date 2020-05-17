FROM alpine:latest 

ENV TZ Asia/Tokyo

RUN apk upgrade --update --available && \
apk add --no-cache \
bash \
runit \
fping \
tzdata \
apache2 \
smokeping \
ttf-dejavu

RUN ln -snf /usr/share/zoneinfo/${TZ} /etc/localtime && \
rm -rf /var/cache/apk/*

RUN echo $'PS1="[\u@\h \W]# "\n\
PATH=$PATH:$HOME/bin\n\
export PATH PS1' > /root/.bashrc && \
echo $'if [ -f ~/.bashrc ]; then\n\
  . ~/.bashrc\n\
fi' > /root/.bash_profile

RUN sed -i -e 's/ServerTokens OS/ServerTokens Prod/' \
-e 's/ServerSignature On/ServerSignature Off/' \
-e 's/\#\(LoadModule cgi_module.*\)/\1/' \
-e 's/\(CustomLog logs\/access\.log combined\)/#\1/' \
-e 's/\#\(CustomLog logs\/access\.log common\)/\1/' \
-e 's/lib\/apache2\(\/mod_cgi\.so\)/modules\1/' /etc/apache2/httpd.conf && \
echo 'PidFile /run/apache2/httpd.pid' >> /etc/apache2/httpd.conf && \
/bin/bash -c "mkdir -p /run/apache2"

RUN echo $'Alias /cache /var/lib/smokeping/cache\n\
Alias /data /var/lib/smokeping/data\n\
Alias /cropper /usr/share/webapps/smokeping/cropper\n\
Alias /img /usr/share/webapps/smokeping/img\n\
Alias /js /usr/share/webapps/smokeping/js\n\
Alias /css /usr/share/webapps/smokeping/css\n\
ScriptAlias /smokeping.cgi /usr/share/webapps/smokeping/smokeping.cgi\n\
<Files smokeping.cgi>\n\
  AddHandler cgi-script .cgi\n\
  Options +ExecCGI\n\
  Require all granted\n\
</Files>\n\
<DirectoryMatch /usr/share/webapps/smokeping/(cropper|img|js|css)>\n\
  Require all granted\n\
</DirectoryMatch>\n\
<DirectoryMatch /var/lib/smokeping/(cache|data)>\n\
  Require all granted\n\
</DirectoryMatch>\n\
AddDefaultCharset Off' >> /etc/apache2/conf.d/smokeping.conf

COPY config /etc/smokeping/config

RUN /bin/bash -c "mkdir -p /var/lib/smokeping/{cache,data}" && \
/bin/bash -c "chown apache.smokeping /var/lib/smokeping/{cache,data}" && \
/bin/bash -c "rm -rf /etc/smokeping/examples"

RUN /bin/bash -c "ln -snf /dev/stdout /var/log/apache2/access.log" && \
/bin/bash -c "ln -snf /dev/stdout /var/log/apache2/error.log"

COPY services /services

RUN chmod +x /services/*/run

VOLUME ["/var/lib/smokeping"]

EXPOSE 80

ENTRYPOINT ["runsvdir", "-P", "/services"]

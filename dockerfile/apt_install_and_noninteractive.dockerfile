FROM  mariadb:5.5.63-trusty

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ 'Asia/Shanghai'
RUN set -ex; \
	\
	echo $TZ > /etc/timezone && \
	apt-get update && apt-get install -y tzdata && \
	rm /etc/localtime && \
	ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
	dpkg-reconfigure -f noninteractive tzdata; \
	rm -rf /var/lib/apt/lists/*;

RUN set -ex; \
	\
	fetchDeps=" \
	rsyslog-mysql \
	"; \
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps; \
	rm -rf /var/lib/apt/lists/*;

RUN set -ex; \
	\
	fetchDeps=" \
	wget \
	apache2 \
	"; \
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps; \
	rm -rf /var/lib/apt/lists/*;

RUN set -ex; \
	\
	fetchDeps=" \
	php5 \
	libapache2-mod-php5 \
	php5-mysql \
	php5-gd \
	php5-cli \
	"; \
	apt-get update; \
	apt-get install -y --no-install-recommends $fetchDeps; \
	rm -rf /var/lib/apt/lists/*;

RUN mkdir /tmp/loganalyzer
COPY ./loganalyzer-4.1.6.tar.gz /tmp/loganalyzer/

RUN set -ex; \
	\
	cd /tmp/loganalyzer; \
	# wget http://download.adiscon.com/loganalyzer/loganalyzer-4.1.6.tar.gz; \
	tar -xzvf loganalyzer-4.1.6.tar.gz; \
	mkdir /var/www/html/loganalyzer; \
	cp -r loganalyzer-4.1.6/src/* /var/www/html/loganalyzer; \
	rm -r /tmp/loganalyzer;


COPY config.php /var/www/html/loganalyzer/

RUN set -ex; \
	\
	cd /var/www/html/loganalyzer/; \
	# touch config.php; \
	chown www-data:www-data config.php; \
	chmod 666 config.php; \
	chown www-data:www-data -R /var/www/html/loganalyzer/; \
	cd /;

COPY loganalyzer.sql /

COPY loganalyzer_run.sh /

COPY maintenance.sh /

# mysql run background
#RUN sed -i '/^exec "$@"\s*$/c $@ &' /usr/local/bin/docker-entrypoint.sh
COPY  docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["/loganalyzer_run.sh"]

EXPOSE 514/udp 514/tcp 80/tcp

CMD ["mysqld"]




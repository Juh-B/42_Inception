FROM debian:bookworm

RUN apt-get update && apt-get install -y \
    nginx \
    openssl \
    && rm -f /etc/nginx/sites-enabled/default \
    && rm -rf /var/lib/apt/lists/*


COPY conf/nginx.conf /etc/nginx/conf.d/default.conf

COPY tools/init_nginx.sh /usr/local/bin/init_nginx.sh
RUN chmod +x /usr/local/bin/init_nginx.sh

EXPOSE 443

ENTRYPOINT ["/usr/local/bin/init_nginx.sh"]

CMD ["nginx", "-g", "daemon off;"]

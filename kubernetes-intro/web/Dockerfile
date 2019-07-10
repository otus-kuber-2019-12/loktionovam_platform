FROM nginx:1.17.1-alpine

LABEL maintainer="loktionovam@gmail.com"

ENV NGINX_HOST=localhost \
    NGINX_PORT=8000

# May be better to use COPY *.conf /etc/nginx/
# rather then use regex and heredoc

RUN adduser -S -D -H -u 1001 -h /app -s /sbin/nologin -g app app && \
    chown app: /etc/nginx/conf.d/ && \
    mkdir -p /app && \
    chown app: /app && \
    # Some ugly shit to fix nginx.conf to run server as a non-root user
    # see "Running nginx as a non-root user" https://hub.docker.com/_/nginx
    sed -i -E \
         -e 's/^pid .+/pid \/tmp\/nginx.pid;/g' \
         -e '/http.+\{/a include /etc/nginx/tmp.paths;' \
         -e '/user.+nginx;/d' /etc/nginx/nginx.conf && \
    echo -e 'server {\n\
    listen       ${NGINX_PORT};\n\
    server_name  ${NGINX_HOST};\n\
    location / {\n\
        root   /app;\n\
        index  index.html index.htm;\n\
    }\n\
}'\
>> /etc/nginx/conf.d/01-site.template && \
    echo -e '\n\
    client_body_temp_path /tmp/client_temp;\n\
    proxy_temp_path       /tmp/proxy_temp_path;\n\
    fastcgi_temp_path     /tmp/fastcgi_temp;\n\
    uwsgi_temp_path       /tmp/uwsgi_temp;\n\
    scgi_temp_path        /tmp/scgi_temp;' \
>> /etc/nginx/tmp.paths && \
    rm /etc/nginx/conf.d/default.conf

CMD /bin/ash -c "envsubst < /etc/nginx/conf.d/01-site.template > /etc/nginx/conf.d/01-site.conf && exec nginx -g 'daemon off;'"

EXPOSE ${NGINX_PORT}
USER app

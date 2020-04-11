FROM nginx:1.17.1-alpine

LABEL maintainer="loktionovam@gmail.com"

ENV NGINX_HOST=localhost \
    NGINX_PORT=8000 \
    NGINX_CRT="server.crt" \
    NGINX_KEY="server.key"

RUN adduser -S -D -H -u 1001 -h /app -s /sbin/nologin -g app app && \
    chown app: /etc/nginx/conf.d/ && \
    mkdir -p /app && \
    chown app: /app && \
    rm /etc/nginx/conf.d/default.conf

COPY nginx.conf tmp.paths /etc/nginx/
COPY site.conf.template /etc/nginx/conf.d/site.conf.template

# there are may be some issues with nginx variables (like $server and so on) and envsubst
CMD /bin/ash -c "envsubst < /etc/nginx/conf.d/site.conf.template > /etc/nginx/conf.d/site.conf && exec nginx -g 'daemon off;'"

EXPOSE ${NGINX_PORT}
USER app

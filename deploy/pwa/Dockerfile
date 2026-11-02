FROM nginx:stable-alpine
RUN apk add --no-cache ca-certificates
ENV UNIO_API_UPSTREAM=https://bot-1790421609-9641-larisfonkraft.bothost.tech
COPY nginx.conf /etc/nginx/templates/default.conf.template
COPY public/ /usr/share/nginx/html/
EXPOSE 8080

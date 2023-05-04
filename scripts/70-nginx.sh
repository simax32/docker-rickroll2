#!/bin/sh

set -eu

PORT="${PORT:-"8080"}"

# Create nginx conf with port variable
tee /etc/nginx/nginx.conf << 'EOF' >/dev/null
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /tmp/nginx.pid;

events {
    accept_mutex off;
    worker_connections  1024;
}

http {
    proxy_temp_path /tmp/proxy_temp;
    proxy_cache_path /tmp/mycache keys_zone=mycache:50m;
    client_body_temp_path /tmp/client_temp;
    fastcgi_temp_path /tmp/fastcgi_temp;
    uwsgi_temp_path /tmp/uwsgi_temp;
    scgi_temp_path /tmp/scgi_temp;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    include       /etc/nginx/conf.d/*.conf;
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    sendfile_max_chunk 512k;
    sendfile        on;
    tcp_nopush     on;
    keepalive_timeout  65;
    gzip  on;

    server {
        # add proxy caches
        listen       ${PORT};

        root /usr/share/nginx/html;
        index index.html;

        # Make site accessible from http://localhost/
        server_name _;

        error_page 404 /index.html;

        location /rtc {
            #try_files $uri $uri/ /index.html;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_pass      http://127.0.0.1:8088/janus;
        }

        location /rtcapp {
            # enable thread pools for livestream
            aio threads=default;

            proxy_pass http://localhost:8188;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host $host;
        }
        location ~ \.flv$ {
            # enable thread pool
            aio threads=default;
            flv;
        }

        location /healthz {
            return 200;
        }

        location ~* \.(jpg|jpeg|gif|png|css|js|ico|webp|tiff|ttf|svg|mp4)$ {
            mp4;
            mp4_buffer_size     1M;
            mp4_max_buffer_size 3M;

            aio threads=default;
            
            # enable caching for mp4 videos
            proxy_cache mycache;
            proxy_cache_valid 200 300s;
            proxy_cache_lock on;

            # enable nginx slicing
            slice              1m;
            proxy_cache_key    $host$uri$is_args$args$slice_range;
            proxy_set_header   Range $slice_range;
            proxy_http_version 1.1;

            # Immediately forward requests to the origin if we are filling the cache
            proxy_cache_lock_timeout 0s;

            # Set the 'age' to a value larger than the expected fill time
            proxy_cache_lock_age 200s;

            proxy_cache_use_stale updating;
        }
    }
}
EOF

# Apply port variable
sed -i s/'${PORT}'/${PORT}/g /etc/nginx/nginx.conf

echo ""
echo "#####################"
echo "Nginx running on port $PORT"
echo "#####################"
echo ""

exec "$@"
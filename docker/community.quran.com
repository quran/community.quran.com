server {
  listen   3000;
  server_name  community.quran.com;
  root   /home/app/community/public;
  passenger_enabled on;
  passenger_user app;
  passenger_ruby /usr/bin/ruby2.7;
  passenger_app_env production;

  access_log  /var/log/nginx/community.quran.com/access.log;
  error_log  /var/log/nginx/community.quran.com/error.log;

  location / {
    passenger_max_request_queue_size 200;
    proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header Host $http_host;
  }

  location /admin/* {
    passenger_max_request_queue_size 200;
    proxy_send_timeout          600;
    proxy_read_timeout          600;
    send_timeout                600;
  }

  location  ~^/assets/ {
    # Per RFC2616 - 1 year maximum expiry
    expires 1y;
    gzip_static on;
    add_header Cache-Control public;
  }
}

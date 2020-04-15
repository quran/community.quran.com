FROM phusion/passenger-customizable:1.0.9

# set correct environment variables
ENV HOME /root

# use baseimage-docker's init process
CMD ["/sbin/my_init"]

# customizing passenger-customizable image
RUN /pd_build/ruby-2.6.*.sh
RUN /pd_build/redis.sh

ENV RAILS_ENV production

# redis
RUN rm -f /etc/service/redis/down

# nginx
RUN rm /etc/service/nginx/down
RUN rm /etc/nginx/sites-enabled/default
ADD docker/community.quran.com /etc/nginx/sites-enabled/community.quran.com
ADD docker/postgres-env.conf /etc/nginx/main.d/postgres-env.conf
ADD docker/misc-env.conf /etc/nginx/main.d/misc-env.conf
ADD docker/gzip.conf /etc/nginx/conf.d/gzip.conf

# logrotate
COPY docker/nginx.logrotate.conf /etc/logrotate.d/nginx
RUN cp /etc/cron.daily/logrotate /etc/cron.hourly

# setup gems
WORKDIR /tmp
ADD Gemfile Gemfile
ADD Gemfile.lock Gemfile.lock
RUN bundle install

# setup the app
RUN mkdir /home/app/community
ADD . /home/app/community/

WORKDIR /home/app/community
RUN mkdir -p log
RUN chown -R app log
RUN chown -R app public
RUN chown app Gemfile
RUN chown app Gemfile.lock
RUN mkdir -p /var/log/nginx/community.quran.com

# precompile assets
RUN bundle exec rake assets:precompile

# pg_dump
RUN apt-get update
RUN apt-get install -y postgresql-client

# cleanup apt
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# expose port 3000
EXPOSE 3000

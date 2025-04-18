FROM redis:7-alpine

# ENV REDIS_PASSWORD=1
# ENV REDIS_USER=${REDIS_USER}
# ENV REDIS_USER_PASSWORD=${REDIS_USER_PASSWORD}

RUN mkdir -p /usr/local/etc/redis && \
    echo "bind 0.0.0.0" > /usr/local/etc/redis/redis.conf && \
    # echo "requirepass $REDIS_PASSWORD" >> /usr/local/etc/redis/redis.conf && \
    echo "appendonly yes" >> /usr/local/etc/redis/redis.conf && \
    echo "appendfsync everysec" >> /usr/local/etc/redis/redis.conf
RUN echo "user default on nopass ~* +@all" > /usr/local/etc/redis/users.acl
    # echo "user $REDIS_USER on >$REDIS_USER_PASSWORD ~* +@all" >> /usr/local/etc/redis/users.acl

EXPOSE 6379

# ENTRYPOINT [ "redis-server /usr/local/etc/redis/redis.conf --aclfile /usr/local/etc/redis/users.acl" ]
    
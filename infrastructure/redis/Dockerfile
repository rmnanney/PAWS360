FROM redis:7.2

# Install debugging tools
RUN apt-get update && apt-get install -y \
    curl \
    net-tools \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy configuration files
COPY redis.conf /usr/local/etc/redis/redis.conf
COPY sentinel.conf /usr/local/etc/redis/sentinel.conf

# Create data directory
RUN mkdir -p /data && chown redis:redis /data

EXPOSE 6379 26379

# Default to Redis server mode (override in docker-compose for sentinel)
CMD ["redis-server", "/usr/local/etc/redis/redis.conf"]

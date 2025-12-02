FROM postgres:15

# Install Patroni and dependencies
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-dev \
    python3-psycopg2 \
    curl \
    gosu \
    && pip3 install --break-system-packages --no-cache-dir \
    patroni[etcd]==3.2.0 \
    python-etcd \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create directories with proper ownership
RUN mkdir -p /data/patroni /config && \
    chown -R postgres:postgres /data/patroni /config

# Copy configuration and bootstrap script
COPY patroni.yml /config/patroni.yml
COPY bootstrap.sh /usr/local/bin/bootstrap.sh
RUN chmod +x /usr/local/bin/bootstrap.sh

EXPOSE 5432 8008

ENTRYPOINT ["/usr/local/bin/bootstrap.sh"]

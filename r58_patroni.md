```bash
PATRONI_CLUSTER_NAME='cluster-test-01'
PATRONI1_NAME='pg1'
PATRONI2_NAME='pg2'
PATRONI3_NAME='pg3'
PATRONI1_IP='10.0.3.201'
PATRONI2_IP='10.0.3.202'
PATRONI3_IP='10.0.3.203'
ETCD1_IP='10.0.3.101'
ETCD2_IP='10.0.3.102'
ETCD3_IP='10.0.3.103'
ETCD_USER='patroni'
ETCD_PASSWORD='patroni'
PGDATA="/var/lib/postgresql/15/${PATRONI_CLUSTER_NAME}"
PGPORT='5432'
PGBIN='/usr/lib/postgresql/15/bin'

PATRONICTL_CONFIG_FILE="/etc/patroni/config.yml"
PATRONI_SCOPE="${PATRONI_CLUSTER_NAME}"

PATRONI_NAME="$(hostname)"
PATRONI_IP="$(hostname -I | sed -e 's/\s*$//')"

chown -R  postgres: /etc/patroni/

cat >"$PATRONICTL_CONFIG_FILE" <<_CONFIGURATION_PATRONI_
scope: ${PATRONI_CLUSTER_NAME}
namespace: /service/  # valeur par défaut
name: ${PATRONI_NAME}

restapi:
  listen: ${PATRONI_IP}:8008
  connect_address: ${PATRONI_IP}:8008
log:
  level: INFO
  dir: /var/log/patroni/${PATRONI_CLUSTER_NAME}
etcd3:
  hosts:
  - ${ETCD1_IP}:2379
  - ${ETCD2_IP}:2379
  - ${ETCD3_IP}:2379
  username: ${ETCD_USER}
  password: ${ETCD_PASSWORD}
  protocol: http
bootstrap:
  dcs:
    ttl: 30
    loop_wait: 10
    retry_timeout: 10
    maximum_lag_on_failover: 1048576
    postgresql:
      use_pg_rewind: true
      use_slots: true
      parameters:
        wal_level: replica
        hot_standby: on
        max_wal_senders: 10
        max_replication_slots: 5
  initdb:
  - encoding: UTF8
  - data-checksums
  pg_hba:
  - host all all all scram-sha-256
  - host replication replicator all scram-sha-256
  users:
    dba:
      password: dba_password
      options:
      - createrole
      - createdb
postgresql:
  listen: "*:${PGPORT}"
  connect_address: ${PATRONI_IP}:${PGPORT}
  data_dir: ${PGDATA}
  bin_dir: ${PGBIN}
  authentication:
    replication:
      username: replicator
      password: replicator_password
    superuser:
      username: postgres
      password: postgres_password
    rewind:
      username: rewinder
      password: rewinder_password
  parameters:
    unix_socket_directories: '.'
  basebackup:
    max-rate: "100M"
    checkpoint: "fast"
watchdog:
  mode: automatic
  device: /dev/watchdog
  safety_margin: 5
tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
_CONFIGURATION_PATRONI_

sudo install -o postgres -g postgres -m 0750 -d /var/log/patroni/${PATRONI_CLUSTER_NAME}
sudo pg_dropcluster 15 main --stop

patroni --validate-config /etc/patroni/config.yml

sudo systemctl enable --now patroni
sudo systemctl status patroni

cat <<_EOF_ > ~postgres/.bashrc
## Patroni stuff goes here
export PATRONICTL_CONFIG_FILE="$PATRONICTL_CONFIG_FILE"
export PATRONI_SCOPE="${PATRONI_SCOPE}"

## PostgreSQL
export PGDATA="/var/lib/postgresql/15/${PATRONI_SCOPE}"
export PGHOST=\$PGDATA
export PGPORT=5432

_EOF_

cat <<_EOF_ > ~postgres/.profile
# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi
_EOF_

chown postgres: ~postgres/.bashrc ~postgres/.profile

```

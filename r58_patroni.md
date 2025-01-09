```bash
sudo cp /etc/postgresql/17/main/start.conf /etc/postgresql/17/main/start.conf.save
echo disabled | sudo tee /etc/postgresql/17/main/start.conf
sudo systemctl stop postgresql@17-main

sudo apt-get install patroni
sudo chown postgres: /etc/patroni

PATRONI_CLUSTER_NAME='acme'
sudo install -o postgres -g postgres -m 0750 -d /var/log/patroni/${PATRONI_CLUSTER_NAME}
PATRONI1_NAME='p1'
PATRONI2_NAME='p2'
PATRONI3_NAME='p3'
PATRONI1_IP='10.0.0.21' # p1
PATRONI2_IP='10.0.0.22' # p2
PATRONI3_IP='10.0.0.23' # p3
ETCD1_IP='10.0.0.11'    # e1
ETCD2_IP='10.0.0.12'    # e2
ETCD3_IP='10.0.0.13'    # e3
ETCD_USER='patroni'
ETCD_PASSWORD='patroni'
PGVERSION=17
PGDATA="/var/lib/postgresql/${PGVERSION}/${PATRONI_CLUSTER_NAME}"
PGPORT='5432'
PGBIN="/usr/lib/postgresql/${PGVERSION}/bin"

PATRONICTL_CONFIG_FILE="/etc/patroni/config.yml"
PATRONI_SCOPE="${PATRONI_CLUSTER_NAME}"

PATRONI_NAME="$(hostname)"
PATRONI_IP="$(hostname -I | sed -e 's/\s*$//')"

cat >"$PATRONICTL_CONFIG_FILE" << _CONFIGURATION_PATRONI_
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
      data_dir: ${PGDATA}
      use_pg_rewind: true
      use_slots: true
      parameters:
        wal_level: replica
        hot_standby: on
        max_wal_senders: 10
        max_replication_slots: 5
        unix_socket_directories: '/tmp'
      pg_hba:
      - local all all trust
      - host all all all trust
      - host replication replicator all scram-sha-256
  initdb:
  - encoding: UTF8
  - data-checksums
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
# parameters:
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

patroni --validate-config /etc/patroni/config.yml

sudo systemctl enable --now patroni
sudo systemctl status patroni

cat <<_EOF_ > ~postgres/.bashrc
## Patroni stuff goes here
export PATRONICTL_CONFIG_FILE="$PATRONICTL_CONFIG_FILE"
export PATRONI_SCOPE="$PATRONI_SCOPE"

## PostgreSQL
export PGDATA="$PGDATA"
export PGHOST="/tmp"
export PGPORT=$PGPORT

_EOF_

cat <<_EOF_ > ~postgres/.profile
# ~/.profile: executed by Bourne-compatible login shells.

if [ "$BASH" ]; then
  if [ -f ~/.bashrc ]; then
    . ~/.bashrc
  fi
fi
_EOF_

```

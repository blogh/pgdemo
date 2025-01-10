# Installation

## Prepare

```bash
# stop the pre-installed service
sudo cp /etc/postgresql/17/main/start.conf /etc/postgresql/17/main/start.conf.save
echo disabled | sudo tee /etc/postgresql/17/main/start.conf
sudo systemctl stop postgresql@17-main

# install patroni
sudo apt-get install patroni
```

## Configure

```bash
PATRONI_CLUSTER_NAME='acme'
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

sudo chown postgres: /etc/patroni
sudo install -o postgres -g postgres -m 0750 -d /var/log/patroni/${PATRONI_CLUSTER_NAME}

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
  mode: required
  device: /dev/watchdog
  safety_margin: 5
tags:
  nofailover: false
  noloadbalance: false
  clonefrom: false
  nosync: false
_CONFIGURATION_PATRONI_
```

## Watchdog support

```bash
cat <<'EOF' | sudo tee /etc/udev/rules.d/99-watchdog.rules
# give writes on watchdog device to postgres
SUBSYSTEM=="misc", KERNEL=="watchdog", ACTION=="add", RUN+="/bin/chown postgres /dev/watchdog"

# Or a better solution using ACL:
#SUBSYSTEM=="misc", KERNEL=="watchdog", ACTION=="add", RUN+="/bin/setfacl -m u:postgres:rw- /dev/watchdog"
EOF
```

## Check and start

```bash
# Validate conf
patroni --validate-config /etc/patroni/config.yml

# Start service
sudo systemctl enable --now patroni
sudo systemctl status patroni

# Setup env vars
cat <<_EOF_ > ~postgres/.bashrc
## Patroni stuff goes here
export PATRONICTL_CONFIG_FILE="$PATRONICTL_CONFIG_FILE"
export PATRONI_SCOPE="$PATRONI_SCOPE"

## PostgreSQL
export PGDATA="$PGDATA"
export PGHOST="/tmp"
export PGPORT=$PGPORT
export EDITOR=vi

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

# Standby cluster and switchover

## Prepare

On p3, do some cleanup:

```bash
sudo systemctl stop patroni
rm -Rf /var/lib/postgresql/17/acme

cp /etc/patroni/config.yml /etc/patroni/config.yml.old
```

Install etcdctl:

```bash
sudo apt-get install -y etcd-client
```

## Setup

Edit the configuration:

* set scope to "acme_standby"
* add the following into `bootstrap.dcs`:
  ```yaml
  standby_cluster:
    host: 10.0.0.21
    port: 5432
  ```

## Start

Start the cluster:

```bash
# patronictl remove acme_standby # If the cluster was already there ie it's not the first try
sudo systemctl start patroni
```

Check information on the (one node) cluster:

* on p3: 
  ```bash
  patronictl list acme_standby
  ```
* on e1:
  ```bash 
  etcdctl --user root:root --endpoints 10.0.0.11:2379 get --prefix --keys-only /service  
  ```
* on p1:
  ```bash
  patronictl list acme
  patronictl list acme_standby
  psql -xc "SELECT * FROM pg_stat_activity WHERE application_name = 'p3'"
  ```

## Switchover

Write in p1, stop p1 then p2:

```bash
psql -c "CREATE TABLE t1();"  # on p1
patronictl pause acme         # on p1 to prevent p2 from promoting when we stop p1 first 
sudo systemctl stop patroni   # on p1 then p2
```

Check repli on p3:

```bash
psql -c "\dt"
```

Remove the `standby_cluster` conf from `acme_standby` to do the promotion:

```bash
patronictl edit-config acme_standby
patronictl list acme_standby
psql -xc "CREATE TABLE t2()"
```

Update the configuration on acme to set it up as a standby cluster with the
following directly under the `dcs` section:

```yaml
standby_cluster:
  host: 10.0.0.23
  port: 5432
```

with (from anywhere that has access to etcd):

```bash
patronictl edit-config acme
```

Start p1 and p2:

```bash
sudo systemctl start patroni # on p1 and p2
patronictl list acme
patronictl resume acme
```

## Switchback, scratch and reinit like before

Stop p3:

```bash
sudo systemctl stop patroni # on p3
```

Promote the standby cluster:

```bash
patronictl edit-config acme # on p1, remove the standby_cluster section
patronictl list acme
```

Remove the data dir from p3, restore the old conf:

```bash
rm -Rf /var/lib/postgresql/17/acme
cp /etc/patroni/config.yml.old /etc/patroni/config.yml
patronictl remove acme_standby
```

Start the cluster and check:

```bash
sudo systemctl start patroni # on p3
patronictl list acme
```

# pgBackRest

## Configuration

```bash
patronictl edit-config acme
```

Add the following in the configuration in the postgresql configuration:

```bash
archive_mode: 'on'
archive_command: 'pgbackrest --stanza=main archive-push %p'
restore_command: 'pgbackrest --stanza=main archive-get %f "%p"'
```

Reload the configuration with a restart:

```bash
patronictl restart --role any --force acme
```

On the host, scratch the data directory, recreate the repo, do a check:

```bash
pgbackrest --stanza main stop
pgbackrest --stanza main stanza-delete
```

Edit the conf fix the pgdata paths (on host, p1, p2, p3).
Create the stanza, test achiving do a full:

```bash
pgbackrest --stanza main stanza-create
pgbackrest --stanza main check --log-level-console detail
pgbackrest --stanza main backup --log-level-console detail --type full
pgbackrest --stanza main info
```

## Setup replica method via pgBackRest

Add the following in the postgresql section via `patronictl edit-config acme`:

```yaml
create_replica_methods:
- basebackup
- pgbackrest
pgbackrest:
  command: /usr/bin/pgbackrest --stanza=main --delta restore
  keep_data: True
  no_leader: True
  no_params: True
basebackup:
- verbose
- max-rate: '100M'
```

## Reinit!

Reinit a replica, check the logs:

```bash
patronictl reinit --force acme p1 
less /var/log/patroni/acme/patroni.log
```

Reverse the order of the replica method (pgbackrest first), and reinit:

```bash
patronictl reinit --force acme p1 
less /var/log/patroni/acme/patroni.log
```

# Init the cluster ?

## Configuration

Update the yaml on all nodes:

```yaml
bootstrap:
  method: pgbackrest
  pgbackrest:
    command: /bin/bash -c "pgbackrest --stanza=main restore"
    keep_existing_recovery_conf: True
    no_params: True
  #...

  dcs:
    create_replica_methods:
    - basebackup
    - pgbackrest
    pgbackrest:
      command: /usr/bin/pgbackrest --stanza=main --delta restore
      keep_data: True
      no_leader: True
      no_params: True
    basebackup:
    - verbose
    - max-rate: '100M'
```

## Cleanup

On all nodes:

```bash
sudo systemctl stop patroni
```

On p1:

```bash
patronictl remove acme
```

Then everywhere :

```bash
rm /var/log/patroni/acme/patroni.log
rm /var/log/pgbackrest/*
```

## Init

On all nodes:

```bash
sudo systemctl start patron
watch ps -fu postgres | grep pgbackrest
patronictl list acme
```


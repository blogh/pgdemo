# VM Setup

We have 3 servers p1, p2, p3 + backup all with Debian 12

Update `.ssh/config`:

```bash
Host p1
  Hostname 10.0.0.21
  User admin
  StrictHostKeyChecking no

Host p2
  Hostname 10.0.0.22
  User admin
  StrictHostKeyChecking no

Host p3
  Hostname 10.0.0.23
  User admin
  StrictHostKeyChecking no

Host e1
  Hostname 10.0.0.11
  User admin
  StrictHostKeyChecking no

Host e2
  Hostname 10.0.0.12
  User admin
  StrictHostKeyChecking no

Host e3
  Hostname 10.0.0.13
  User admin
  StrictHostKeyChecking no
```

With `tmux`:

```bash
ssh vm1
ssh p1 # in panel 1
ssh p2 # in panel 2
ssh p3 # in panel 3
```

# PostgreSQL install

Then on all nodes:

```bash
# Import the repository signing key:
sudo apt -y install curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

# Create the repository configuration file:
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Update the package lists:
sudo apt update

# Install PostgreSQL 17
sudo apt -y install postgresql-17
```

Edit the sudoers file to add (`visudo`):

```
postgres ALL=(ALL) NOPASSWD: ALL
```

List and drop the existing clusters:

```bash
pg_lsclusters
pg_dropcluster --stop 17 main
sudo systemctl daemon-reload
```

Force checksums in `initdb` and update `log_line_prefix`:

```bash
sudo vi /etc/postgresql-common/createcluster.conf
```

```
initdb_options = '--data-checksums --lc-messages=C'
log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h '
```

# Create a primary instance

Create and start an instance on `p1`:

```bash
pg_createcluster 17 main
sudo systemctl start postgresql@17-main
# check the data_checksums
psql -c "\dconfig+ data_checksums"
```

Check the configuration on the primary:

```bash
# check the replication configuration
psql -c "\dconfig+ (wal_level|max_wal_senders|max_replication_slots|wal_sender_timeout)"
```

Create a replication user:

```bash
createuser --no-superuser --no-createrole --no-createdb --replication -P repli
echo '*:*:*:repli:confidentiel' >> ~/.pgpass
chmod 600 ~/.pgpass
```

Update the `/etc/postgresql/17/main/pg_hba.conf` to add:

```bash
cat << _EOF_ >> /etc/postgresql/17/main/pg_hba.conf
host    replication     repli           10.0.0.22/32            scram-sha-256
host    replication     repli           10.0.0.23/32            scram-sha-256
_EOF_
```

Check that the instance is listening on the correct interface and set a wal retention:

```bash
cat << _EOF_ >> /etc/postgresql/17/main/postgresql.conf
listen_addresses = '*'
wal_keep_size = '256MB'
_EOF_

sudo systemctl restart postgresql@17-main
sudo systemctl status postgresql@17-main
psql -c "\dconfig+ (listen_addresses|wal_keep_size)"
```

# Create a standby instance

On p2:

```bash
pg_createcluster 17 main
rm -Rf /var/lib/postgresql/17/main
```

```bash
echo '*:*:*:repli:confidentiel' >> ~/.pgpass
chmod 600 ~/.pgpass
```

```bash
pg_basebackup --pgdata /var/lib/postgresql/17/main \
              --progress \
              --write-recovery-conf \
              --checkpoint fast \
              --host 10.0.0.21 \
              --username repli
```

Update `primary_conninfo` to add `application_name=p2`:

```bash
cat  /var/lib/postgresql/17/main/postgresql.auto.conf
echo "##############"
file /var/lib/postgresql/17/main/standby.signal
```

Update the pg_hba:

```bash
 grep -E "host.*replication" /etc/postgresql/17/main/pg_hba.conf
```

... and check the configuration:

```bash
grep -E "^(listen_addresses|wal_keep_size)" /etc/postgresql/17/main/postgresql.conf
```

Check the instance and it's processes:

```bash
sudo systemctl start  postgresql@17-main
sudo systemctl status  postgresql@17-main
```

# Install pgBackRest

On the host vm:

```bash
# Import the repository signing key:
sudo apt -y install curl ca-certificates
sudo install -d /usr/share/postgresql-common/pgdg
sudo curl -o /usr/share/postgresql-common/pgdg/apt.postgresql.org.asc --fail https://www.postgresql.org/media/keys/ACCC4CF8.asc

# Create the repository configuration file:
sudo sh -c 'echo "deb [signed-by=/usr/share/postgresql-common/pgdg/apt.postgresql.org.asc] https://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" > /etc/apt/sources.list.d/pgdg.list'

# Update the package lists:
sudo apt update
```

On the host sever and all postgresql servers:

```bash
sudo apt-get install -y pgbackrest
```

Exchange keys between servers

On the host vm:

```bash
sudo chown dalibo /etc/pgbackrest.conf
sudo chown -R dalibo /var/lib/pgbackrest/
sudo chown -R dalibo /var/log/pgbackrest/

cat  << _EOF_ > /etc/pgbackrest.conf
[global]
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2

[main]
pg1-host=p1
pg1-path=/var/lib/postgresql/17/main
pg2-host=p2
pg2-path=/var/lib/postgresql/17/main
_EOF_

pgbackrest --stanza=main stanza-create
```

On the primary and standby:

```bash
sudo chown postgres /etc/pgbackrest.conf

cat  << _EOF_ > /etc/pgbackrest.conf
[global]
repo1-host=10.0.0.1
repo1-host-user=dalibo
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2

[main]
pg1-path=/var/lib/postgresql/17/main
_EOF_

cat  << _EOF_ >> /etc/postgresql/17/main/postgresql.conf
archive_mode = 'on'
archive_command = 'pgbackrest --stanza=main archive-push %p'
restore_command = 'pgbackrest --stanza=main archive-get %f "%p"'
_EOF_

sudo systemctl restart postgresql@17-main
```

On the host vm:

```bash
pgbackrest --stanza=main check --log-level-console=info
pgbackrest --stanza=main backup --log-level-console=info --type=full
pgbackrest --stanza=main info
```

# Switchover

Old primary:

```bash
sudo systemctl stop postgresql@17-main
/usr/lib/postgresql/17/bin/pg_controldata -D /var/lib/postgresql/17/main/ | grep -E "(REDO|state)"
```

New primary:

```bash
/usr/lib/postgresql/17/bin/pg_controldata -D /var/lib/postgresql/17/main/ | grep -E "(REDO|state)"
psql -c "SELECT pg_promote();"
grep primary /var/lib/postgresql/17/main/postgresql.auto.conf
```

Old primary:

```bash
touch /var/lib/postgresql/17/main/standby.signal
cat << _EOF_ >> /var/lib/postgresql/17/main/postgresql.auto.conf
primary_conninfo = 'user=repli passfile=''/var/lib/postgresql/.pgpass'' host=10.0.0.22 port=5432 application_name=p1'
_EOF_

cat  /var/lib/postgresql/17/main/postgresql.auto.conf
echo "##############"
file /var/lib/postgresql/17/main/standby.signal

sudo systemctl start postgresql@17-main
```

On the host vm:

```bash
pgbackrest --stanza=main backup --log-level-console=info --type=full
pgbackrest --stanza=main info
```

# Sync rep

On p3:

```bash
pg_createcluster 17 main
rm -Rf /var/lib/postgresql/17/main
```

```bash
echo '*:*:*:repli:confidentiel' >> ~/.pgpass
chmod 600 ~/.pgpass
```

```bash
pg_basebackup --pgdata /var/lib/postgresql/17/main \
              --progress \
              --write-recovery-conf \
              --checkpoint fast \
              --host 10.0.0.22 \
              --username repli
```

Update `primary_conninfo` to add `application_name=p3`:

```bash
cat  /var/lib/postgresql/17/main/postgresql.auto.conf
echo "##############"
file /var/lib/postgresql/17/main/standby.signal
```

Update the pg_hba:

```bash
 grep -E "host.*replication" /etc/postgresql/17/main/pg_hba.conf
```

... and check the configuration:

```bash
grep -E "^(listen_addresses|wal_keep_size|^archive|^restore)" /etc/postgresql/17/main/postgresql.conf
```

Configure pgBackRest:

```bash
sudo chown postgres /etc/pgbackrest.conf

cat  << _EOF_ > /etc/pgbackrest.conf
[global]
repo1-host=10.0.0.1
repo1-host-user=dalibo
repo1-path=/var/lib/pgbackrest
repo1-retention-full=2

[main]
pg1-path=/var/lib/postgresql/17/main
_EOF_
```

Check the instance and it's processes:

```bash
sudo systemctl start  postgresql@17-main
sudo systemctl status  postgresql@17-main
```

Add pg3 to the configuration of the host server

```
pg3-host=p3
pg3-path=/var/lib/postgresql/17/main
```

# Sync rep

Change `cluster_name` on all servers:

```bash
echo "cluster_name = '$(hostname)'" >> /etc/postgresql/17/main/postgresql.conf
```

On the primary (p2):

```bash
grep -E "^#synchronous" /etc/postgresql/17/main/postgresql.conf

cat << _EOF_ >> /etc/postgresql/17/main/postgresql.conf
synchronous_commit = on
synchronous_standby_names = 'p1, p2'
_EOF_
```

Try also:

```
synchronous_standby_names = 'FIRST (p1, p2)'
synchronous_standby_names = 'ANY (p1, p2)'
synchronous_standby_names = '*'
```

Checks

```bash
psql -xc "TABLE pg_stat_replication"
```

# Slots

On the primary:

```bash
psql -c "SELECT pg_create_physical_replication_slot('p1')"
psql -c "SELECT pg_create_physical_replication_slot('p3')"
psql -xc "TABLE pg_replication_slots"
```

Update **p1**:

```bash
cat << _EOF_ >> /var/lib/postgresql/17/main/postgresql.auto.conf
primary_slot_name = 'p1'
_EOF_
```

Update **p3**:

```bash
cat << _EOF_ >> /var/lib/postgresql/17/main/postgresql.auto.conf
primary_slot_name = 'p3'
_EOF_
```

Ultimately:

```bash
psql -c "SELECT pg_drop_replication_slot('p1')"
```




## Install

RedHat:

```bash
sudo yum install etcd # No package for RH 8, DL git and install
#sudo dnf install etcd 

sudo firewall-cmd --quiet --permanent --new-service=etcd
sudo firewall-cmd --quiet --permanent --service=etcd --set-short=Etcd
sudo firewall-cmd --quiet --permanent --service=etcd --set-description="Etcd server"
sudo firewall-cmd --quiet --permanent --service=etcd --add-port=2379/tcp # client communication
sudo firewall-cmd --quiet --permanent --service=etcd --add-port=2380/tcp # cluster communication
sudo firewall-cmd --quiet --permanent --add-service=etcd
sudo firewall-cmd --quiet --reload
```

Debian:

```bash
sudo apt install etcd
```

Note: install `jq` and `curl` to continue also

## Cleanup old cluster

See `ETCD_DATA_DIR`, by default in `/var/lib/etcd/default`.

```bash
ls -al /var/lib/etcd/

# if needed
systemctl stop etcd
rm -Rf /var/lib/etcd/default.etcd
```

## Create a new cluster

* Debian: /etc/default/etcd
* RH: /etc/etcd/etcd.conf

```bash
CONFIG_FILE="/etc/default/etcd"

LOCAL_IP="$(hostname -I | sed -e 's/\s*$//')"
NODE_NAME="$(hostname)"
ETCD_INITIAL_CLUSTER="e1=http://10.0.3.101:2380,e2=http://10.0.3.102:2380,e3=http://10.0.3.103:2380"

cat <<_EOF_ >"$CONFIG_FILE"
#[Member]
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://${LOCAL_IP}:2380"
ETCD_LISTEN_CLIENT_URLS="http://${LOCAL_IP}:2379,http://127.0.0.1:2379,http://[::1]:2379"
ETCD_NAME="$NODE_NAME"

#[Clustering]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://${LOCAL_IP}:2380"
ETCD_ADVERTISE_CLIENT_URLS="http://${LOCAL_IP}:2379"
ETCD_INITIAL_CLUSTER="${ETCD_INITIAL_CLUSTER}"
ETCD_INITIAL_CLUSTER_TOKEN="patroni-clusters"
ETCD_INITIAL_CLUSTER_STATE="new"

#[Other stuff]
ETCD_ENABLE_V2="true"
_EOF_
```

Update `.bash_profile`:

```bash
cat <<_EOF_ >>~/.bashrc
## etcd stuff goes here
export ETCDCTL_API=3
export ETCDCTL_ENDPOINTS="http://10.0.3.101:2379,http://10.0.3.102:2379,http://10.0.3.103:2379"

_EOF_
```

## Start

RH (the service is not started by default):

```bash
systemctl enable --now etcd
journalctl -fu etcd
```

Debian

```bash
systemctl restart etcd # or start it  if we stopped it earlier
journalctl -fu etcd
```


## Checks

```bash
# API V2
ETCDCTL_API=2 etcdctl member list
ETCDCTL_API=2 etcdctl cluster-health
```

```bash
# API V3
ETCDCTL_API=3 etcdctl -w table endpoint status
ETCDCTL_API=3 etcdctl -w table endpoint health
```

```bash
# API V2
curl -s -XGET http://127.0.0.1:2379/v2/members | jq
curl -s -XGET http://127.0.0.1:2379/v2/stats/self | jq
curl -s -XGET http://127.0.0.1:2379/v2/stats/leader | jq
```

```bash
# API V3
curl -s -XGET http://127.0.0.1:2379/version | jq
curl -s -XGET http://127.0.0.1:2379/health | jq
curl -s -XGET http://127.0.0.1:2379/metrics
```

## Usage

```bash
# API V2
ETCDCTL_API=2 etcdctl set fruit pomme
ETCDCTL_API=2 etcdctl mkdir mystuff
ETCDCTL_API=2 etcdctl set mystuff/voiture porche
ETCDCTL_API=2 etcdctl set otherstuff/maison bleue
ETCDCTL_API=2 etcdctl ls --recursive
ETCDCTL_API=2 etcdctl get --quorum fruit
ETCDCTL_API=2 etcdctl get --quorum mystuff/voiture

ETCDCTL_API=3 etcdctl get fruit  # the namespaces are different

ETCDCTL_API=2 etcdctl rm fruit
ETCDCTL_API=2 etcdctl rm mystuff/voiture
ETCDCTL_API=2 etcdctl rm otherstuff/maison
ETCDCTL_API=2 etcdctl rm --dir mystuff
ETCDCTL_API=2 etcdctl rmdir otherstuff
ETCDCTL_API=2 etcdctl ls --recursive
```

```bash
# API V3
ETCDCTL_API=3 etcdctl put /fruit pomme # the "/" is not required, it just helps with --prefix
ETCDCTL_API=3 etcdctl put /mystuff/voiture porche
ETCDCTL_API=3 etcdctl put /otherstuff/maison bleue
ETCDCTL_API=3 etcdctl get --prefix --consistency="l" /
ETCDCTL_API=3 etcdctl get --prefix --consistency="s" /
ETCDCTL_API=3 etcdctl get --from-key /
ETCDCTL_API=3 etcdctl get --prefix --keys-only /

ETCDCTL_API=3 etcdctl del --prefix /
```

## Authentication

```bash
# API V2
ETCDCTL_API=2 etcdctl user add root
ETCDCTL_API=2 etcdctl user add patroni

ETCDCTL_API=2 etcdctl -u root auth enable

ETCDCTL_API=2 etcdctl ls                        # works
ETCDCTL_API=2 etcdctl -u root:root role get guest # created by auth enabled if it didn't exist already
ETCDCTL_API=2 etcdctl -u root role remove guest # created by auth enabled if it didn't exist already
ETCDCTL_API=2 etcdctl ls                        # doesn't work anymore
ETCDCTL_API=2 etcdctl -u root:root ls           # works

ETCDCTL_API=2 etcdctl -u patroni:patroni ls     # doesn't work

ETCDCTL_API=2 etcdctl -u root:root role add  patroni
ETCDCTL_API=2 etcdctl -u root:root role grant patroni --path /service/ --readwrite
ETCDCTL_API=2 etcdctl -u root:root user grant --roles patroni patroni
ETCDCTL_API=2 etcdctl -u root:root user get patroni
ETCDCTL_API=2 etcdctl -u root:root role get patroni

ETCDCTL_API=2 etcdctl -u patroni:patroni ls           # still doesn't work
ETCDCTL_API=2 etcdctl -u patroni:patroni ls /service/ # only complains because the key wasn't created
```

```bash
# API V3
ETCDCTL_API=3 etcdctl user add root
ETCDCTL_API=3 etcdctl user add patroni

ETCDCTL_API=3 etcdctl role get root
ETCDCTL_API=3 etcdctl role add patroni

ETCDCTL_API=3 etcdctl user grant-role root root
ETCDCTL_API=3 etcdctl user grant-role patroni patroni

ETCDCTL_API=3 etcdctl auth enable

ETCDCTL_API=3 etcdctl get --prefix /                        # doesn't work a user is required
ETCDCTL_API=3 etcdctl --user patroni:patroni get --prefix / # doesn't work not enough privileges
ETCDCTL_API=3 etcdctl --user root:root get --prefix /      # works (it's root ..)

ETCDCTL_API=3 etcdctl --user root:root user get patroni
ETCDCTL_API=3 etcdctl --user root:root role grant-permission --prefix patroni readwrite /service/
ETCDCTL_API=3 etcdctl --user root:root role get patroni

ETCDCTL_API=3 etcdctl --user patroni:patroni get --prefix /          # doesn't work not enough privileges
ETCDCTL_API=3 etcdctl --user patroni:patroni get --prefix /service/  # returns nothing (the key doesn't exist yet)
```

## Lease

```bash
ETCDCTL_API=3 etcdctl lease grant 300                    # returns NOLEASE

ETCDCTL_API=3 etcdctl put sample value --lease=NOLEASE
ETCDCTL_API=3 etcdctl get sample

ETCDCTL_API=3 etcdctl lease keep-alive NOLEASE
ETCDCTL_API=3 etcdctl lease revoke NOLEASE               # or wait 300s

ETCDCTL_API=3 etcdctl get sample
```

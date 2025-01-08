## Install

RedHat:

```bash
#sudo yum install etcd # No package for RH 8, DL git and install
sudo dnf install etcd 

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
sudo apt install etcd                  # Debian 11-
sudo apt install etcd-{server,client}  # Debian 12+
```

Note: install `jq` and `curl` to continue also

## Cleanup old cluster (Debian)

See `ETCD_DATA_DIR`, by default in `/var/lib/etcd/default`.

```bash
sudo ls -al /var/lib/etcd/

# if needed
sudo systemctl stop etcd
sudo rm -Rf /var/lib/etcd/default.etcd
```

## Create a new cluster

* Debian: /etc/default/etcd
* RH: /etc/etcd/etcd.conf

```bash
CONFIG_FILE="/etc/default/etcd"

LOCAL_IP="$(hostname -I | sed -e 's/\s*$//')"
NODE_NAME="$(hostname)"
ETCD_INITIAL_CLUSTER="e1=http://10.0.0.11:2380,e2=http://10.0.0.12:2380,e3=http://10.0.0.13:2380"

cat <<_EOF_ | sudo tee "$CONFIG_FILE"
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
#ETCD_ENABLE_V2="true"
_EOF_
```

Update `.bash_profile`:

```bash
cat <<_EOF_ >>~/.bashrc
## etcd stuff goes here
export ETCDCTL_API=3
export ETCDCTL_ENDPOINTS="http://10.0.0.11:2379,http://10.0.0.12:2379,http://10.0.0.13:2379"

_EOF_
. ~/.bashrc
```

## Start

RH (the service is not started by default):

```bash
sudo systemctl enable --now etcd
sudo journalctl -fu etcd
```

Debian

```bash
sudo systemctl restart etcd # or start it  if we stopped it earlier
sudo journalctl -fu etcd
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

Revisions:


```bash
function list_revs(){
   key=$1
   min=$2
   max=$3
   for (( rev=$min ; rev<=$max; rev++ )); do
      echo -n "\"rev\" : $rev;"
      etcdctl -w fields --rev $rev get $key | grep -E 'CreateRevision|Key|Version|Value' | tr "\n" ";" | sed -e "s/CreateRevision/CRev/g";
      echo
   done
}

ETCDCTL_API=3 etcdctl put /fruit pomme # the "/" is not required, it just helps with --prefix
ETCDCTL_API=3 etcdctl -w fields get /fruit | grep -E 'Revision|Key|Version|Value' 
ETCDCTL_API=3 etcdctl put /fruit poire
ETCDCTL_API=3 etcdctl put /fruit abricot
ETCDCTL_API=3 etcdctl del /fruit
ETCDCTL_API=3 etcdctl -w fields get /fruit | grep -E 'Revision|Key|Version|Value'
list_revs '/fruit' 0 15

ETCDCTL_API=3 etcdctl compact 15
list_revs '/fruit' 0 15
```

## Lease

```bash
ETCDCTL_API=3 etcdctl lease 

ETCDCTL_API=3 etcdctl lease grant 300                    # returns NOLEASE

ETCDCTL_API=3 etcdctl put sample value --lease=NOLEASE
ETCDCTL_API=3 etcdctl get sample

ETCDCTL_API=3 etcdctl lease keep-alive --once NOLEASE
ETCDCTL_API=3 etcdctl lease timetolive NOLEASE
ETCDCTL_API=3 etcdctl lease revoke NOLEASE               # or wait 300s

ETCDCTL_API=3 etcdctl get sample
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
# Documentation
ETCDCTL_API=3 etcdctl user
echo "********************"
ETCDCTL_API=3 etcdctl role

ETCDCTL_API=3 etcdctl user add root
ETCDCTL_API=3 etcdctl user add patroni

echo "**"
ETCDCTL_API=3 etcdctl user list
echo "** No roles"
ETCDCTL_API=3 etcdctl role list      # No roles 

ETCDCTL_API=3 etcdctl role add patroni

ETCDCTL_API=3 etcdctl user grant-role root root   # root seems to not exist, but it works
ETCDCTL_API=3 etcdctl user grant-role patroni patroni

echo "**"
ETCDCTL_API=3 etcdctl user get patroni
echo "**"
ETCDCTL_API=3 etcdctl user get root
echo "** Error"
ETCDCTL_API=3 etcdctl role add patroni

ETCDCTL_API=3 etcdctl auth enable

echo "** doesn't work a user is required"
ETCDCTL_API=3 etcdctl get --prefix /
echo "** doesn't work not enough privileges"
ETCDCTL_API=3 etcdctl --user patroni:patroni get --prefix /
echo "** works (it's root ..) (but nothing to show)"
ETCDCTL_API=3 etcdctl --user root:root get --prefix /

ETCDCTL_API=3 etcdctl --user root:root role grant-permission --prefix patroni readwrite /service/
ETCDCTL_API=3 etcdctl --user root:root role get patroni

echo "** doesn't work not enough privileges"
ETCDCTL_API=3 etcdctl --user patroni:patroni get --prefix /
echo "** returns nothing (the key doesn't exist yet)"
ETCDCTL_API=3 etcdctl --user patroni:patroni get --prefix /service/

ETCDCTL_API=3 etcdctl --user root:root auth disable
```


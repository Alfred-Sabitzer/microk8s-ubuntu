# RookCeph Toolbox installation

Downloading the original file from

````bash
wget -qO- https://raw.githubusercontent.com/rook/rook/master/deploy/examples/toolbox.yaml > /tmp/toolbox.yaml
yq -i -y '.metadata.namespace = "rook-ceph-external"' /tmp/toolbox.yaml
````

This command replaces the namespace.

The original command is further modified.
It needs the credential for the client-admin. This credentials are very mighty.

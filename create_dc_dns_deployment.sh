#!/bin/bash

# Root directory
ROOT_DIR="/home/one/projects/10_9_sept_2024/openshift"

# Folders to be created for DCs and DNS
FOLDERS=(
    "$ROOT_DIR/dc"
    "$ROOT_DIR/dns"
)

# Create folders
echo "Creating folder structure for DC and DNS servers..."
for folder in "${FOLDERS[@]}"; do
    mkdir -p "$folder"
    echo "Created $folder"
done

# DC Deployment YAML (Domain Controller 1)
cat <<EOF > "$ROOT_DIR/dc/dc1-deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dc1
  namespace: default
  labels:
    app: domain-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: domain-controller
      dc: dc1
  template:
    metadata:
      labels:
        app: domain-controller
        dc: dc1
    spec:
      containers:
      - name: dc1
        image: mcr.microsoft.com/windows/servercore:ltsc2019
        command: ["powershell", "-Command", "Install-ADDSDomainController -DomainName example.com"]
        ports:
        - containerPort: 389 # LDAP port
        - containerPort: 636 # LDAP SSL port
        - containerPort: 53  # DNS
        volumeMounts:
        - mountPath: /var/lib/ldap
          name: dc1-storage
      volumes:
      - name: dc1-storage
        persistentVolumeClaim:
          claimName: dc1-pvc
EOF

# DC Service YAML (Domain Controller 1)
cat <<EOF > "$ROOT_DIR/dc/dc1-service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: dc1-service
  namespace: default
spec:
  selector:
    app: domain-controller
    dc: dc1
  ports:
    - protocol: TCP
      port: 389
      targetPort: 389
    - protocol: TCP
      port: 636
      targetPort: 636
    - protocol: TCP
      port: 53
      targetPort: 53
  type: ClusterIP
EOF

# DC Deployment YAML (Domain Controller 2)
cat <<EOF > "$ROOT_DIR/dc/dc2-deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dc2
  namespace: default
  labels:
    app: domain-controller
spec:
  replicas: 1
  selector:
    matchLabels:
      app: domain-controller
      dc: dc2
  template:
    metadata:
      labels:
        app: domain-controller
        dc: dc2
    spec:
      containers:
      - name: dc2
        image: mcr.microsoft.com/windows/servercore:ltsc2019
        command: ["powershell", "-Command", "Install-ADDSDomainController -DomainName example.com"]
        ports:
        - containerPort: 389 # LDAP port
        - containerPort: 636 # LDAP SSL port
        - containerPort: 53  # DNS
        volumeMounts:
        - mountPath: /var/lib/ldap
          name: dc2-storage
      volumes:
      - name: dc2-storage
        persistentVolumeClaim:
          claimName: dc2-pvc
EOF

# DC Service YAML (Domain Controller 2)
cat <<EOF > "$ROOT_DIR/dc/dc2-service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: dc2-service
  namespace: default
spec:
  selector:
    app: domain-controller
    dc: dc2
  ports:
    - protocol: TCP
      port: 389
      targetPort: 389
    - protocol: TCP
      port: 636
      targetPort: 636
    - protocol: TCP
      port: 53
      targetPort: 53
  type: ClusterIP
EOF

# Persistent Volume Claims for DC1 and DC2
cat <<EOF > "$ROOT_DIR/dc/dc1-pvc.yaml"
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dc1-pvc
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-storage
EOF

cat <<EOF > "$ROOT_DIR/dc/dc2-pvc.yaml"
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dc2-pvc
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-storage
EOF

# DNS Server Deployment YAML (BIND DNS)
cat <<EOF > "$ROOT_DIR/dns/dns-deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: dns-server
  namespace: default
  labels:
    app: dns-server
spec:
  replicas: 1
  selector:
    matchLabels:
      app: dns-server
  template:
    metadata:
      labels:
        app: dns-server
    spec:
      containers:
      - name: dns-server
        image: internetsystemsconsortium/bind9:9.16
        ports:
        - containerPort: 53
        - containerPort: 953 # Control channel
        volumeMounts:
        - mountPath: /etc/bind
          name: dns-storage
      volumes:
      - name: dns-storage
        persistentVolumeClaim:
          claimName: dns-pvc
EOF

# DNS Server Service YAML
cat <<EOF > "$ROOT_DIR/dns/dns-service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: dns-server-service
  namespace: default
spec:
  selector:
    app: dns-server
  ports:
    - protocol: UDP
      port: 53
      targetPort: 53
    - protocol: TCP
      port: 53
      targetPort: 53
  type: ClusterIP
EOF

# DNS Persistent Volume Claim
cat <<EOF > "$ROOT_DIR/dns/dns-pvc.yaml"
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: dns-pvc
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: nfs-storage
EOF

# Permissions setup
echo "Setting permissions for all files..."
chmod -R 755 "$ROOT_DIR"

echo "All DC and DNS server YAML files have been created successfully under $ROOT_DIR."


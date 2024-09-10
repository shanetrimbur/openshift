#!/bin/bash

# Root directory
ROOT_DIR="/home/one/projects/10_9_sept_2024/openshift"

# Folders to be created
FOLDERS=(
    "$ROOT_DIR/keycloak"
    "$ROOT_DIR/pki"
    "$ROOT_DIR/storage"
)

# Create folders
echo "Creating folder structure..."
for folder in "${FOLDERS[@]}"; do
    mkdir -p "$folder"
    echo "Created $folder"
done

# Keycloak Deployment YAML
cat <<EOF > "$ROOT_DIR/keycloak/keycloak-deployment.yaml"
apiVersion: apps/v1
kind: Deployment
metadata:
  name: keycloak
  namespace: default
  labels:
    app: keycloak
spec:
  replicas: 1
  selector:
    matchLabels:
      app: keycloak
  template:
    metadata:
      labels:
        app: keycloak
    spec:
      containers:
      - name: keycloak
        image: quay.io/keycloak/keycloak:21.0.1
        env:
        - name: KEYCLOAK_USER
          value: admin
        - name: KEYCLOAK_PASSWORD
          value: admin
        - name: DB_VENDOR
          value: h2
        - name: KEYCLOAK_IMPORT
          value: "/config/pki-realm.json"
        volumeMounts:
        - mountPath: /config
          name: keycloak-config
        - mountPath: /etc/x509/https
          name: tls-certs
      volumes:
      - name: keycloak-config
        configMap:
          name: keycloak-config
      - name: tls-certs
        secret:
          secretName: keycloak-tls
EOF

# Keycloak Service YAML
cat <<EOF > "$ROOT_DIR/keycloak/keycloak-service.yaml"
apiVersion: v1
kind: Service
metadata:
  name: keycloak
  namespace: default
spec:
  selector:
    app: keycloak
  ports:
    - protocol: TCP
      port: 8443
      targetPort: 8443
  type: ClusterIP
EOF

# Keycloak Ingress YAML
cat <<EOF > "$ROOT_DIR/keycloak/keycloak-ingress.yaml"
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: keycloak-ingress
  namespace: default
  annotations:
    nginx.ingress.kubernetes.io/ssl-redirect: "true"
    nginx.ingress.kubernetes.io/backend-protocol: "HTTPS"
spec:
  rules:
    - host: keycloak.example.com
      http:
        paths:
        - path: /
          pathType: Prefix
          backend:
            service:
              name: keycloak
              port:
                number: 8443
  tls:
    - hosts:
      - keycloak.example.com
      secretName: keycloak-tls
EOF

# Keycloak PKI Realm Configuration JSON
cat <<EOF > "$ROOT_DIR/keycloak/keycloak-pki-realm-config.json"
{
  "realm": "PKI-Realm",
  "enabled": true,
  "sslRequired": "all",
  "clients": [
    {
      "clientId": "pki-client",
      "enabled": true,
      "clientAuthenticatorType": "client-x509",
      "redirectUris": [
        "https://example-app.example.com/*"
      ]
    }
  ],
  "identityProviders": [
    {
      "alias": "x509",
      "providerId": "x509",
      "enabled": true,
      "updateProfileFirstLoginMode": "on",
      "trustEmail": true,
      "config": {
        "x509_certificates_header": "X-SSL-CERT",
        "x509_crl_check": "none",
        "x509_identity_source": "SUBJECTDN",
        "x509_identity_source_dn_regex": "CN=(.*?)(?:,|$)"
      }
    }
  ]
}
EOF

# Keycloak ConfigMap YAML
cat <<EOF > "$ROOT_DIR/keycloak/keycloak-configmap.yaml"
apiVersion: v1
kind: ConfigMap
metadata:
  name: keycloak-config
  namespace: default
data:
  pki-realm.json: |
    {
      "realm": "PKI-Realm",
      "enabled": true,
      "sslRequired": "all",
      "clients": [
        {
          "clientId": "pki-client",
          "enabled": true,
          "clientAuthenticatorType": "client-x509",
          "redirectUris": [
            "https://example-app.example.com/*"
          ]
        }
      ],
      "identityProviders": [
        {
          "alias": "x509",
          "providerId": "x509",
          "enabled": true,
          "updateProfileFirstLoginMode": "on",
          "trustEmail": true,
          "config": {
            "x509_certificates_header": "X-SSL-CERT",
            "x509_crl_check": "none",
            "x509_identity_source": "SUBJECTDN",
            "x509_identity_source_dn_regex": "CN=(.*?)(?:,|$)"
          }
        }
      ]
    }
EOF

# Persistent Volume Claim for Keycloak
cat <<EOF > "$ROOT_DIR/storage/keycloak-pvc.yaml"
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: keycloak-pvc
  namespace: default
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: nfs-storage
EOF

# Create dummy certificates for PKI (ca.crt, server.crt, server.key)
echo "Generating dummy certificates..."
cat <<EOF > "$ROOT_DIR/pki/ca.crt"
-----BEGIN CERTIFICATE-----
MIID...
-----END CERTIFICATE-----
EOF

cat <<EOF > "$ROOT_DIR/pki/server.crt"
-----BEGIN CERTIFICATE-----
MIID...
-----END CERTIFICATE-----
EOF

cat <<EOF > "$ROOT_DIR/pki/server.key"
-----BEGIN PRIVATE KEY-----
MIIE...
-----END PRIVATE KEY-----
EOF

# Permissions setup
echo "Setting permissions..."
chmod -R 755 "$ROOT_DIR"

echo "All files and folders have been created successfully under $ROOT_DIR."


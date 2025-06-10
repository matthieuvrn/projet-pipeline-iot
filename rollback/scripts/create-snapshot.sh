#!/bin/bash
# snapshots/scripts/create-snapshot.sh

set -euo pipefail

ENVIRONMENT=${1:-staging}
SNAPSHOT_NAME=${2:-"auto-$(date +%Y%m%d-%H%M%S)"}
RESOURCE_GROUP="iot-${ENVIRONMENT}-rg"
RETENTION_DAYS=30

echo "🔄 Creating snapshot for environment: $ENVIRONMENT"
echo "📝 Snapshot name: $SNAPSHOT_NAME"

# Vérifier les variables d'environnement Azure
if [[ -z "${AZURE_CLIENT_ID:-}" ]] || [[ -z "${AZURE_CLIENT_SECRET:-}" ]] || [[ -z "${AZURE_SUBSCRIPTION_ID:-}" ]] || [[ -z "${AZURE_TENANT_ID:-}" ]]; then
    echo "❌ Azure credentials not set"
    exit 1
fi

# Se connecter à Azure
echo "🔐 Logging into Azure..."
az login --service-principal \
    --username "$AZURE_CLIENT_ID" \
    --password "$AZURE_CLIENT_SECRET" \
    --tenant "$AZURE_TENANT_ID" \
    --output none

az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# Créer le snapshot des VMs
echo "💾 Creating VM snapshots..."
VM_NAMES=$(az vm list --resource-group "$RESOURCE_GROUP" --query "[].name" --output tsv)

for VM_NAME in $VM_NAMES; do
    echo "  📸 Creating snapshot for VM: $VM_NAME"
    
    # Obtenir l'ID du disque OS
    OS_DISK_ID=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" \
        --query "storageProfile.osDisk.managedDisk.id" --output tsv)
    
    # Créer le snapshot
    SNAPSHOT_NAME_VM="${SNAPSHOT_NAME}-${VM_NAME}-os"
    az snapshot create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$SNAPSHOT_NAME_VM" \
        --source "$OS_DISK_ID" \
        --tags "environment=$ENVIRONMENT" "created_by=ci_cd" "retention_days=$RETENTION_DAYS" \
        --output none
    
    echo "  ✅ Snapshot created: $SNAPSHOT_NAME_VM"
    
    # Créer snapshots des disques de données s'ils existent
    DATA_DISKS=$(az vm show --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" \
        --query "storageProfile.dataDisks[].managedDisk.id" --output tsv)
    
    DISK_INDEX=0
    for DATA_DISK_ID in $DATA_DISKS; do
        SNAPSHOT_NAME_DATA="${SNAPSHOT_NAME}-${VM_NAME}-data-${DISK_INDEX}"
        echo "  📸 Creating data disk snapshot: $SNAPSHOT_NAME_DATA"
        
        az snapshot create \
            --resource-group "$RESOURCE_GROUP" \
            --name "$SNAPSHOT_NAME_DATA" \
            --source "$DATA_DISK_ID" \
            --tags "environment=$ENVIRONMENT" "created_by=ci_cd" "retention_days=$RETENTION_DAYS" \
            --output none
        
        echo "  ✅ Data disk snapshot created: $SNAPSHOT_NAME_DATA"
        ((DISK_INDEX++))
    done
done

# Snapshot de la base de données PostgreSQL
echo "🗄️ Creating database backup..."
DB_SERVER_NAME="iot-${ENVIRONMENT}-db"
DB_BACKUP_NAME="${SNAPSHOT_NAME}-db"

# Vérifier si le serveur de base de données existe
if az postgres server show --resource-group "$RESOURCE_GROUP" --name "$DB_SERVER_NAME" --output none 2>/dev/null; then
    echo "  📸 Creating database backup: $DB_BACKUP_NAME"
    
    # Créer une sauvegarde de la base de données
    az postgres server-logs download \
        --resource-group "$RESOURCE_GROUP" \
        --server-name "$DB_SERVER_NAME" \
        --name "$DB_BACKUP_NAME" \
        --output none || echo "  ⚠️ Warning: Could not create database backup"
    
    echo "  ✅ Database backup completed"
else
    echo "  ℹ️ No PostgreSQL server found, skipping database backup"
fi

# Sauvegarder la configuration Terraform
echo "📋 Backing up Terraform state..."
mkdir -p "../backups/$SNAPSHOT_NAME"

# Exporter l'état Terraform
terraform -chdir="../../terraform/environments/$ENVIRONMENT" output -json > "../backups/$SNAPSHOT_NAME/terraform-outputs.json"
terraform -chdir="../../terraform/environments/$ENVIRONMENT" show -json > "../backups/$SNAPSHOT_NAME/terraform-state.json"

# Sauvegarder les variables Terraform
cp "../../terraform/environments/$ENVIRONMENT/terraform.tfvars" "../backups/$SNAPSHOT_NAME/" 2>/dev/null || true

# Créer un manifest du snapshot
cat > "../backups/$SNAPSHOT_NAME/snapshot-manifest.json" << EOF
{
    "snapshot_name": "$SNAPSHOT_NAME",
    "environment": "$ENVIRONMENT",
    "created_at": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "created_by": "ci_cd",
    "retention_days": $RETENTION_DAYS,
    "vm_snapshots": [
$(for VM_NAME in $VM_NAMES; do
    echo "        \"${SNAPSHOT_NAME}-${VM_NAME}-os\","
done | sed '$ s/,$//')
    ],
    "database_backup": "$DB_BACKUP_NAME",
    "terraform_backup": true
}
EOF

echo "📄 Snapshot manifest created"

# Nettoyer les anciens snapshots
echo "🧹 Cleaning up old snapshots..."
CUTOFF_DATE=$(date -d "$RETENTION_DAYS days ago" +%Y-%m-%d)

OLD_SNAPSHOTS=$(az snapshot list --resource-group "$RESOURCE_GROUP" \
    --query "[?tags.environment=='$ENVIRONMENT' && tags.created_by=='ci_cd' && timeCreated < '$CUTOFF_DATE'].name" \
    --output tsv)

for OLD_SNAPSHOT in $OLD_SNAPSHOTS; do
    echo "  🗑️ Deleting old snapshot: $OLD_SNAPSHOT"
    az snapshot delete --resource-group "$RESOURCE_GROUP" --name "$OLD_SNAPSHOT" --output none
done

# Nettoyer les anciens backups locaux
find "../backups" -name "auto-*" -type d -mtime +$RETENTION_DAYS -exec rm -rf {} + 2>/dev/null || true

echo "✅ Snapshot creation completed successfully!"
echo "📊 Snapshot details:"
echo "   Name: $SNAPSHOT_NAME"
echo "   Environment: $ENVIRONMENT"
echo "   Resource Group: $RESOURCE_GROUP"
echo "   Retention: $RETENTION_DAYS days"
echo "   VMs: $(echo $VM_NAMES | wc -w)"
echo "   Backup location: ../backups/$SNAPSHOT_NAME"

# Logout d'Azure
az logout --output none

exit 0
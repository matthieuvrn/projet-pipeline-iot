#!/bin/bash
# snapshots/scripts/restore-snapshot.sh

set -euo pipefail

ENVIRONMENT=${1:-}
SNAPSHOT_NAME=${2:-}
RESOURCE_GROUP="iot-${ENVIRONMENT}-rg"
FORCE_RESTORE=${3:-false}

if [[ -z "$ENVIRONMENT" ]] || [[ -z "$SNAPSHOT_NAME" ]]; then
    echo "❌ Usage: $0 <environment> <snapshot_name> [force]"
    echo "   Example: $0 staging auto-20241201-143000"
    exit 1
fi

echo "🔄 Starting snapshot restoration..."
echo "📝 Environment: $ENVIRONMENT"
echo "📝 Snapshot: $SNAPSHOT_NAME"
echo "📝 Resource Group: $RESOURCE_GROUP"

# Vérifier les variables d'environnement Azure
if [[ -z "${AZURE_CLIENT_ID:-}" ]] || [[ -z "${AZURE_CLIENT_SECRET:-}" ]] || [[ -z "${AZURE_SUBSCRIPTION_ID:-}" ]] || [[ -z "${AZURE_TENANT_ID:-}" ]]; then
    echo "❌ Azure credentials not set"
    exit 1
fi

# Fonction de confirmation
confirm_restore() {
    if [[ "$FORCE_RESTORE" != "true" ]]; then
        echo "⚠️  WARNING: This will restore the infrastructure to snapshot $SNAPSHOT_NAME"
        echo "⚠️  This operation is DESTRUCTIVE and will replace current VMs and data"
        echo "⚠️  Current running services will be stopped during restoration"
        echo ""
        read -p "Are you sure you want to continue? (type 'YES' to confirm): " confirmation
        
        if [[ "$confirmation" != "YES" ]]; then
            echo "❌ Restoration cancelled"
            exit 1
        fi
    fi
}

# Se connecter à Azure
echo "🔐 Logging into Azure..."
az login --service-principal \
    --username "$AZURE_CLIENT_ID" \
    --password "$AZURE_CLIENT_SECRET" \
    --tenant "$AZURE_TENANT_ID" \
    --output none

az account set --subscription "$AZURE_SUBSCRIPTION_ID"

# Vérifier que le snapshot existe
echo "🔍 Verifying snapshot exists..."
SNAPSHOT_MANIFEST="../backups/$SNAPSHOT_NAME/snapshot-manifest.json"

if [[ ! -f "$SNAPSHOT_MANIFEST" ]]; then
    echo "❌ Snapshot manifest not found: $SNAPSHOT_MANIFEST"
    exit 1
fi

echo "✅ Snapshot manifest found"

# Lire les informations du snapshot
SNAPSHOT_ENV=$(jq -r '.environment' "$SNAPSHOT_MANIFEST")
VM_SNAPSHOTS=($(jq -r '.vm_snapshots[]' "$SNAPSHOT_MANIFEST"))

if [[ "$SNAPSHOT_ENV" != "$ENVIRONMENT" ]]; then
    echo "❌ Snapshot environment ($SNAPSHOT_ENV) does not match target environment ($ENVIRONMENT)"
    exit 1
fi

# Confirmer la restauration
confirm_restore

# Créer un backup de l'état actuel avant restauration
echo "💾 Creating pre-restore backup..."
BACKUP_NAME="pre-restore-$(date +%Y%m%d-%H%M%S)"
"./create-snapshot.sh" "$ENVIRONMENT" "$BACKUP_NAME"

# Obtenir la liste des VMs actuelles
echo "📋 Getting current VM list..."
CURRENT_VMS=$(az vm list --resource-group "$RESOURCE_GROUP" --query "[].name" --output tsv)

# Arrêter les VMs actuelles
echo "⏹️ Stopping current VMs..."
for VM_NAME in $CURRENT_VMS; do
    echo "  🛑 Stopping VM: $VM_NAME"
    az vm deallocate --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --no-wait --output none
done

# Attendre que toutes les VMs soient arrêtées
echo "⏳ Waiting for VMs to stop..."
for VM_NAME in $CURRENT_VMS; do
    az vm wait --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --deallocated --output none
    echo "  ✅ VM stopped: $VM_NAME"
done

# Fonction pour restaurer une VM à partir d'un snapshot
restore_vm_from_snapshot() {
    local VM_NAME=$1
    local SNAPSHOT_NAME_OS="${SNAPSHOT_NAME}-${VM_NAME}-os"
    
    echo "🔄 Restoring VM: $VM_NAME"
    
    # Vérifier que le snapshot existe
    if ! az snapshot show --resource-group "$RESOURCE_GROUP" --name "$SNAPSHOT_NAME_OS" --output none 2>/dev/null; then
        echo "❌ OS Snapshot not found: $SNAPSHOT_NAME_OS"
        return 1
    fi
    
    # Supprimer la VM actuelle (garder les disques pour l'instant)
    echo "  🗑️ Deleting current VM: $VM_NAME"
    az vm delete --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --yes --output none
    
    # Obtenir les informations du snapshot
    SNAPSHOT_ID=$(az snapshot show --resource-group "$RESOURCE_GROUP" --name "$SNAPSHOT_NAME_OS" --query "id" --output tsv)
    
    # Créer un nouveau disque à partir du snapshot
    NEW_DISK_NAME="${VM_NAME}-restored-os-disk"
    echo "  💽 Creating new OS disk from snapshot..."
    az disk create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$NEW_DISK_NAME" \
        --source "$SNAPSHOT_ID" \
        --output none
    
    # Obtenir l'ID du nouveau disque
    NEW_DISK_ID=$(az disk show --resource-group "$RESOURCE_GROUP" --name "$NEW_DISK_NAME" --query "id" --output tsv)
    
    # Recréer la VM avec le disque restauré
    echo "  🖥️ Recreating VM with restored disk..."
    
    # Obtenir la configuration réseau existante
    SUBNET_ID=$(az network vnet subnet show \
        --resource-group "$RESOURCE_GROUP" \
        --vnet-name "iot-${ENVIRONMENT}-vnet" \
        --name "iot-${ENVIRONMENT}-subnet" \
        --query "id" --output tsv)
    
    # Créer une nouvelle interface réseau
    NIC_NAME="${VM_NAME}-restored-nic"
    az network nic create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$NIC_NAME" \
        --subnet "$SUBNET_ID" \
        --output none
    
    # Créer la VM
    az vm create \
        --resource-group "$RESOURCE_GROUP" \
        --name "$VM_NAME" \
        --attach-os-disk "$NEW_DISK_ID" \
        --os-type Linux \
        --nics "$NIC_NAME" \
        --output none
    
    # Restaurer les disques de données s'ils existent
    DATA_DISK_INDEX=0
    while true; do
        DATA_SNAPSHOT_NAME="${SNAPSHOT_NAME}-${VM_NAME}-data-${DATA_DISK_INDEX}"
        
        if az snapshot show --resource-group "$RESOURCE_GROUP" --name "$DATA_SNAPSHOT_NAME" --output none 2>/dev/null; then
            echo "  💾 Restoring data disk $DATA_DISK_INDEX..."
            
            DATA_SNAPSHOT_ID=$(az snapshot show --resource-group "$RESOURCE_GROUP" --name "$DATA_SNAPSHOT_NAME" --query "id" --output tsv)
            DATA_DISK_NAME="${VM_NAME}-restored-data-disk-${DATA_DISK_INDEX}"
            
            # Créer le disque de données
            az disk create \
                --resource-group "$RESOURCE_GROUP" \
                --name "$DATA_DISK_NAME" \
                --source "$DATA_SNAPSHOT_ID" \
                --output none
            
            # Attacher le disque à la VM
            az vm disk attach \
                --resource-group "$RESOURCE_GROUP" \
                --vm-name "$VM_NAME" \
                --name "$DATA_DISK_NAME" \
                --output none
            
            echo "    ✅ Data disk $DATA_DISK_INDEX restored"
            ((DATA_DISK_INDEX++))
        else
            break
        fi
    done
    
    echo "  ✅ VM $VM_NAME restored successfully"
}

# Restaurer chaque VM
echo "🔄 Starting VM restoration..."
for VM_SNAPSHOT in "${VM_SNAPSHOTS[@]}"; do
    # Extraire le nom de la VM du nom du snapshot
    VM_NAME=$(echo "$VM_SNAPSHOT" | sed "s/${SNAPSHOT_NAME}-\(.*\)-os/\1/")
    restore_vm_from_snapshot "$VM_NAME"
done

# Démarrer les VMs restaurées
echo "▶️ Starting restored VMs..."
for VM_SNAPSHOT in "${VM_SNAPSHOTS[@]}"; do
    VM_NAME=$(echo "$VM_SNAPSHOT" | sed "s/${SNAPSHOT_NAME}-\(.*\)-os/\1/")
    echo "  🚀 Starting VM: $VM_NAME"
    az vm start --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --no-wait --output none
done

# Attendre que les VMs démarrent
echo "⏳ Waiting for VMs to start..."
for VM_SNAPSHOT in "${VM_SNAPSHOTS[@]}"; do
    VM_NAME=$(echo "$VM_SNAPSHOT" | sed "s/${SNAPSHOT_NAME}-\(.*\)-os/\1/")
    az vm wait --resource-group "$RESOURCE_GROUP" --name "$VM_NAME" --created --output none
    echo "  ✅ VM started: $VM_NAME"
done

# Restaurer la configuration Terraform si disponible
echo "📋 Restoring Terraform configuration..."
TERRAFORM_BACKUP="../backups/$SNAPSHOT_NAME/terraform-state.json"
if [[ -f "$TERRAFORM_BACKUP" ]]; then
    echo "  📥 Terraform state backup found, copying to environment directory..."
    cp "$TERRAFORM_BACKUP" "../../terraform/environments/$ENVIRONMENT/terraform-state-restored.json"
    
    # Copier les variables Terraform si disponibles
    TERRAFORM_VARS="../backups/$SNAPSHOT_NAME/terraform.tfvars"
    if [[ -f "$TERRAFORM_VARS" ]]; then
        cp "$TERRAFORM_VARS" "../../terraform/environments/$ENVIRONMENT/terraform.tfvars.restored"
        echo "  📥 Terraform variables restored"
    fi
    
    echo "  ✅ Terraform configuration restored"
else
    echo "  ⚠️ No Terraform backup found"
fi

# Restaurer la base de données si nécessaire
echo "🗄️ Checking for database restoration..."
DB_BACKUP_NAME=$(jq -r '.database_backup' "$SNAPSHOT_MANIFEST")
if [[ "$DB_BACKUP_NAME" != "null" ]] && [[ -n "$DB_BACKUP_NAME" ]]; then
    echo "  🔄 Database backup found: $DB_BACKUP_NAME"
    echo "  ⚠️ Manual database restoration may be required"
    echo "  📝 Check Azure portal for database point-in-time restore options"
else
    echo "  ℹ️ No database backup to restore"
fi

# Nettoyer les anciens disques et interfaces réseau
echo "🧹 Cleaning up old resources..."
OLD_DISKS=$(az disk list --resource-group "$RESOURCE_GROUP" --query "[?contains(name, '-old-') || contains(name, '-backup-')].name" --output tsv)
OLD_NICS=$(az network nic list --resource-group "$RESOURCE_GROUP" --query "[?contains(name, '-old-') || contains(name, '-backup-')].name" --output tsv)

for OLD_DISK in $OLD_DISKS; do
    echo "  🗑️ Deleting old disk: $OLD_DISK"
    az disk delete --resource-group "$RESOURCE_GROUP" --name "$OLD_DISK" --yes --no-wait --output none
done

for OLD_NIC in $OLD_NICS; do
    echo "  🗑️ Deleting old NIC: $OLD_NIC"
    az network nic delete --resource-group "$RESOURCE_GROUP" --name "$OLD_NIC" --no-wait --output none
done

# Créer un rapport de restauration
echo "📄 Creating restoration report..."
cat > "../backups/restore-report-$(date +%Y%m%d-%H%M%S).json" << EOF
{
    "restoration_date": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
    "source_snapshot": "$SNAPSHOT_NAME",
    "target_environment": "$ENVIRONMENT",
    "resource_group": "$RESOURCE_GROUP",
    "restored_vms": [
$(for VM_SNAPSHOT in "${VM_SNAPSHOTS[@]}"; do
    VM_NAME=$(echo "$VM_SNAPSHOT" | sed "s/${SNAPSHOT_NAME}-\(.*\)-os/\1/")
    echo "        \"$VM_NAME\","
done | sed '$ s/,$//')
    ],
    "pre_restore_backup": "$BACKUP_NAME",
    "terraform_restored": $([ -f "$TERRAFORM_BACKUP" ] && echo "true" || echo "false"),
    "database_backup": "$DB_BACKUP_NAME",
    "status": "completed"
}
EOF

echo "✅ Snapshot restoration completed successfully!"
echo "📊 Restoration summary:"
echo "   Source snapshot: $SNAPSHOT_NAME"
echo "   Target environment: $ENVIRONMENT"
echo "   VMs restored: ${#VM_SNAPSHOTS[@]}"
echo "   Pre-restore backup: $BACKUP_NAME"
echo "   Database backup: $DB_BACKUP_NAME"
echo ""
echo "⚠️ Post-restoration steps:"
echo "   1. Verify application functionality"
echo "   2. Check database connectivity"
echo "   3. Validate terraform state if needed"
echo "   4. Monitor logs for any issues"
echo "   5. Update DNS/load balancer if necessary"

# Logout d'Azure
az logout --output none

exit 0
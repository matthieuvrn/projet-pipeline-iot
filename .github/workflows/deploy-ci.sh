#!/bin/bash

# Script de déploiement simplifié pour GitHub Actions
# Ne fait pas de vérification des changements non commités

set -e

# Vérification des dépendances
command -v ansible-playbook >/dev/null 2>&1 || { echo "Ansible est requis mais non installé. Sortie."; exit 1; }

echo "🔄 Déploiement avec Ansible..."
ansible-playbook -i ansible/inventory.ini ansible/deploy.yml

echo "✅ Déploiement terminé avec succès !"
echo "🎉 L'API est maintenant disponible à l'adresse configurée dans l'inventaire Ansible."
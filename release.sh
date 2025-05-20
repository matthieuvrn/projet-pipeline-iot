#!/bin/bash

# Script de release pour l'API IoT Sensors
# Usage: ./release.sh [version]

set -e

# Vérification des dépendances
command -v git >/dev/null 2>&1 || { echo "Git est requis mais non installé. Sortie."; exit 1; }
command -v ansible-playbook >/dev/null 2>&1 || { echo "Ansible est requis mais non installé. Sortie."; exit 1; }

# Définir le répertoire du projet
PROJECT_DIR=$(pwd)
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Version (optionnelle)
VERSION=${1:-$(date +"%Y.%m.%d-%H%M")}
TAG="v$VERSION"

echo "🚀 Déploiement de la version $TAG"

# Vérifier que nous sommes dans un dépôt Git et qu'il n'y a pas de changements non commités
if [ -z "$(git status --porcelain)" ]; then
  echo "✅ Le répertoire de travail est propre."
else
  echo "❌ Le répertoire de travail a des changements non commités. Commitez d'abord."
  exit 1
fi

# Générer le changelog
echo "📝 Génération du changelog..."
# Récupérer les commits de manière plus robuste
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  # Si nous avons au moins un commit
  if git describe --tags --abbrev=0 >/dev/null 2>&1; then
    # Si nous avons au moins un tag
    LAST_TAG=$(git describe --tags --abbrev=0)
    COMMITS=$(git log --pretty=format:"- %s (%h)" ${LAST_TAG}..HEAD)
  else
    # Si nous n'avons pas de tag, prendre tous les commits
    COMMITS=$(git log --pretty=format:"- %s (%h)")
  fi
else
  # Si nous n'avons pas de commit du tout
  COMMITS="- Premier déploiement"
fi
CHANGELOG="# Release $TAG ($(date +"%Y-%m-%d"))\n\n$COMMITS"
echo -e "$CHANGELOG" > CHANGELOG.md
cat CHANGELOG.md

# Commit et tag
git add CHANGELOG.md
git commit -m "Release $TAG"
git tag -a "$TAG" -m "Release $TAG"

echo "📦 Commit et tag créés localement."

# Push vers le dépôt distant
echo "📤 Push des changements et du tag..."
git push origin "$CURRENT_BRANCH"
git push origin "$TAG"

echo "🏷️ Tag $TAG poussé vers le dépôt distant."

# Déployer avec Ansible
echo "🔄 Déploiement avec Ansible..."
cd "$PROJECT_DIR"
ansible-playbook -i ansible/inventory.ini ansible/deploy.yml

echo "✅ Déploiement terminé avec succès !"
echo "🎉 L'API est maintenant disponible à l'adresse configurée dans l'inventaire Ansible."
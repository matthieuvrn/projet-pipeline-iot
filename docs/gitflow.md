# Documentation GitFlow - Projet IoT API

## Vue d'ensemble

Ce projet utilise la méthodologie GitFlow pour organiser le développement et les déploiements. Cette approche garantit une gestion structurée des versions et des environnements.

## Structure des branches

### Branches principales

#### `main` 
- **Rôle** : Branche de production
- **Protection** : Totalement protégée, pas de push direct
- **Déploiement** : Production automatique sur push/merge
- **Tags** : Toutes les versions officielles (v1.0.0, v1.1.0, etc.)

#### `develop`
- **Rôle** : Branche d'intégration pour le développement
- **Protection** : Protégée, merge uniquement via PR
- **Déploiement** : Staging automatique sur push
- **Tests** : Pipeline complet (lint, tests, build)

### Branches de support

#### `feature/*`
- **Nomenclature** : `feature/description-courte` ou `feature/JIRA-123`
- **Source** : Créée depuis `develop`
- **Destination** : Merge vers `develop`
- **Durée de vie** : Temporaire, supprimée après merge
- **Exemple** : `feature/add-sensor-endpoint`

#### `release/*`
- **Nomenclature** : `release/v1.2.0`
- **Source** : Créée depuis `develop`
- **Destination** : Merge vers `main` ET `develop`
- **Rôle** : Préparation d'une nouvelle version
- **Actions** : Correction de bugs mineurs, mise à jour du changelog

#### `hotfix/*`
- **Nomenclature** : `hotfix/v1.1.1` ou `hotfix/fix-critical-bug`
- **Source** : Créée depuis `main`
- **Destination** : Merge vers `main` ET `develop`
- **Rôle** : Correction urgente en production
- **Déploiement** : Production immédiate après validation

## Workflow détaillé

### 1. Développement d'une nouvelle fonctionnalité

```bash
# 1. Créer une branche feature depuis develop
git checkout develop
git pull origin develop
git checkout -b feature/nouvelle-fonctionnalite

# 2. Développer et commiter
git add .
git commit -m "feat: ajouter endpoint pour nouveaux capteurs"

# 3. Pousser la branche
git push origin feature/nouvelle-fonctionnalite

# 4. Créer une Pull Request vers develop
# Via interface GitHub avec review obligatoire
```

### 2. Préparation d'une release

```bash
# 1. Créer une branche release depuis develop
git checkout develop
git pull origin develop
git checkout -b release/v1.2.0

# 2. Préparer la release
# - Mettre à jour le CHANGELOG.md
# - Fixer les bugs de dernière minute
# - Mettre à jour la version dans package.json

# 3. Merger vers main
git checkout main
git merge --no-ff release/v1.2.0
git tag -a v1.2.0 -m "Release version 1.2.0"
git push origin main --tags

# 4. Merger vers develop
git checkout develop
git merge --no-ff release/v1.2.0
git push origin develop

# 5. Supprimer la branche release
git branch -d release/v1.2.0
git push origin --delete release/v1.2.0
```

### 3. Hotfix critique

```bash
# 1. Créer une branche hotfix depuis main
git checkout main
git pull origin main
git checkout -b hotfix/v1.1.1

# 2. Corriger le bug
git add .
git commit -m "fix: corriger la faille de sécurité critique"

# 3. Merger vers main
git checkout main
git merge --no-ff hotfix/v1.1.1
git tag -a v1.1.1 -m "Hotfix version 1.1.1"
git push origin main --tags

# 4. Merger vers develop
git checkout develop
git merge --no-ff hotfix/v1.1.1
git push origin develop

# 5. Supprimer la branche hotfix
git branch -d hotfix/v1.1.1
git push origin --delete hotfix/v1.1.1
```

## Conventions de nommage

### Commits
Nous utilisons la convention [Conventional Commits](https://www.conventionalcommits.org/) :

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

**Types principaux :**
- `feat`: Nouvelle fonctionnalité
- `fix`: Correction de bug
- `docs`: Documentation
- `style`: Formatage, pas de changement de code
- `refactor`: Refactoring du code
- `test`: Ajout/modification de tests
- `chore`: Tâches de maintenance

**Exemples :**
```
feat(api): ajouter endpoint pour capteurs de température
fix(auth): corriger la validation des tokens JWT
docs(readme): mettre à jour les instructions d'installation
test(sensors): ajouter tests unitaires pour SensorService
```

### Branches
- **feature/** : `feature/description-kebab-case`
- **release/** : `release/v{major}.{minor}.{patch}`
- **hotfix/** : `hotfix/v{major}.{minor}.{patch}` ou `hotfix/description`

### Tags
Format : `v{major}.{minor}.{patch}`
- **v1.0.0** : Release majeure avec breaking changes
- **v1.1.0** : Release mineure avec nouvelles fonctionnalités
- **v1.1.1** : Release de patch avec corrections

## Protection des branches

### Branch Protection Rules

#### `main`
```yaml
Protection:
  - Require pull request reviews: true
  - Required reviewers: 2
  - Dismiss stale reviews: true
  - Require status checks: true
  - Require branches to be up to date: true
  - Required status checks:
    - ci/lint
    - ci/test
    - ci/build
    - ci/security-scan
  - Restrict pushes: true
  - Allow force pushes: false
  - Allow deletions: false
```

#### `develop`
```yaml
Protection:
  - Require pull request reviews: true
  - Required reviewers: 1
  - Require status checks: true
  - Required status checks:
    - ci/lint
    - ci/test
    - ci/build
  - Restrict pushes: true
  - Allow force pushes: false
```

## Intégration CI/CD

### Déclencheurs par branche

| Branche | Déclencheur | Actions | Déploiement |
|---------|------------|---------|-------------|
| `feature/*` | Push, PR | Lint, Test, Build | - |
| `develop` | Push, Merge | Pipeline complet | Staging |
| `release/*` | Push | Pipeline complet | Staging |
| `main` | Push, Merge | Pipeline complet + Tag | Production |
| `hotfix/*` | Push | Pipeline complet | Staging puis Production |

### Pipeline par environnement

#### Staging (develop, release/*, hotfix/*)
1. Lint & Security Scan
2. Tests unitaires et d'intégration
3. Build Docker image
4. Déploiement infrastructure (Terraform)
5. Déploiement application (Ansible)
6. Tests de fumée
7. Création de snapshot

#### Production (main avec tags)
1. Tous les steps de staging
2. Validation manuelle (optionnelle)
3. Déploiement production
4. Tests de vérification
5. Création de snapshot de production
6. Notification équipe

## Gestion des conflits

### Résolution de conflits de merge

```bash
# 1. Mettre à jour la branche de destination
git checkout develop
git pull origin develop

# 2. Retourner sur votre branche
git checkout feature/ma-fonctionnalite

# 3. Rebase sur develop
git rebase develop

# 4. Résoudre les conflits manuellement
# Éditer les fichiers en conflit

# 5. Ajouter les fichiers résolus
git add .
git rebase --continue

# 6. Force push (uniquement sur les branches feature)
git push --force-with-lease origin feature/ma-fonctionnalite
```

## Versionnement sémantique

### Règles de versioning

- **MAJOR** (x.0.0) : Breaking changes, incompatibilité API
- **MINOR** (x.y.0) : Nouvelles fonctionnalités, compatible
- **PATCH** (x.y.z) : Corrections de bugs, compatible

### Automatisation des versions

Le versioning est automatisé via GitHub Actions :

```yaml
# Exemple dans .github/workflows/ci-cd.yml
- name: Bump version and push tag
  uses: mathieudutour/github-tag-action@v6.1
  with:
    github_token: ${{ secrets.GITHUB_TOKEN }}
    default_bump: patch
    release_branches: main
```

## Exemple de workflow complet

### Scénario : Développement d'une nouvelle API

1. **Création de la feature**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b feature/api-v2-sensors
   ```

2. **Développement**
   ```bash
   # Développement...
   git add .
   git commit -m "feat(api): ajouter API v2 pour capteurs"
   git push origin feature/api-v2-sensors
   ```

3. **Pull Request**
   - Créer PR de `feature/api-v2-sensors` vers `develop`
   - Review par l'équipe
   - Tests automatiques passent
   - Merge vers `develop`

4. **Déploiement staging automatique**
   - Pipeline CI/CD se déclenche
   - Déploiement sur environnement staging
   - Tests de fumée

5. **Préparation release**
   ```bash
   git checkout develop
   git pull origin develop
   git checkout -b release/v1.3.0
   # Mise à jour CHANGELOG, corrections mineures...
   ```

6. **Release vers production**
   ```bash
   git checkout main
   git merge --no-ff release/v1.3.0
   git tag -a v1.3.0 -m "Release v1.3.0 - Nouvelle API capteurs"
   git push origin main --tags
   ```

7. **Déploiement production automatique**
   - Pipeline CI/CD se déclenche sur le tag
   - Déploiement production
   - Création de snapshot
   - Notification équipe

## Bonnes pratiques

### Commits
- Commits atomiques et logiques
- Messages clairs et descriptifs
- Utiliser les conventions de commit
- Éviter les commits de fix de typos multiples

### Pull Requests
- Titre descriptif
- Description détaillée des changements
- Référencer les issues/tickets
- Ajouter des captures d'écran si UI
- Tests ajoutés/modifiés si nécessaire

### Reviews
- Review obligatoire avant merge
- Vérifier la qualité du code
- Valider les tests
- Confirmer la documentation

### Nettoyage
- Supprimer les branches feature après merge
- Garder `develop` et `main` propres
- Nettoyer les branches obsolètes régulièrement

## Outils recommandés

### Git Hooks
```bash
# Pre-commit hook pour vérifier les conventions
npm install -g @commitlint/cli @commitlint/config-conventional
echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js
```

### Git Aliases utiles
```bash
git config --global alias.co checkout
git config --global alias.br branch
git config --global alias.ci commit
git config --global alias.st status
git config --global alias.lg "log --oneline --graph --decorate --all"
```

## Troubleshooting

### Problèmes courants

1. **Branche locale désynchronisée**
   ```bash
   git fetch --all --prune
   git reset --hard origin/develop
   ```

2. **Commit sur la mauvaise branche**
   ```bash
   git reset HEAD~1
   git stash
   git checkout correct-branch
   git stash pop
   ```

3. **Merge accidentel**
   ```bash
   git reset --hard HEAD~1
   ```

**Note** : Ces commandes sont destructives, utilisez avec précaution et assurez-vous d'avoir une sauvegarde.
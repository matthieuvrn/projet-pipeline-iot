# 🌐 Pipeline de Déploiement Continu - IoT API

> Infrastructure complète CI/CD pour une API de supervision de capteurs environnementaux destinée à une application mobile.

[![CI/CD Pipeline](https://github.com/username/iot-api-cicd/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/username/iot-api-cicd/actions)
[![Staging Deployment](https://img.shields.io/badge/staging-deployed-green)](https://iot-api-staging.example.com)
[![Production Deployment](https://img.shields.io/badge/production-deployed-blue)](https://iot-api.example.com)
[![Version](https://img.shields.io/github/v/tag/username/iot-api-cicd)](https://github.com/username/iot-api-cicd/tags)

## 📋 Table des matières

- [🎯 Présentation du projet](#-présentation-du-projet)
- [🏗️ Architecture](#️-architecture)
- [🔄 GitFlow](#-gitflow)
- [🚀 Pipeline CI/CD](#-pipeline-cicd)
- [📦 Packaging et versioning](#-packaging-et-versioning)
- [🔐 Gestion des secrets](#-gestion-des-secrets)
- [📊 Monitoring et logs](#-monitoring-et-logs)
- [💾 Snapshots et sauvegarde](#-snapshots-et-sauvegarde)
- [🔄 Procédures de rollback](#-procédures-de-rollback)
- [🚀 Installation et déploiement](#-installation-et-déploiement)
- [📸 Captures d'écran](#-captures-décran)
- [🤝 Contribution](#-contribution)

## 🎯 Présentation du projet

### Contexte

Ce projet implémente une infrastructure complète de déploiement continu (CI/CD) pour une **API REST de supervision de capteurs environnementaux**. L'API est destinée à alimenter une application mobile permettant de monitorer des capteurs IoT (température, humidité, qualité de l'air, etc.) déployés dans différents environnements.

### Objectifs

- ✅ **Infrastructure as Code** complète avec Terraform
- ✅ **Déploiement automatisé** multi-environnements (staging/production)
- ✅ **Pipeline CI/CD** robuste avec tests, sécurité et monitoring
- ✅ **Stratégie GitFlow** structurée avec versionnement sémantique
- ✅ **Monitoring avancé** avec Prometheus, Grafana et alerting
- ✅ **Mécanismes de sauvegarde** avec snapshots automatisés
- ✅ **Procédures de rollback** testées et documentées

### Technologies utilisées

| Catégorie | Technologies |
|-----------|-------------|
| **Infrastructure** | Terraform, Azure Cloud |
| **Configuration** | Ansible, Docker |
| **CI/CD** | GitHub Actions, Docker Registry |
| **Monitoring** | Prometheus, Grafana, Loki, AlertManager |
| **Base de données** | PostgreSQL |
| **API** | Node.js, Express, REST |
| **Sécurité** | Snyk, npm audit, SSL/TLS |

## 🏗️ Architecture

### Vue d'ensemble de l'infrastructure

```
┌─────────────────────────────────────────────────────────────┐
│                    AZURE CLOUD                              │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────────┐    ┌─────────────────┐                 │
│  │   STAGING ENV   │    │ PRODUCTION ENV  │                 │
│  │                 │    │                 │                 │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │                 │
│  │ │Load Balancer│ │    │ │Load Balancer│ │                 │
│  │ └─────────────┘ │    │ └─────────────┘ │                 │
│  │        │        │    │        │        │                 │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │                 │
│  │ │  IoT API    │ │    │ │  IoT API    │ │                 │
│  │ │ (Container) │ │    │ │ (Container) │ │                 │
│  │ └─────────────┘ │    │ └─────────────┘ │                 │
│  │        │        │    │        │        │                 │
│  │ ┌─────────────┐ │    │ ┌─────────────┐ │                 │
│  │ │ PostgreSQL  │ │    │ │ PostgreSQL  │ │                 │
│  │ └─────────────┘ │    │ └─────────────┘ │                 │
│  └─────────────────┘    └─────────────────┘                 │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│                 MONITORING STACK                            │
├─────────────────────────────────────────────────────────────┤
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │ Prometheus  │ │  Grafana    │ │    Loki     │            │
│  │ (Métriques) │ │(Dashboards) │ │   (Logs)    │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
│         │               │               │                   │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐            │
│  │AlertManager │ │  Promtail   │ │ Node Export │            │
│  └─────────────┘ └─────────────┘ └─────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

### Structure du projet

```
📁 iot-api-cicd/
├── 📁 .github/workflows/          # Pipelines CI/CD
│   ├── ci-cd.yml                  # Pipeline principal
│   ├── staging.yml                # Déploiement staging
│   ├── production.yml             # Déploiement production
│   ├── snapshot.yml               # Gestion snapshots
│   └── rollback.yml               # Procédure rollback
├── 📁 api/                        # Code source API REST
│   ├── 📁 src/                    # Code source
│   ├── 📁 tests/                  # Tests unitaires/intégration
│   ├── package.json               # Dépendances Node.js
│   ├── Dockerfile                 # Image Docker
│   └── server.js                  # Point d'entrée
├── 📁 terraform/                  # Infrastructure as Code
│   ├── 📁 environments/
│   │   ├── 📁 staging/           # Config staging
│   │   └── 📁 production/        # Config production
│   ├── 📁 modules/               # Modules Terraform réutilisables
│   ├── main.tf                   # Configuration principale
│   ├── variables.tf              # Variables
│   └── outputs.tf                # Sorties
├── 📁 ansible/                   # Configuration serveurs
│   ├── 📁 roles/                 # Rôles Ansible
│   ├── 📁 inventories/
│   │   ├── 📁 staging/           # Inventaire staging
│   │   └── 📁 production/        # Inventaire production
│   ├── deploy.yml                # Playbook déploiement
│   └── rollback.yml              # Playbook rollback
├── 📁 monitoring/                # Stack monitoring
│   ├── 📁 prometheus/            # Configuration Prometheus
│   ├── 📁 grafana/               # Dashboards Grafana
│   ├── 📁 loki/                  # Configuration Loki
│   └── docker-compose.yml        # Stack monitoring
├── 📁 rollback/                  # Procédures rollback
│   ├── 📁 scripts/               # Scripts rollback
│   └── procedures.md             # Documentation procédures
├── 📁 snapshots/                 # Gestion snapshots
│   ├── 📁 scripts/               # Scripts snapshots
│   └── schedule.yml              # Planification snapshots
├── 📁 scripts/                   # Scripts utilitaires
│   ├── deploy.sh                 # Script déploiement
│   ├── release.sh                # Script release
│   ├── version.sh                # Gestion versions
│   └── rollback.sh               # Script rollback
├── 📁 docs/                      # Documentation
│   ├── gitflow.md                # Documentation GitFlow
│   ├── deployment.md             # Guide déploiement
│   ├── rollback.md               # Guide rollback
│   └── monitoring.md             # Guide monitoring
├── .env.example                  # Template variables
├── CHANGELOG.md                  # Historique versions
└── README.md                     # Documentation principale
```

## 🔄 GitFlow

### Structure des branches

Notre projet utilise **GitFlow** pour organiser le développement :

```
main (production)     ●──●──●──●──●──●
                       │  │  │  │  │  │
develop (staging)      ●──●──●──●──●──●──●──●
                       │     │     │     │
feature/nouvelle-api   ●──●──●     │     │
                             │     │     │
release/v1.2.0              ●──●  │     │
                                   │     │
hotfix/v1.1.1                     ●──●  │
```

| Branche | Rôle | Déploiement | Protection |
|---------|------|-------------|------------|
| `main` | Production stable | 🚀 Production | ✅ Protégée, tags requis |
| `develop` | Intégration | 🧪 Staging | ✅ PR requis |
| `feature/*` | Nouvelles fonctionnalités | - | Tests automatiques |
| `release/*` | Préparation versions | 🧪 Staging | Tests complets |
| `hotfix/*` | Corrections urgentes | 🚀 Production | Fast-track |

### Convention de commits

Nous utilisons [Conventional Commits](https://www.conventionalcommits.org/) :

```
feat(api): ajouter endpoint pour capteurs de température
fix(auth): corriger la validation des tokens JWT  
docs(readme): mettre à jour les instructions d'installation
test(sensors): ajouter tests unitaires pour SensorService
```

**📖 [Documentation GitFlow complète →](docs/gitflow.md)**

## 🚀 Pipeline CI/CD

### Vue d'ensemble du pipeline

```mermaid
graph LR
    A[Push Code] --> B[Lint & Security]
    B --> C[Tests]
    C --> D[Build Docker]
    D --> E[Deploy Staging]
    E --> F[Smoke Tests]
    F --> G{Branche main?}
    G -->|Non| H[End]
    G -->|Oui| I[Tag Version]
    I --> J[Deploy Production]
    J --> K[Snapshot]
    K --> L[Notify Team]
```

### Étapes détaillées

#### 1. **Lint & Security** 🔍
- ESLint pour le code JavaScript
- Prettier pour le formatage
- npm audit pour les vulnérabilités
- Snyk security scan
- Terraform fmt check

#### 2. **Tests** 🧪
- Tests unitaires avec Jest
- Tests d'intégration avec base de données
- Coverage report avec Codecov
- Tests de performance (optionnel)

#### 3. **Build** 🏗️
- Construction image Docker
- Push vers GitHub Container Registry
- Optimisation des layers
- Scan de sécurité de l'image

#### 4. **Deploy Staging** 🧪
- Provisioning infrastructure Terraform
- Configuration serveurs avec Ansible
- Déploiement de l'application
- Health checks automatiques

#### 5. **Tests de fumée** 💨
- Test des endpoints critiques
- Vérification de la connectivité DB
- Tests de performance de base

#### 6. **Versioning** 🏷️
- Bump automatique de version (SemVer)
- Création de tags Git
- Génération du changelog
- Création de GitHub Release

#### 7. **Deploy Production** 🚀
- Déploiement uniquement sur tags
- Blue-green deployment
- Tests de vérification
- Rollback automatique si échec

#### 8. **Post-deployment** 📊
- Création de snapshots
- Monitoring et alerting
- Notifications équipe (Slack)
- Mise à jour documentation

### Fichiers de workflow

| Fichier | Déclencheur | Environnement | Actions |
|---------|-------------|---------------|---------|
| [`ci-cd.yml`](.github/workflows/ci-cd.yml) | Push, PR | Tous | Pipeline complet |
| [`staging.yml`](.github/workflows/staging.yml) | Push develop | Staging | Déploiement staging |
| [`production.yml`](.github/workflows/production.yml) | Tags v* | Production | Déploiement production |
| [`rollback.yml`](.github/workflows/rollback.yml) | Manuel | Staging/Prod | Procédure rollback |
| [`snapshot.yml`](.github/workflows/snapshot.yml) | Planifié | Tous | Snapshots automatiques |

## 📦 Packaging et versioning

### Versionnement sémantique (SemVer)

Nous utilisons le **versionnement sémantique** : `MAJOR.MINOR.PATCH`

```
v1.2.3
│ │ │
│ │ └─ PATCH: Corrections de bugs
│ └─── MINOR: Nouvelles fonctionnalités compatibles
└───── MAJOR: Breaking changes
```

### Processus automatisé

1. **Analyse des commits** avec Conventional Commits
2. **Bump automatique** de version selon les changements
3. **Création de tags Git** automatique
4. **Génération du CHANGELOG.md**
5. **Création de GitHub Releases** avec artefacts

### Artefacts générés

- 📦 **Images Docker** : `ghcr.io/username/iot-api:v1.2.3`
- 📋 **Archives source** : `iot-api-v1.2.3.tar.gz`
- 📄 **Documentation** : README, CHANGELOG, API docs
- 🔧 **Configurations** : Terraform, Ansible, Docker

### Stockage des artefacts

| Type | Stockage | Rétention | Exemple |
|------|----------|-----------|---------|
| Images Docker | GitHub Container Registry | 90 jours | `ghcr.io/username/iot-api:v1.2.3` |
| Releases | GitHub Releases | Permanent | `v1.2.3` avec assets |
| Snapshots | Azure Storage | 30 jours | Snapshots VM et DB |
| Logs CI/CD | GitHub Actions | 90 jours | Historique des builds |

## 🔐 Gestion des secrets

### Stratégie de sécurité

Nous utilisons plusieurs niveaux de protection pour les secrets :

#### 1. **GitHub Secrets** 🔒
Stockage sécurisé des credentials cloud et tokens d'API.

```yaml
# Secrets Azure
AZURE_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID }}
AZURE_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET }}
AZURE_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID }}
AZURE_TENANT_ID: ${{ secrets.AZURE_TENANT_ID }}

# Secrets application
DATABASE_PASSWORD: ${{ secrets.DATABASE_PASSWORD }}
JWT_SECRET: ${{ secrets.JWT_SECRET }}
API_KEY: ${{ secrets.API_KEY }}

# Monitoring
GRAFANA_PASSWORD: ${{ secrets.GRAFANA_PASSWORD }}
SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK_URL }}
```

#### 2. **Variables d'environnement** 🌍
Séparation claire entre staging et production.

```bash
# .env.staging
NODE_ENV=staging
DATABASE_URL=postgres://user:pass@staging-db:5432/iot_staging
API_URL=https://iot-api-staging.example.com
LOG_LEVEL=debug

# .env.production  
NODE_ENV=production
DATABASE_URL=postgres://user:pass@prod-db:5432/iot_production
API_URL=https://iot-api.example.com
LOG_LEVEL=info
```

#### 3. **Azure Key Vault** 🗝️
Gestion centralisée des secrets pour les applications déployées.

### Bonnes pratiques appliquées

- ✅ **Rotation automatique** des secrets sensibles
- ✅ **Principe du moindre privilège** pour les accès
- ✅ **Chiffrement** des secrets au repos et en transit
- ✅ **Audit** des accès aux secrets
- ✅ **Séparation** stricte staging/production
- ✅ **Pas de secrets** dans le code source ou les logs

## 📊 Monitoring et logs

### Stack de monitoring

Notre infrastructure de monitoring complète inclut :

#### **Prometheus** 📈
Collecte de métriques temps réel avec plus de 50 métriques :

- **Métriques applicatives** : Latence, throughput, erreurs
- **Métriques système** : CPU, mémoire, disque, réseau  
- **Métriques infrastructure** : Azure VM, Load Balancer, Database
- **Métriques business** : Nombre de capteurs, données collectées

#### **Grafana** 📊
Dashboards visuels avec alerting intégré :

- 🖥️ **Dashboard Infrastructure** : Vue d'ensemble serveurs
- 📱 **Dashboard Application** : Métriques API et performance  
- 🗄️ **Dashboard Database** : PostgreSQL monitoring
- 🌐 **Dashboard Business** : KPIs métier et usage

#### **Loki + Promtail** 📝
Collecte et agrégation de logs centralisée :

- 📋 **Logs applicatifs** : API requests, erreurs, debug
- 🐳 **Logs conteneurs** : Docker containers et orchestration
- 🔧 **Logs système** : Syslog, auth, kern
- 🚀 **Logs déploiement** : CI/CD, Terraform, Ansible

### Configuration des alertes

#### Alertes critiques ⚠️
- API indisponible > 30s
- Erreurs 5xx > 5%
- CPU > 80% pendant 5min
- Espace disque < 15%
- Certificat SSL expire dans 30 jours

#### Notifications 📧
- **Slack** : Canal #alerts pour l'équipe
- **Email** : Escalade pour alertes critiques
- **PagerDuty** : Astreinte 24/7 production

## 💾 Snapshots et sauvegarde

### Stratégie de sauvegarde

Notre approche multi-niveaux garantit la récupération en cas de problème :

#### **Snapshots automatiques** 📸
- **Fréquence** : Quotidien à 2h00 UTC
- **Rétention** : 30 jours
- **Déclencheurs** : 
  - Avant chaque déploiement production
  - Avant opérations de maintenance
  - Sur demande via workflow manuel

#### **Composants sauvegardés** 💾

1. **Virtual Machines Azure**
   - Snapshots des disques OS et données
   - Configuration réseau et sécurité
   - Tags et métadonnées

2. **Base de données PostgreSQL**
   - Dumps SQL complets
   - Point-in-time recovery activé
   - Réplication cross-region

3. **État Terraform**
   - Fichiers d'état (terraform.tfstate)
   - Variables et outputs
   - Configuration modules

4. **Configuration application**
   - Variables d'environnement
   - Certificats et secrets
   - Configuration nginx/load balancer

### Scripts de gestion

| Script | Description | Usage |
|--------|-------------|-------|
| [`create-snapshot.sh`](snapshots/scripts/create-snapshot.sh) | Création manuelle snapshot | `./create-snapshot.sh staging` |
| [`restore-snapshot.sh`](snapshots/scripts/restore-snapshot.sh) | Restauration snapshot | `./restore-snapshot.sh staging v1.2.3` |
| [`list-snapshots.sh`](snapshots/scripts/list-snapshots.sh) | Liste des snapshots | `./list-snapshots.sh production` |
| [`cleanup-snapshots.sh`](snapshots/scripts/cleanup-snapshots.sh) | Nettoyage ancien snapshots | `./cleanup-snapshots.sh` |

### Planification automatique

```yaml
# .github/workflows/snapshot.yml
schedule:
  - cron: '0 2 * * *'  # Tous les jours à 2h00 UTC
```

## 🔄 Procédures de rollback

### Types de rollback

Notre stratégie de rollback couvre plusieurs niveaux :

#### **1. Rollback applicatif** 🔄
Retour à une version antérieure de l'application sans changement d'infrastructure.

```bash
# Via GitHub Actions workflow
gh workflow run rollback.yml \
  -f environment=production \
  -f target_version=v1.2.3 \
  -f rollback_type=application \
  -f confirm_rollback=CONFIRM
```

#### **2. Rollback infrastructure** 🏗️
Restauration complète de l'infrastructure via snapshot.

```bash
# Restauration d'un snapshot complet
./snapshots/scripts/restore-snapshot.sh production snapshot-20241201-020000
```

#### **3. Rollback complet** 🔄
Combinaison application + infrastructure pour un retour total.

### Procédure de rollback

#### **Étape 1 : Évaluation** 🔍
- Identifier la cause du problème
- Déterminer le type de rollback nécessaire
- Choisir la version/snapshot cible

#### **Étape 2 : Sauvegarde pré-rollback** 💾
- Création automatique d'un snapshot de l'état actuel
- Backup des logs et métriques actuels
- Notification de l'équipe

#### **Étape 3 : Exécution** ⚡
- Arrêt des services concernés
- Restauration selon le type choisi
- Redémarrage et vérifications

#### **Étape 4 : Validation** ✅
- Tests de fonctionnement
- Vérification des métriques
- Validation par l'équipe

#### **Étape 5 : Communication** 📢
- Notification de fin de rollback
- Rapport détaillé
- Post-mortem si nécessaire

### Temps de récupération (RTO/RPO)

| Type | RTO (Recovery Time) | RPO (Recovery Point) |
|------|-------------------|---------------------|
| Application | < 5 minutes | < 1 minute |
| Infrastructure | < 15 minutes | < 24 heures |
| Base de données | < 10 minutes | < 1 heure |
| Rollback complet | < 20 minutes | < 24 heures |

## 🚀 Installation et déploiement

### Prérequis

- **Git** avec accès au repository
- **Docker** et Docker Compose
- **Terraform** >= 1.6.0
- **Ansible** >= 2.9
- **Azure CLI** avec souscription active
- **Node.js** >= 18 pour le développement local

### Installation locale

```bash
# 1. Cloner le repository
git clone https://github.com/username/iot-api-cicd.git
cd iot-api-cicd

# 2. Configurer les variables d'environnement
cp .env.example .env
# Éditer .env avec vos valeurs

# 3. Installer les dépendances API
cd api
npm install
npm run test

# 4. Lancer le stack de monitoring (optionnel)
cd ../monitoring
docker-compose up -d

# 5. Vérifier la configuration Terraform
cd ../terraform/environments/staging
terraform init
terraform plan
```

### Déploiement automatique

#### **Déploiement staging** 🧪

Le déploiement staging se déclenche automatiquement sur :
- Push sur la branche `develop`
- Merge d'une Pull Request vers `develop`

```bash
# Exemple de déploiement feature
git checkout develop
git pull origin develop
git checkout -b feature/nouvelle-api
# ... développement ...
git add .
git commit -m "feat(api): ajouter endpoint capteurs température"
git push origin feature/nouvelle-api
# Créer PR vers develop
```

#### **Déploiement production** 🚀

Le déploiement production se déclenche sur :
- Push d'un tag version (ex: `v1.2.3`)
- Release GitHub

```bash
# Créer une release
git checkout main
git tag -a v1.2.3 -m "Release v1.2.3"
git push origin v1.2.3
# Le pipeline CI/CD se déclenche automatiquement
```

### Déploiement manuel

Pour un déploiement manuel d'urgence :

```bash
# 1. Déployer l'infrastructure
cd terraform/environments/production
terraform init
terraform plan
terraform apply

# 2. Configurer les serveurs
cd ../../../ansible
ansible-playbook -i inventories/production/hosts deploy.yml

# 3. Vérifier le déploiement
curl https://iot-api.example.com/health
```

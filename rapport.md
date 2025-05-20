# Rapport - Pipeline de Déploiement Continu pour API IoT

## Architecture de l'infrastructure

### Choix du provider

Pour ce projet, j'ai choisi **Azure** comme fournisseur cloud pour les raisons suivantes :
- Interface utilisateur intuitive et documentation complète
- Bonne intégration avec les outils DevOps
- Offre gratuite pour les nouveaux utilisateurs (crédits de démarrage)
- Support natif pour Linux et Windows

### Architecture

![Architecture](https://i.imgur.com/REMPLACER_PAR_UNE_IMAGE.png)

L'architecture se compose des éléments suivants :
1. **Machine Virtuelle Ubuntu** : Héberge notre API Node.js
2. **Réseau Virtuel** : Isole notre infrastructure
3. **Groupe de Sécurité Réseau** : Contrôle le trafic entrant et sortant
4. **IP Publique** : Permet l'accès à notre API depuis Internet

## Configuration Terraform

### Structure des fichiers

```
infra/
├── main.tf           # Configuration principale
├── variables.tf      # Définition des variables
├── outputs.tf        # Définition des sorties
└── terraform.tfvars  # Valeurs des variables (non commité)
```

### Fonctionnement

La configuration Terraform :
1. Crée un groupe de ressources Azure
2. Provisionne un réseau virtuel et un sous-réseau
3. Configure une IP publique pour l'accès externe
4. Définit un groupe de sécurité autorisant les ports SSH (22) et API (3000)
5. Déploie une VM Ubuntu avec une clé SSH pour l'accès

### Exécution

```bash
cd infra
terraform init
terraform plan
terraform apply
```

Après exécution, Terraform affiche l'adresse IP publique de la VM et l'URL de l'API.

## Configuration Ansible

### Structure des fichiers

```
ansible/
├── inventory.ini  # Inventaire des serveurs
└── deploy.yml     # Playbook de déploiement
```

### Fonctionnement du playbook

Le playbook Ansible :
1. Met à jour le système
2. Installe Git et Node.js
3. Installe PM2 pour la gestion des processus Node.js
4. Clone ou met à jour le code source depuis GitHub
5. Installe les dépendances npm
6. Démarre ou redémarre l'application avec PM2
7. Configure PM2 pour démarrer automatiquement au boot

### Exécution

```bash
ansible-playbook -i ansible/inventory.ini ansible/deploy.yml
```

## Pipeline CI/CD

### Outil choisi

J'ai choisi **GitHub Actions** pour l'orchestration CI/CD car :
- Intégration native avec GitHub
- Configuration simple en YAML
- Exécuteurs gratuits pour les projets publics
- Support des secrets pour les informations sensibles

### Fonctionnement

Le pipeline CI/CD :
1. Est déclenché par un push de tag (`v*`)
2. Récupère le code source
3. Configure l'environnement (Node.js, Ansible)
4. Configure la clé SSH pour l'accès à la VM
5. Met à jour l'inventaire Ansible avec l'IP du serveur
6. Exécute le script de release.sh

### Déroulement

Lorsqu'un tag est poussé, GitHub Actions exécute le workflow :
1. Checkout du code
2. Installation des dépendances
3. Configuration de l'environnement
4. Exécution du script de release

## Défis rencontrés et solutions

### Défi 1 : Configuration de l'authentification Azure

**Problème** : Difficultés à configurer l'authentification Terraform avec Azure.

**Solution** : Création d'un Service Principal avec les droits nécessaires et stockage sécurisé des identifiants.

### Défi 2 : Transfert de la clé SSH dans GitHub Actions

**Problème** : Comment transférer la clé SSH de manière sécurisée.

**Solution** : Utilisation des secrets GitHub pour stocker la clé privée et l'injecter dans le workflow.

### Défi 3 : Persistance de PM2 après redémarrage

**Problème** : L'application ne redémarrait pas après un reboot de la VM.

**Solution** : Configuration de PM2 pour démarrer au boot avec `pm2 startup` et `pm2 save`.

## Conclusion

Ce projet a permis de mettre en place une infrastructure complète de déploiement continu pour une API IoT. L'utilisation de Terraform, Ansible et GitHub Actions a permis d'automatiser l'ensemble du processus, de la création de l'infrastructure jusqu'au déploiement de l'application.

Les améliorations futures pourraient inclure :
- Mise en place de tests automatisés
- Monitoring de l'application
- Sauvegarde automatique des données
- Mise à l'échelle automatique de l'infrastructure
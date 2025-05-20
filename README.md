# Projet Pipeline de Déploiement Continu - IoT

Ce projet implémente une infrastructure complète pour le déploiement continu d'une API REST de supervision de capteurs environnementaux.

## Structure du projet

- `infra/` : Configuration Terraform pour le provisionnement de l'infrastructure
- `ansible/` : Playbooks Ansible pour la configuration et le déploiement
- `api/` : Code source de l'API REST
- `.github/workflows/` : Configuration CI/CD GitHub Actions
- `release.sh` : Script de release
- `rapport.md` : Documentation du projet

## Fonctionnalités

- Provisionnement automatisé de l'infrastructure sur Azure avec Terraform
- Configuration et déploiement automatique avec Ansible
- Pipeline CI/CD avec GitHub Actions
- API REST pour collecter et lire des données de capteurs environnementaux
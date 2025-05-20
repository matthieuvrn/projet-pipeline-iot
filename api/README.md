# API de supervision de capteurs environnementaux

API REST simple pour collecter et lire des données de capteurs environnementaux.

## Installation

```bash
npm install
```

## Démarrage

```bash
npm start
```

L'API sera disponible sur http://localhost:3000

## Endpoints

- `GET /` - Page d'accueil
- `GET /api/sensors` - Récupérer tous les capteurs
- `GET /api/sensors/:id` - Récupérer un capteur par ID
- `POST /api/sensors/:id/data` - Ajouter une nouvelle valeur pour un capteur

## Exemple de requête

```bash
curl -X POST -H "Content-Type: application/json" -d '{"value": 23.5}' http://localhost:3000/api/sensors/1/data
```
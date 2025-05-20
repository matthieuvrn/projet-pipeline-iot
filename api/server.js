const express = require('express');
const cors = require('cors');
const dotenv = require('dotenv');

// Configuration des variables d'environnement
dotenv.config();

// Initialisation de l'application Express
const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
app.use(express.json());

// Base de données simulée pour les capteurs
const sensors = [
  { id: 1, name: 'Temperature Sensor', value: 22.5, unit: 'C', location: 'Living Room', lastUpdate: new Date() },
  { id: 2, name: 'Humidity Sensor', value: 45, unit: '%', location: 'Bathroom', lastUpdate: new Date() },
  { id: 3, name: 'CO2 Sensor', value: 415, unit: 'ppm', location: 'Kitchen', lastUpdate: new Date() },
];

// Routes API

// Route d'accueil
app.get('/', (req, res) => {
  res.json({ message: 'API de supervision de capteurs environnementaux' });
});

// Récupérer tous les capteurs
app.get('/api/sensors', (req, res) => {
  res.json(sensors);
});

// Récupérer un capteur par ID
app.get('/api/sensors/:id', (req, res) => {
  const id = parseInt(req.params.id);
  const sensor = sensors.find(s => s.id === id);
  
  if (!sensor) {
    return res.status(404).json({ message: 'Capteur non trouvé' });
  }
  
  res.json(sensor);
});

// Ajouter une nouvelle valeur pour un capteur
app.post('/api/sensors/:id/data', (req, res) => {
  const id = parseInt(req.params.id);
  const { value } = req.body;
  
  if (value === undefined) {
    return res.status(400).json({ message: 'La valeur est requise' });
  }
  
  const sensorIndex = sensors.findIndex(s => s.id === id);
  
  if (sensorIndex === -1) {
    return res.status(404).json({ message: 'Capteur non trouvé' });
  }
  
  sensors[sensorIndex].value = value;
  sensors[sensorIndex].lastUpdate = new Date();
  
  res.json(sensors[sensorIndex]);
});

// Démarrage du serveur
app.listen(PORT, () => {
  console.log(`Serveur démarré sur le port ${PORT}`);
});

module.exports = app; // Pour les tests
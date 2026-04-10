// Service de capture audio + GPS.
// Gère le cycle de vie de l'enregistrement via le package `record`,
// acquiert la position GPS au moment du démarrage via `geolocator`,
// et persiste le [FieldRecording] résultant via [StoriesLocalDatasource].

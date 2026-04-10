// Service de synchronisation vers PocketBase.
// Surveille la connectivité réseau via `connectivity_plus`,
// itère sur les [FieldRecording] dont le [SyncStatus] est `pending`,
// uploade le fichier audio et les métadonnées, puis met à jour le statut local.

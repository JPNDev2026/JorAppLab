package com.example.jorat_geofence

import android.content.ContentUris
import android.content.Context
import android.content.ContentValues
import android.net.ConnectivityManager
import android.net.NetworkCapabilities
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import android.telephony.TelephonyManager
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val TAG = "JoratDownloads"
        private const val DOWNLOAD_CHANNEL = "jorat/downloads"
        private const val NETWORK_CHANNEL = "jorat/network"
    }

    private val downloadUriCache = mutableMapOf<String, Uri>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, DOWNLOAD_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "saveCsvToDownloads") {
                    val fileName = call.argument<String>("fileName")
                    val content = call.argument<String>("content")
                    if (fileName.isNullOrBlank() || content == null) {
                        result.error("INVALID_ARGS", "Paramètres fileName/content manquants", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val location = saveCsvToDownloads(fileName, content)
                        result.success(location)
                    } catch (e: Exception) {
                        result.error("SAVE_FAILED", e.message, null)
                    }
                } else {
                    result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getNetworkType") {
                    try {
                        result.success(getNetworkType())
                    } catch (_: Exception) {
                        result.success("unknown")
                    }
                } else {
                    result.notImplemented()
                }
            }
    }

    private fun saveCsvToDownloads(fileName: String, content: String): String {
        val safeName = if (fileName.endsWith(".csv")) fileName else "$fileName.csv"
        val resolver = applicationContext.contentResolver

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val cachedUri = downloadUriCache[safeName]
            if (cachedUri != null) {
                try {
                    writeContentToUri(cachedUri, content)
                    return cachedUri.toString()
                } catch (_: Exception) {
                    downloadUriCache.remove(safeName)
                    safeDeleteUri(cachedUri)
                }
            }

            val downloadRelativePath = "${Environment.DIRECTORY_DOWNLOADS}/"
            val existingUri = findExistingDownloadUri(safeName, downloadRelativePath)
                ?: findExistingDownloadUri(safeName, Environment.DIRECTORY_DOWNLOADS)
                ?: findExistingDownloadUri(safeName, null)
            if (existingUri != null) {
                try {
                    writeContentToUri(existingUri, content)
                    downloadUriCache[safeName] = existingUri
                    return existingUri.toString()
                } catch (_: Exception) {
                    downloadUriCache.remove(safeName)
                    safeDeleteUri(existingUri)
                }
            }

            var uri = tryInsertDownload(safeName, downloadRelativePath)
            if (uri == null) {
                val fallbackUri = findExistingDownloadUri(safeName, downloadRelativePath)
                    ?: findExistingDownloadUri(safeName, Environment.DIRECTORY_DOWNLOADS)
                    ?: findExistingDownloadUri(safeName, null)
                if (fallbackUri != null) {
                    writeContentToUri(fallbackUri, content)
                    downloadUriCache[safeName] = fallbackUri
                    return fallbackUri.toString()
                }

                purgeDownloadRowsByName(safeName)
                uri = tryInsertDownload(safeName, downloadRelativePath)
                    ?: throw IllegalStateException(
                        "Impossible de créer le fichier dans Téléchargements"
                    )
            }

            try {
                writeContentToUri(uri, content)

                val values = ContentValues().apply {
                    put(MediaStore.MediaColumns.IS_PENDING, 0)
                }
                resolver.update(uri, values, null, null)
                downloadUriCache[safeName] = uri
                return uri.toString()
            } catch (e: Exception) {
                safeDeleteUri(uri)
                throw e
            }
        }

        @Suppress("DEPRECATION")
        val downloadsDir = Environment.getExternalStoragePublicDirectory(
            Environment.DIRECTORY_DOWNLOADS
        )
        if (!downloadsDir.exists()) {
            downloadsDir.mkdirs()
        }

        val file = File(downloadsDir, safeName)
        file.writeText(content, Charsets.UTF_8)
        return file.absolutePath
    }

    private fun tryInsertDownload(fileName: String, relativePath: String): Uri? {
        val resolver = applicationContext.contentResolver
        val values = ContentValues().apply {
            put(MediaStore.MediaColumns.DISPLAY_NAME, fileName)
            put(MediaStore.MediaColumns.MIME_TYPE, "text/csv")
            put(MediaStore.MediaColumns.RELATIVE_PATH, relativePath)
            put(MediaStore.MediaColumns.IS_PENDING, 1)
        }

        return try {
            resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
        } catch (e: Exception) {
            Log.w(TAG, "insert failed for $fileName: ${e.message}")
            null
        }
    }

    private fun purgeDownloadRowsByName(fileName: String) {
        val resolver = applicationContext.contentResolver
        val selection = "${MediaStore.MediaColumns.DISPLAY_NAME} = ?"
        val args = arrayOf(fileName)

        try {
            resolver.delete(MediaStore.Downloads.EXTERNAL_CONTENT_URI, selection, args)
        } catch (e: Exception) {
            Log.w(TAG, "purge downloads failed for $fileName: ${e.message}")
        }

        try {
            resolver.delete(MediaStore.Files.getContentUri("external"), selection, args)
        } catch (e: Exception) {
            Log.w(TAG, "purge files failed for $fileName: ${e.message}")
        }
    }

    private fun safeDeleteUri(uri: Uri) {
        val resolver = applicationContext.contentResolver
        try {
            resolver.delete(uri, null, null)
        } catch (e: Exception) {
            Log.w(TAG, "delete uri failed for $uri: ${e.message}")
        }
    }

    private fun writeContentToUri(uri: Uri, content: String) {
        val resolver = applicationContext.contentResolver
        resolver.openOutputStream(uri, "wt")?.use { stream ->
            stream.write(content.toByteArray(Charsets.UTF_8))
        } ?: throw IllegalStateException("Impossible d'écrire le fichier CSV")
    }

    private fun findExistingDownloadUri(fileName: String, relativePath: String? = null): Uri? {
        val resolver = applicationContext.contentResolver
        val projection = arrayOf(MediaStore.MediaColumns._ID)
        val (selection, selectionArgs) = if (relativePath != null) {
            Pair(
                "${MediaStore.MediaColumns.DISPLAY_NAME} = ? AND ${MediaStore.MediaColumns.RELATIVE_PATH} = ?",
                arrayOf(fileName, relativePath)
            )
        } else {
            Pair(
                "${MediaStore.MediaColumns.DISPLAY_NAME} = ?",
                arrayOf(fileName)
            )
        }

        val fromDownloads = queryForFileUri(
            baseUri = MediaStore.Downloads.EXTERNAL_CONTENT_URI,
            projection = projection,
            selection = selection,
            selectionArgs = selectionArgs,
            sortOrder = "${MediaStore.MediaColumns.DATE_MODIFIED} DESC"
        )
        if (fromDownloads != null) return fromDownloads

        val filesUri = MediaStore.Files.getContentUri("external")
        val fromFiles = queryForFileUri(
            baseUri = filesUri,
            projection = projection,
            selection = selection,
            selectionArgs = selectionArgs,
            sortOrder = "${MediaStore.MediaColumns.DATE_MODIFIED} DESC"
        )
        if (fromFiles != null) return fromFiles

        return null
    }

    private fun queryForFileUri(
        baseUri: Uri,
        projection: Array<String>,
        selection: String,
        selectionArgs: Array<String>,
        sortOrder: String
    ): Uri? {
        val resolver = applicationContext.contentResolver
        resolver.query(
            baseUri,
            projection,
            selection,
            selectionArgs,
            sortOrder
        )?.use { cursor ->
            if (cursor.moveToFirst()) {
                val idColumn = cursor.getColumnIndexOrThrow(MediaStore.MediaColumns._ID)
                val id = cursor.getLong(idColumn)
                return ContentUris.withAppendedId(baseUri, id)
            }
        }
        return null
    }

    private fun getNetworkType(): String {
        val connectivityManager =
            getSystemService(Context.CONNECTIVITY_SERVICE) as? ConnectivityManager
                ?: return "unknown"

        val network = connectivityManager.activeNetwork ?: return "none"
        val capabilities = connectivityManager.getNetworkCapabilities(network) ?: return "none"

        return when {
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_WIFI) -> "wifi"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_ETHERNET) -> "ethernet"
            capabilities.hasTransport(NetworkCapabilities.TRANSPORT_CELLULAR) -> getMobileGeneration()
            else -> "other"
        }
    }

    private fun getMobileGeneration(): String {
        val telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
            ?: return "mobile"

        val networkType = try {
            telephonyManager.dataNetworkType
        } catch (_: SecurityException) {
            0
        }

        if (networkType == 0) {
            val serviceStateText = try {
                telephonyManager.serviceState?.toString()?.lowercase()
            } catch (_: Exception) {
                null
            } ?: ""

            if (serviceStateText.contains("nrstate=connected") ||
                serviceStateText.contains("nrstate=not_restricted")) {
                return "5g"
            }
        }

        return when (networkType) {
            // TelephonyManager network type integer values (stable Android constants).
            1, 2, 4, 7, 11, 16 -> "2g" // GPRS, EDGE, CDMA, 1xRTT, IDEN, GSM
            3, 5, 6, 8, 9, 10, 12, 14, 15, 17 -> "3g" // UMTS/EVDO/HSPA/eHRPD/TD-SCDMA
            13, 18, 19 -> "4g" // LTE, IWLAN, LTE_CA
            20 -> "5g" // NR

            else -> "mobile"
        }
    }
}

package com.vampirenodes.mobile

import android.Manifest
import android.app.Activity
import android.content.Context
import android.media.AudioManager
import android.speech.RecognizerIntent
import java.util.Locale
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.view.View
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.webkit.JavascriptInterface
import android.webkit.WebChromeClient
import android.webkit.PermissionRequest
import androidx.webkit.WebViewAssetLoader
import android.webkit.ValueCallback
import android.webkit.WebView
import android.webkit.WebViewClient

class MainActivity : Activity() {
    private lateinit var webView: WebView
    private var pendingAudioRequest: PermissionRequest? = null
    private var pendingFileChooser: ValueCallback<Array<Uri>>? = null
    private val assetLoader by lazy {
        WebViewAssetLoader.Builder()
            .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(this))
            .build()
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        webView = WebView(this).apply {
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.allowFileAccess = false
            settings.allowContentAccess = true
            settings.allowFileAccessFromFileURLs = false
            settings.allowUniversalAccessFromFileURLs = false
            settings.mixedContentMode = android.webkit.WebSettings.MIXED_CONTENT_NEVER_ALLOW
            settings.mediaPlaybackRequiresUserGesture = true
            webViewClient = object : WebViewClient() {
                override fun shouldInterceptRequest(view: WebView, request: android.webkit.WebResourceRequest): android.webkit.WebResourceResponse? {
                    return assetLoader.shouldInterceptRequest(request.url)
                }
                override fun shouldOverrideUrlLoading(view: WebView, request: android.webkit.WebResourceRequest): Boolean {
                    val uri = request.url
                    if (uri.scheme == "https" && uri.host == "appassets.androidplatform.net") return false
                    if (uri.scheme == "https" || uri.scheme == "mailto" || uri.scheme == "tel") {
                        return try {
                            startActivity(Intent(Intent.ACTION_VIEW, uri))
                            true
                        } catch (_: Exception) {
                            true
                        }
                    }
                    return true
                }
            }
            webChromeClient = object : WebChromeClient() {
                override fun onShowFileChooser(
                    view: WebView,
                    filePathCallback: ValueCallback<Array<Uri>>,
                    fileChooserParams: FileChooserParams
                ): Boolean {
                    pendingFileChooser?.onReceiveValue(null)
                    pendingFileChooser = filePathCallback
                    val picker = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "image/*"
                        putExtra(Intent.EXTRA_MIME_TYPES, arrayOf("image/png", "image/jpeg", "image/webp", "image/gif"))
                        putExtra(Intent.EXTRA_ALLOW_MULTIPLE, false)
                    }
                    return try {
                        startActivityForResult(picker, REQUEST_IMAGE)
                        true
                    } catch (_: Exception) {
                        pendingFileChooser = null
                        filePathCallback.onReceiveValue(null)
                        false
                    }
                }

                override fun onPermissionRequest(request: PermissionRequest) {
                    runOnUiThread {
                        val wantsAudio = request.resources.contains(PermissionRequest.RESOURCE_AUDIO_CAPTURE)
                        val unsupported = request.resources.filter { it != PermissionRequest.RESOURCE_AUDIO_CAPTURE }
                        if (!wantsAudio || unsupported.isNotEmpty()) {
                            request.deny()
                        } else if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                            request.grant(arrayOf(PermissionRequest.RESOURCE_AUDIO_CAPTURE))
                        } else {
                            pendingAudioRequest?.deny()
                            pendingAudioRequest = request
                            requestPermissions(arrayOf(Manifest.permission.RECORD_AUDIO), REQUEST_AUDIO)
                        }
                    }
                }
            }
            addJavascriptInterface(HomeBridge(), "VampireNative")
            loadUrl("https://appassets.androidplatform.net/assets/experience.html")
        }
        setContentView(webView)
        hideSystemBarsForLauncher()
    }

    private fun hideSystemBarsForLauncher() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            window.insetsController?.let { controller ->
                controller.hide(WindowInsets.Type.statusBars() or WindowInsets.Type.navigationBars())
                controller.systemBarsBehavior = WindowInsetsController.BEHAVIOR_SHOW_TRANSIENT_BARS_BY_SWIPE
            }
        } else {
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = (
                View.SYSTEM_UI_FLAG_FULLSCREEN or View.SYSTEM_UI_FLAG_HIDE_NAVIGATION or
                    View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY or View.SYSTEM_UI_FLAG_LAYOUT_STABLE or
                    View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN or View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
            )
        }
    }

    @Deprecated("Deprecated Android callback retained for the platform file picker")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_IMAGE) {
            val callback = pendingFileChooser
            pendingFileChooser = null
            val result = if (resultCode == RESULT_OK && data?.data != null) arrayOf(data.data!!) else null
            callback?.onReceiveValue(result)
        } else if (requestCode == REQUEST_VOICE && resultCode == RESULT_OK) {
            val spoken = data?.getStringArrayListExtra(RecognizerIntent.EXTRA_RESULTS)?.firstOrNull()
            if (!spoken.isNullOrBlank() && ::webView.isInitialized) {
                val encoded = org.json.JSONObject.quote(spoken)
                webView.evaluateJavascript("window.allinesHandleSpeech && window.allinesHandleSpeech($encoded)", null)
            }
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == REQUEST_AUDIO) {
            val request = pendingAudioRequest
            pendingAudioRequest = null
            if (request != null) {
                if (grantResults.isNotEmpty() && grantResults[0] == android.content.pm.PackageManager.PERMISSION_GRANTED) {
                    request.grant(arrayOf(PermissionRequest.RESOURCE_AUDIO_CAPTURE))
                } else {
                    request.deny()
                }
            }
        }
    }

    override fun onDestroy() {
        pendingAudioRequest?.deny()
        pendingAudioRequest = null
        pendingFileChooser?.onReceiveValue(null)
        pendingFileChooser = null
        if (::webView.isInitialized) {
            webView.stopLoading()
            webView.loadUrl("about:blank")
            webView.removeJavascriptInterface("VampireNative")
            webView.destroy()
        }
        super.onDestroy()
    }

    override fun onWindowFocusChanged(hasFocus: Boolean) {
        super.onWindowFocusChanged(hasFocus)
        if (hasFocus) hideSystemBarsForLauncher()
    }

    @Deprecated("Deprecated Android callback retained for the launcher back action")
    override fun onBackPressed() {
        if (!::webView.isInitialized) {
            exitToSystemHome()
            return
        }
        webView.evaluateJavascript("window.vampireHandleBack ? window.vampireHandleBack() : false") { result ->
            if (result != "true") {
                if (webView.canGoBack()) webView.goBack() else exitToSystemHome()
            }
        }
    }

    private fun exitToSystemHome() {
        val home = Intent(Intent.ACTION_MAIN).addCategory(Intent.CATEGORY_HOME)
        home.flags = Intent.FLAG_ACTIVITY_NEW_TASK
        startActivity(home)
    }

    private inner class HomeBridge {
        @JavascriptInterface
        fun exitToHome() { runOnUiThread { exitToSystemHome() } }

        @JavascriptInterface
        fun launchApp(name: String): Boolean {
            val intent: Intent = when (name) {
                "Phone" -> Intent(Intent.ACTION_DIAL)
                "Messages" -> Intent(Intent.ACTION_SENDTO, Uri.parse("smsto:"))
                "Camera" -> Intent("android.media.action.IMAGE_CAPTURE")
                "Gallery" -> Intent(Intent.ACTION_GET_CONTENT).setType("image/*")
                "Files", "Downloads" -> Intent(Intent.ACTION_OPEN_DOCUMENT).addCategory(Intent.CATEGORY_OPENABLE).setType("*/*")
                "Contacts" -> Intent(Intent.ACTION_VIEW, android.provider.ContactsContract.Contacts.CONTENT_URI)
                "Calendar" -> Intent(Intent.ACTION_MAIN).addCategory("android.intent.category.APP_CALENDAR")
                "Browser" -> Intent(Intent.ACTION_VIEW, Uri.parse("https://www.google.com"))
                "Maps" -> Intent(Intent.ACTION_VIEW, Uri.parse("geo:0,0?q=nearby"))
                "Settings" -> Intent(android.provider.Settings.ACTION_SETTINGS)
                else -> return false
            }
            return try {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                true
            } catch (_: Exception) { false }
        }

        @JavascriptInterface
        fun openSystemPanel(action: String) {
            val actions = mapOf(
                "wifi" to android.provider.Settings.ACTION_WIFI_SETTINGS,
                "bluetooth" to android.provider.Settings.ACTION_BLUETOOTH_SETTINGS,
                "display" to android.provider.Settings.ACTION_DISPLAY_SETTINGS,
                "sound" to android.provider.Settings.ACTION_SOUND_SETTINGS,
                "location" to android.provider.Settings.ACTION_LOCATION_SOURCE_SETTINGS,
                "dnd" to android.provider.Settings.ACTION_NOTIFICATION_POLICY_ACCESS_SETTINGS,
                "airplane" to android.provider.Settings.ACTION_AIRPLANE_MODE_SETTINGS,
                "hotspot" to android.provider.Settings.ACTION_WIRELESS_SETTINGS,
                "settings" to android.provider.Settings.ACTION_SETTINGS
            )
            val target = actions[action] ?: return
            runOnUiThread {
                try { startActivity(Intent(target)) } catch (_: Exception) {
                    try { startActivity(Intent(android.provider.Settings.ACTION_SETTINGS)) } catch (_: Exception) { }
                }
            }
        }

        @JavascriptInterface
        fun setWindowBrightness(level: Double) {
            val safe = level.coerceIn(0.05, 1.0).toFloat()
            runOnUiThread {
                val params = window.attributes
                params.screenBrightness = safe
                window.attributes = params
            }
        }

        @JavascriptInterface
        fun setMediaVolume(percent: Int) {
            runOnUiThread {
                val audio = getSystemService(Context.AUDIO_SERVICE) as AudioManager
                val max = audio.getStreamMaxVolume(AudioManager.STREAM_MUSIC)
                val target = ((percent.coerceIn(0, 100) / 100.0) * max).toInt()
                audio.setStreamVolume(AudioManager.STREAM_MUSIC, target, 0)
            }
        }

        @JavascriptInterface
        fun startVoiceInput() {
            runOnUiThread {
                try {
                    val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                        putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                        putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault().toLanguageTag())
                        putExtra(RecognizerIntent.EXTRA_PROMPT, "Speak to Allince")
                    }
                    startActivityForResult(intent, REQUEST_VOICE)
                } catch (_: Exception) {
                    webView.evaluateJavascript("document.querySelector('#allines-status').textContent='Voice service unavailable'", null)
                }
            }
        }
    }
    companion object {
        private const val REQUEST_AUDIO = 7101
        private const val REQUEST_IMAGE = 7102
        private const val REQUEST_VOICE = 7103
    }
}

package com.example.virtual_tryon

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Register our hand-written plugin alongside the generated ones.
        flutterEngine.plugins.add(FaceTrackerPlugin())
    }
}

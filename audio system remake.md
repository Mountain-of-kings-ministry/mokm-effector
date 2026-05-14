1. Low-level Audio Engine
   * Pull-based Architecture: Transitioned AudioEngine from QMediaPlayer to QAudioSink. This allows for direct access
     to the audio buffer before it reaches the hardware.
   * AudioEngineDevice: Implemented a custom QIODevice that performs the following on every buffer request:
       * Fetches raw samples from all active AudioLayer objects.
       * Applies track-level volume, panning, and master volume.
       * Real-time Processing: Passes the mixed audio through the track's EffectChain, supporting both CLAP and VST3
         plugins.
       * Synchronization: Automatically advances the TimelineModel frame based on the number of audio samples
         processed, ensuring perfect sync between audio and video.

  2. Parameter Automation
   * Dynamic Properties: Updated EffectInstance to intercept dynamic property changes. This allows the TimelineModel
     to animate plugin parameters using the existing keyframe system without needing to know the specifics of each
     plugin.
   * Keyframe Integration: Updated KeyframeEditor.qml to automatically list all automatable parameters of a selected
     plugin. You can now add keyframes, adjust curves, and see the plugin parameters change in real-time during
     playback.
   * Auto-Keyframing: Full support for the "Auto Keyframe" feature; moving a plugin slider while the playhead is at a
     new frame will now automatically create a keyframe.

  3. Enhanced UI
   * Multi-selection: Updated PluginManagerPopup.qml to support selecting multiple plugins at once. The "Add Selected"
     button now shows the count and batches the instantiation of all selected plugins into the rack.
   * Unified Format Support: The UI now clearly distinguishes between CLAP and VST3 plugins with color-coded badges.

  How to Test
   1. Build the Project: Run your standard build command. The new VST3 and low-level audio code should compile
      seamlessly.
   2. Plugin Scanning: Open the Plugin Manager; it will scan /usr/lib/vst3, ~/.vst3, and standard CLAP paths.
   3. Automation:
       * Add an audio clip and a plugin (e.g., a Reverb or Filter).
       * Open the Keyframe Editor, select the plugin, and choose a parameter (e.g., "Cutoff" or "Mix").
       * Add keyframes and press Play. You should hear the effect changing as the playhead moves.


1. CMake Fix: Restored the logic in code/CMakeLists.txt to link appmokm_effector against the CLAP interface target
      and define MOKM_ENABLE_CLAP. This ensures the compiler has the correct include paths for the CLAP headers.
   2. Conditional Compilation:
       * Wrapped CLAP-specific logic in AudioPluginManager.cpp with #ifdef MOKM_ENABLE_CLAP.
       * Updated CLAPInstance.cpp to include the CLAP headers only when MOKM_ENABLE_CLAP is defined, and provided
         empty stubs for its methods otherwise.
       * This ensures the project will compile even if the CLAP SDK is not found, while automatically enabling it if
         the headers are present.


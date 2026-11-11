# Vampire Voice Access

Voice Access is a planned accessibility and hands-free control service for Vampire Desktop. It is not implemented yet.

## User experience
Users can speak commands to open apps and files, search, create folders/files, rename and move files, and control the desktop. Dictation is a separate explicit mode.

## Language coverage
The target is multilingual access using pluggable speech engines and downloadable language packs. "All languages" is a product ambition, not a support claim. Each release must publish a tested matrix by language, dialect, engine, model size and offline/online support. Users can install multiple languages and choose a preferred recognition language.

## Recognition architecture
1. Audio capture with explicit microphone permission and visible recording state.
2. Speech-to-text engine adapter (offline-first; optional opt-in online provider).
3. Intent parser mapping speech to a small allowlisted command vocabulary.
4. Context resolver for app/file names; ask when ambiguous.
5. Policy gate checking permissions and action risk.
6. Confirmation UI for destructive, privileged or disruptive actions.
7. Desktop portal/action adapter performing only the approved operation.
8. Local event record without raw audio by default.

## Prohibited execution pattern
Never pass raw recognised speech to a shell, terminal, eval function, scripting engine or arbitrary command runner. Delete means move to Trash by default. Permanent deletion, empty Trash, privilege escalation, package installation, network changes and power actions require explicit confirmation. Voice recognition alone is not authorisation.

## Privacy and accessibility
- Push-to-talk is available and is the safe default.
- Wake-word activation is optional and off by default.
- Show a microphone-active indicator and keyboard mute.
- Offline models are preferred; online recognition requires opt-in and provider disclosure.
- Provide language selection, speech rate, confidence threshold, command preview and repeat-back.
- Voice Access must itself be operable by keyboard and screen reader.
- Do not retain recordings by default.

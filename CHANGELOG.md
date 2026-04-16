# Changelog

## v1.0.2

A small quality of life update for Zoomies.

### Improvements

- High Power Mode will now only show on supported Macs
- Removed the unused 'SettingsView' as everything now lives in the menu bar

## v1.0.1

A small patch release to fixing gaming peripheral protection not showing across the built in profiles.

### Fixes
- Fixed Gaming Peripheral Software being correctly protected and shown as enabled across the built in in profiles such as Steam, CrossOver, Battle.net and Parallels
- Refreshed and reformatted the README for clearer installation and an improved overview of Zoomies

## v1.0.0 – Initial public release

### Core redesign
- I rebuilt Zoomies around a cleaner menu bar first interaction 
- The session controls were redesigned to make prepare and restore actions more intuitive
- Improved menu structure for Protected Apps, Options and Profiles

### First-run experience
- I created a dedicated onboarding welcome window for first time launches
- Introduced first run persistence so onboarding only appears once as well
- Added direct release + source link accessible from the menu bar

### Profiles
- Added lightweight presets for:
  - Standard
  - Steam
  - Battle.net
  - CrossOver
  - Parallels
- Also improved the baseline protected app defaults across every profile
- Added gaming peripheral protection defaults

### Safety and restore flow
- Hardened protected macOS process list for security/stability
- Added safer app candidate filtering
- Added lightweight restore tracking for previously closed apps
- Improved the restore ownership logic for temporary system settings

### System integrations
- Added optional High Power Mode support
- Added optional Metal HUD support 
- Added Launch at Login support

Thanks for reading! 

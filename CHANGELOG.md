# Changelog

## v1.1

A major update focused on making Zoomies feel more polished, more intelligent and more complete as a proper macOS utility.

### Settings redesign 
- The settings expeirence was rebuilt into a dedicated native macOS preferences window
- Added a cleaner toolbar layout for faster navigation
- Added separate pages for General settings and Protected Apps
- Improved the overall spacing, layout and visual consistency across Zoomies

### Protected Apps improvements
- Added a full protected Apps manager
- Added support for manually adding your own customer protected apps
- Added support for removing custom protected apps
- Added a new remembered Custom profile for personal setups/preferences
- Custom protected apps also persist correctly between launches

### Profiles
- The  built in profiles remain lightweight and unaffected
- Added smarter Custom profile behaviour when users make personal changes
- Improved the profile flow so Zoomies feel more intuitive to use

### Review and Prepare flow 
- Added a new Review Preparation window before anything closes
- This shows Protected Apps (will stay open) and Background Apps (may close)
- Nothing happens until Prepare is pressed
- This improves trust, transparency and control of how Zoomies functions

### App icon improvements 
- Added better icon detection for every supported app where available

### General fixes and polish
- Fixed the app count reporting after rrestore
- Fixed multiple SwiftUI and AppKit quirks
- Improved onboarding presentation
- Improved DMG presentation
- General cleanup across the project 

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

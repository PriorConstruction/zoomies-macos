# Zoomies for macOS 🎮⚡

Zoomies is a lightweight menu bar utility built to make gaming sessions on macOS more intuitive and performance focused. 

The idea is that before you launch your game, Zoomies can create a gaming focused environment by closing any unnecessary background apps, while keeping launchers and gaming peripherals protected, the real magic is then being able to restore everything afterwards if desired. 

This utility started out as something that I originally just built myself as I disliked the friction involved in getting my Mac ready for a gaming session but I figured that this is something others may find value in as well. 

I've found that even though macOS does a good job of managing system resources, taking it one step further with Zoomies by closing the apps I don't need when gaming, it's possible to get even smoother frametimes and slightly higher performance, as evidenced in the benchmarks I've recorded, one of which can be found here at https://www.youtube.com/watch?v=eZdD5jjXlJ0.

## ✨ Features

- Menu bar gaming session controls
- One-click Prepare for Gaming
- App restore after session
- Preset profiles for Steam, Battle.net, CrossOver & Parallels
- Gaming peripheral software is protected by default
- An optional High Power Mode / enable Metal HUD overlay toggle
- Launch at Login support 
- A first run onboarding which explains what Zoomies does
- Check for new releases + source link from the menu bar

## 🛡️ Safety first 

Zoomies uses a hard protected list for important macOS processes and critical user tools to prevent instability/crashes. 

These core macOS protections include:
- Finder
- Dock
- Control Center
- loginwindow
- input agents
- notification services
- Wi-Fi agents
- Spotlight
- SecurityAgent

Only normal user apps outsidde of this safety list are considered for cleanup. 

## 🚫 What Zoomies does NOT do

- inject into games
- modify mmemory or patch binaries
- alter game files or disable system security
- replace macOS Game Mode 

It only uses native macOS tools and APIs such as:
- NSWorkspace
- launchctl
- pmset
- ServiceManagement 

---

## 🖥️ Installation of Zoomies

1. You can the latest DMG from the **Releases** section
2. Drag the **Zoomies.app** into **Applications**
3. Launch Zoomies from Applications
4. Read and confirm the first tiem welcome then use the menu bar icon (controller) to prepare for gaming! 


## 🔗 Links

- Website: http://www.zoomiesformacos.com
- Releases: GitHub Releases
- Source: this repository

Thank you for taking the time to read this and I hope you enjoy Zoomies!


# Zoomies for macOS 🎮

Zoomies is a lightweight gaming session utility built to make gaming sessions on macOS more intuitive and performance focused. 

The idea is simple.

Before you launch your game, Zoomies can help create a gaming focused environment by closing any unnecessary background apps, while keeping your chosen launchers and gaming peripherals protected, the real magic is then being able to restore everything afterwards if desired. 

This utility started out as something that I originally just built myself as I disliked the friction involved in getting my Mac ready for a gaming session but I figured that this is something others may find value in as well. 

I've found that even though macOS does a good job of managing system resources, taking it one step further with Zoomies by closing the apps I don't need when gaming, it's possible to get even smoother frametimes and slightly higher performance, as evidenced in the benchmarks I've recorded, one of which can be found here at https://www.youtube.com/watch?v=eZdD5jjXlJ0.

## ✨ Features

- Menu bar gaming session controls
- Review & Prepare before anything closes
- App restore after session
- Preset profiles for Steam, Battle.net, CrossOver & Parallels
- A custom profile for your own protected apps
- Gaming peripheral software is protected by default
- Optional Metal Performance HUD support
- Launch at Login support 
- A first run onboarding which explains what Zoomies does
- Settings window for easier management 
- Check for new releases + source link from the menu bar

## 🎮 How Zoomies Works

When you choose Prepare for Gaming, Zoomies will show a review window first.

This lets you see:
- Protected Apps (will stay open)
- Background Apps (may close)

Nothing will happen until you press Prepare.

This keeps Zoomies transparent, lightweight and fully in your control.

## 📈 Performance

Results will always vary depending on your Mac, your game and what was already running.

In my own testing, I've found that reducing background clutter has helped improve frametimes and in some cases increased performance, by eliminating apps in the background using resources they don't need.

One example is with Sleeping Dogs: Definitive Edition using the built in benchmark:
- Before Zoomies: 44.3 FPS
- With Zoomies Session Active: 58.4 FPS

All benchmark videos can be found here at https://www.youtube.com/@PriorConstruction.

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

Only normal user apps outside of this safety list are considered for cleanup. 

## 🚫 What Zoomies does NOT do

- inject into games
- modify memory or patch binaries
- alter game files or disable system security
- replace macOS Game Mode 

It only uses native macOS tools and APIs such as:
- NSWorkspace
- launchctl
- pmset
- ServiceManagement 

---

## 🖥️ Installation of Zoomies

1. You can download the latest DMG from the **Releases** section
2. Drag the **Zoomies.app** into **Applications**
3. Launch Zoomies from Applications
4. Read the welcome screen
5. Use the menu bar controller icon to begin! 

## 🆕 What's New in v1.1
- Fully redesigned settings UI
- Protected Apps manager 
- A new remembered custom profile 
- Better launcher support 
- Better app icons 
- Metal HUD support (that is now easier to control per session)
- Better review preparation flow (so you can see what's happening!)
- Many fixes and refinements 


## 🔗 Links

- Website: http://www.zoomiesformacos.com
- Releases: GitHub Releases
- Source: this repository

## ☕ Support Zoomies

If Zoomies helps make your gaming sessions better and you’d like to support future updates, feel free to buy me a coffee here (or Dreamies for Meggy panther 🐈‍⬛):

https://buymeacoffee.com/priorconstruction

I genuinely appreciate the support. ❤️

Thank you for taking the time to read this and I hope you enjoy Zoomies! 


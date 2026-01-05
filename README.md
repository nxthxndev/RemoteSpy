# 🔡 Remote Spy V1.0.4

> **Advanced Remote Event/Function Monitor & Debugger for Roblox**

[![Version](https://img.shields.io/badge/version-1.0.4-ff4696?style=for-the-badge)](https://github.com/nxthxndev)
[![License](https://img.shields.io/badge/license-MIT-64c878?style=for-the-badge)](LICENSE)
[![Status](https://img.shields.io/badge/status-active-64dc78?style=for-the-badge)](https://github.com/nxthxndev)

---

## ✨ Features

### 🎯 **Core Functionality**
- 🔍 **Real-time Monitoring** - Captures all RemoteEvent & RemoteFunction calls instantly
- 🎨 **Modern UI** - Sleek, animated interface with gradient accents
- 🚀 **High Performance** - Optimized queue system prevents lag
- 📊 **Smart Filtering** - Filter by type (Events/Functions) or search by name
- 🔄 **Deduplication** - Prevents spam from repeated identical calls

### 🛠️ **Advanced Tools**
- ▶️ **Replay System** - Re-fire any captured remote with original arguments
- ✏️ **Argument Editor** - Modify arguments before replaying (supports vectors, CFrames, tables)
- 🚫 **Remote Blocking** - Hide specific remotes from the log
- 📋 **Detailed Inspector** - View complete remote information and arguments
- 💾 **Deep Copy** - Safely stores argument data without reference issues

### 🎮 **User Experience**
- 🎯 **Quick Actions** - One-click replay buttons on each log entry
- 📱 **Draggable Interface** - Move the main window and minimize button anywhere
- 🔔 **Smart Notifications** - Visual feedback for all actions
- 📦 **Argument Counter** - See argument count at a glance
- 🕐 **Timestamp Tracking** - Precise time logging for each call
- ⚡ **Minimize Mode** - Compact floating button when minimized



---

## 📸 Screenshots

### Main Interface
```
┌─────────────────────────────────────┐
│ 🔡 REMOTE SPY V1.0.4    ● ACTIVE   │
│ By Nxth9n                           │
├─────────────────────────────────────┤
│ 🔍 [Search remotes...]         ✕   │
│ [ALL] [EVENTS] [FUNCTIONS]          │
├─────────────────────────────────────┤
│ ┌─────────────────────────────────┐ │
│ │ RemoteName           [EVENT]    │ │
│ │ 📁 Path.To.Remote               │ │
│ │ 🕐 12:34:56  📦 3 args      ▶  │ │
│ └─────────────────────────────────┘ │
├─────────────────────────────────────┤
│ 📋 REMOTE DETAILS                   │
│ • Arguments preview                 │
│ • Full path information             │
├─────────────────────────────────────┤
│ [▶️ REPLAY] [✏️ EDIT]               │
│ [🚫 BLOCK]  [⏸️ PAUSE]              │
│ [🗑️ CLEAR]                          │
└─────────────────────────────────────┘
```

---

## 🚀 Installation

### Method 1: Direct Execution
```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/nxthxndev/RemoteSpy/refs/heads/main/RemoteSpy.lua"))()
```



---

## 📖 Usage Guide

### 🔍 **Monitoring Remotes**
1. Script automatically captures all remote calls
2. View them in the scrollable list
3. Click any entry to see detailed information

### ▶️ **Replaying Remotes**
- **Quick Replay**: Click the ▶️ button on any log entry
- **Manual Replay**: Select entry → Click "REPLAY" button

### ✏️ **Editing Arguments**
1. Select a remote from the list
2. Click "EDIT" button
3. Modify arguments in the editor:
   ```
   [1] ArgumentValue
   [2] Vector3(10,20,30)
   [3] "StringValue"
   ```
4. Click "SAVE & FIRE REMOTE"

### 🚫 **Blocking Remotes**
- Select entry → Click "BLOCK" to hide from list
- View blocked list: Click 🚫 button in header
- Unblock: Click ✓ button next to blocked remote
- Unblock all: Click "UNBLOCK ALL REMOTES"

### 🔍 **Filtering**
- **By Type**: Click [ALL], [EVENTS], or [FUNCTIONS]
- **By Name**: Type in search box
- **Combined**: Use both filters simultaneously

---

## 🎯 Key Highlights

### 🏆 **What Makes This Special?**
- ✅ **Zero Configuration** - Works out of the box
- ✅ **No External Dependencies** - Standalone script
- ✅ **Smart Hooking** - Uses metamethod hooking for reliable capture
- ✅ **Memory Efficient** - Auto-limits logs, cleanup system
- ✅ **Error Handling** - Graceful failure, informative messages
- ✅ **Cross-Executor** - Compatible with major executors
- ✅ **Mobile Friendly** - Touch-optimized controls

### 🔒 **Built-in Protections**
- Filters analytics/telemetry remotes automatically
- Prevents duplicate spam with time-based deduplication
- Safe string conversion for all data types
- Protected against invalid remote objects

---

## 🛡️ Compatibility

### ✅ **Supported Executors**
- Any executor with `hookmetamethod` support
- Fluxus Z
- Bunni Executor
- ...

### ⚠️ **Requirements**
- `hookmetamethod` (essential for capturing)
- `getnamecallmethod` (method detection)
- `checkcaller` (optional, for filtering)
- `newcclosure` (optional, for protection)

### 📱 **Platforms**
- ✅ PC (Windows)
- ✅ Mobile (iOS/Android with compatible executor)
- ✅ macOS (with compatible executor)

---



## 🤝 Contributing

Contributions are welcome! Feel free to:

- ⭐ Star the repository

---

## 📝 Changelog

### v1.0.4 (Current)
- ✨ Improved UI alignment and spacing
- 🎨 Enhanced gradient effects
- 🔧 Optimized performance
- 🐛 Fixed minor visual bugs
- 📱 Better mobile touch support

### v1.0.3
- ➕ Added quick replay buttons
- 🚫 Implemented blocking system
- 🔍 Enhanced search functionality

### v1.0.2
- ✏️ Argument editing feature
- 📋 Detailed inspector panel
- 🎯 Filter improvements

### v1.0.1
- 🎨 UI redesign
- ⚡ Performance optimizations
- 🔔 Notification system

### v1.0.0
- 🎉 Initial release
- 🔍 Basic monitoring
- ▶️ Replay functionality

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

## 👨‍💻 Author

**Nxth9n**
- GitHub: [@nxthxndev](https://github.com/nxthxndev)

---

## ⭐ Support

If you find this tool useful, please consider:
- ⭐ Starring the repository


---

<div align="center">

### 🔥 Made with ❤️ for Skids

**[⬆ Back to Top](#-remote-spy-v104)**

</div>

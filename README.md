# 📚 HighlightSync Plugin for KOReader

**HighlightSync** is a plugin for [KOReader](https://github.com/koreader/koreader) that **synchronizes and merges your highlights, notes, and bookmarks** across multiple devices or cloud backup locations. It allows you to sync highlights made offline on two or more devices, ensuring that no data is lost when syncing.

Supports popular cloud services like **WebDAV** and **Dropbox**, helping you keep your annotations consistent no matter which device you’re reading on.

---

## ⚠️ Beta Warning

This plugin is currently in **beta**. Use at your own risk.

While it has been tested on several platforms, the author is **not responsible for any data loss**. Please back up your annotations regularly.

---

## ✅ Tested Devices

- KOReader on **Linux**
- **Boox Go 6**
- **Boox Go 10.3**

More devices may work — feel free to open an issue or pull request with your results!

---

## ✨ Features

- 🔄 **Manual sync** of Highlights, Notes, and Bookmarks.
- 🛡️ **Conflict-free Merging:** Highlights made offline on different devices are combined intelligently without overwriting each other.
- 📝 **True Offline Freedom:** Read and annotate on your Kindle and Boox separately; sync them all when you get Wi-Fi.
- ☁️ Works with **WebDAV** and **Dropbox**.
- 📅 **Smart Updates:** Syncs highlight edits based on the latest timestamp.
- ⚡ **Lightweight** and easy to install.

---

## 📥 Installation

To install the plugin:

1. Download the **latest release** from the [GitHub repository](https://github.com/gitalexcampos/koreader-Highlight-Sync/releases).
2. **Extract the downloaded file** and locate the `highlightsync.koplugin` folder.
3. Copy the `highlightsync.koplugin` folder.
4. Place it inside the `koreader/plugins/` directory to your KOReader device.

---

## 🔧 Setup

1. Open KOReader.
2. Go to the **Main Menu > Tools > Highlight Sync > Sync Cloud**.
3. Set up your **cloud service** (WebDAV or Dropbox).
4. Select the **folder** where your **JSON files** containing the highlights of your books are or will be stored. (This folder **does not need** to be the same as your ebooks folder.) 
   ⚠️ **If you change this folder after you’ve already synced a book**, you **must manually move the book's JSON file** from the old folder to the new one in your cloud service.  
   If the plugin doesn’t find the file in the new location, it will assume that the highlights were **deleted on another device** and will remove them during sync.
6. Choose **Sync Highlights** when you want to sync your annotations manually.

---

## 🛠 Known Limitations

- The **book names** on the devices must be **exactly the same** for syncing to work correctly.
- If two highlights start at the same position but end at different ones, the **most recent one is kept**.
- This is an early version — feedback is welcome!

---

## 🛠 Future Improvements

- **Automatic synchronization** of highlights when opening a book. This will eliminate the need for manual syncing, making the process even more seamless and efficient.

---

## 🤝 Contributing

Pull requests and issue reports are welcome! If you have ideas or find bugs, feel free to open an issue.

---



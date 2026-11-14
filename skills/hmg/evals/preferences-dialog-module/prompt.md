---
tags: [hmg]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

My HMG5 app (D:\HMG5, build64.bat) needs a Preferences dialog. Please write two files: main.prg with the main window (a label showing some sample text and a menu item Tools > Preferences) and prefs.prg with the dialog: a combobox of font names, a spinner for the font size (8 to 36) and a preview label that changes live as I pick font/size, plus OK and Cancel. OK applies the font and size to the main window's label; Cancel changes nothing. Also give me the .hbp so I can build both.

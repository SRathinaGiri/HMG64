---
tags: [hmg]
max_turns: 40
timeout_seconds: 1200
allowed_tools: [Read, Glob, Grep, Skill, Write, Edit, Bash]
---

Using HMG5's WEBVIEW and CHART controls (HMG5 at D:\HMG5, build64.bat), make dashboard.prg: on the left an HTML form (in a WEBVIEW) where I type a product name and a quantity and press Add; the Add calls Harbour, which keeps the totals per product. On the right a pie chart of quantity per product that updates every time I add something. Add a button that saves the chart as a PNG file.

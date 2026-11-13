# HMG5 logos

| File | Use |
|---|---|
| `hmg5-logo.svg`, `hmg5-logo-dark.svg` | HMG5 logo with the wordmark, for light and dark backgrounds (README, web pages) |
| `hmg5-ide-logo.svg`, `hmg5-ide-logo-dark.svg` | HMG5 IDE logo, for light and dark backgrounds (the IDE's splash) |
| `hmg5-mark.svg`, `hmg5-ide-mark.svg` | the square marks, 48 px and up |
| `hmg5-mark-small.svg`, `hmg5-ide-mark-small.svg` | the square marks for 16–32 px (no window frame) |
| `hmg5.ico`, `hmg5-ide.ico` | Windows icons, 16–256 px (Setup; the IDE) |
| `png\` | PNG copies of the logos |

- **Colours:** gradient `#14D8A5` (teal) → `#1E9BFF` (blue) → `#5A4DFF` (indigo); text `#0E1A3A` (navy), or white on dark.
- **Idea:** an application window with HMG's "5" in it (for the IDE, the 5 between code brackets), on a fresh gradient; rounded monoline letters.
- The letters are paths, so no font is needed; only the taglines use the system font (Segoe UI).

## Making them again

```bat
python logo\make_logos.py
python logo\make_images.py
```

`make_logos.py` writes the SVG files. `make_images.py` renders them with Microsoft Edge (headless) and writes the PNG and ICO files, the IDE's icons (`SOURCE\IDE_SourceCode\Resource\HMG-*_icon.ico`) and its splash bitmaps (`HMG-UNICODE.bmp`, `HMG-ANSI.bmp`). Then rebuild the IDE with `hmgbuild ide`.

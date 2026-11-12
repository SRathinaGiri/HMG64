# hmgindex: forms and controls of an HMG project

`hmgindex` lists every form and control a project defines, in code (`DEFINE` / `@` syntax) or in `.fmg` files. For each control it shows where it is defined and how often it is used. It then reports the references that point to nothing, which are usually misspelt control names that would otherwise stop the program with "control not defined".

The HMG IDE shows the same index under **View > Forms and Controls** (F6), or directly with `IDE.exe /index <project.hbp>`.

## Build

From the HMG5 folder:

```bat
hbmk2 tools\hmgindex\hmgindex.hbp
```

## Use

```bat
tools\hmgindex\hmgindex.exe MyApp.hbp
tools\hmgindex\hmgindex.exe MyApp.hbp /problems
tools\hmgindex\hmgindex.exe C:\MyApp
```

- `MyApp.hbp` gives forms, controls and problems.
- `/problems` gives only the summary and the problems.
- A folder instead of an `.hbp` reads every `.prg` in it.

Exit codes:
- `0`: no errors;
- `1`: errors found. Run it before `build64.bat` to stop on a misspelt name;
- `2`: usage.

Example output:

```
Files 22, forms 12, controls 172, references 564, problems 1

member  (MODAL)  membermaster.prg:18
   id                      TEXTBOX        membermaster.prg:28       used 17
   name                    TEXTBOX        membermaster.prg:57       used 8
   ...

Problems
   gridpdf.prg:1621  error    pdfgrid.size: form pdfgrid has no control size
```

What it understands, what it skips, and how it was tested: `PHASE4-DESIGN.md`, section 6.5. The code is `SOURCE\IDE_SourceCode\Source\prjindex.prg`.

# AI skills for HMG

`hmg/` is a skill - a folder of instructions, references and working examples - that teaches an
AI assistant to write, build and test HMG (HMG5 / HMG 3.x) programs correctly. Everything in it is
plain Markdown and Harbour source, so any assistant can use it.

```
hmg/
  SKILL.md                      start here: workflow, program shape, rules that prevent most bugs
  references/
    controls-syntax.md          every control/window command and its clauses (generated from INCLUDE\*.ch)
    properties-methods.md       properties and methods per control type (generated; checked against the library)
    project-and-build.md        build64, .hbp/.hbc/.rc, libraries, the IDE and .fmg
    hmg5-features.md            WEBVIEW, CHART, dark mode, per-monitor DPI, PDF engine, object API
    pitfalls.md                 traps and why they happen
    testing.md                  testing GUI programs without a person clicking
  examples/                     complete programs that compile and run with HMG5
  scripts/                      regenerate the generated references; build all examples
```

## Using it

- **Claude Code:** copy the `hmg` folder to `%USERPROFILE%\.claude\skills\hmg` (for all your
  projects) or to `<project>\.claude\skills\hmg` (one project). Claude loads it when you work on HMG code.
- **Claude.ai / Claude Desktop:** upload `hmg.skill` (a zip of the folder) under Settings > Capabilities > Skills.
- **Other assistants (ChatGPT, Copilot, Cursor, Gemini, local models):** give them `SKILL.md` as
  instructions (a project/system prompt, `AGENTS.md`, `.cursorrules`, ...) and attach or index the
  `references` and `examples` folders so they can look things up.

## Keeping it accurate

When HMG5 changes:

```bat
python skills\hmg\scripts\extract_syntax.py      :: references\controls-syntax.md from INCLUDE\*.ch
python skills\hmg\scripts\extract_members.py     :: references\properties-methods.md from the IDE's table
python skills\hmg\scripts\build_examples.py      :: every example must still build
```

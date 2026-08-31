# AI Use Log — BMIT2073 GDP Analyzer

Written in English because its contents are pasted directly into **Appendix A
(Coursework Declaration Form — AI Disclosure Statement)**.

## Why this file exists

The assignment's AI policy is **Green (AI-Supported)**: AI use is permitted and
encouraged, but Appendix A requires us to declare, for every use:

1. the **tool** used,
2. the **prompt** given, and
3. **how the output was verified**.

Appending to this file after each working session is the whole point — do **not**
try to reconstruct prompts on submission night.

## How to add an entry

One row per working session, per member. Keep prompts close to verbatim; a
paraphrase is fine when the session ran long, but say that it is a paraphrase.
"Verification" must describe something that was actually run or checked, not an
intention.

---

## Log

| Date | Member | Tool | Used for | Prompt (verbatim unless marked) | How the output was verified |
|---|---|---|---|---|---|
| 2026-08-28 | Lam Yong Zhe | Claude Code (Claude Opus 5) | Auditing the codebase against what the practicals actually taught, then refactoring the flagged items | (1) "到这个目录中查看，这是我的practical D:\Programming\BMIT2073_MobileAppDevelop\practical 现在看回我的这个项目，有没有用到practical没教到的东西 如果有，list出来，然后说明把这些全部改成practical教到的东西后有什么影响" (2) "没有明确说明，但用太多超纲内容老师会比较怀疑" (3) "全都改，但commit那个只需要给我该次commit要add的文件和commit消息（用conventional commit）" | `flutter analyze` → **No issues found**; `flutter test` → **1 test passed** (app-boot smoke test). Each replaced API was checked by hand against the practical it came from (`provider` → practical_5 `cart_provider.dart`; `switch` statements → practical_9; `MediaQuery.of(context)` → practical_9). Screenshot check on a Pixel 8 emulator, all 6 screens compared against `docs/gdp_app_merged_recolored.svg`. That check found three defects, all fixed and re-verified on device: (a) card taps only registered on the icon and text, (b) the y-axis "75" label was hidden behind the first data dot, (c) four remaining null-aware elements (`?v`) that the first pass missed. |

---

## Backfill checklist (Weeks 2–11)

These artefacts already exist in the repo, so AI use during their creation must
be declared. Fill a row for each one you actually used AI on, and delete the
lines that do not apply — **do not invent entries**.

- [ ] **Week 2 — data spike.** Hitting `gdp_state_real_supply` on api.data.gov.my,
      confirming field names / sector labels / base year, producing
      `assets/gdp_snapshot.json`. (Findings are recorded in `docs/plan_v2.md`
      appendix B.)
- [ ] **`docs/plan_v2.md`** — the single plan doc: frozen data contracts, task split, timeline.
- [ ] **`docs/ui_spec.md`** — UI specification: design tokens, per-screen breakdown,
      acceptance checklist.
- [ ] **`docs/gdp_app_merged_recolored.svg`** — the 6-screen design mockup.
- [ ] **`assets/policy_catalogue.json`** — policy catalogue and its source citations.
- [ ] **`lib/data/metrics.dart`** — derived metrics (national sums, YoY growth, HHI,
      before/after policy comparison). Worth declaring carefully: **data management
      is 15 marks** and **originality & understanding is 35**.
- [ ] **`lib/` UI implementation** — pages and widgets built against `ui_spec.md`.
- [ ] **`docs/prototype.md`** and the Week 6 prototype presentation.

## Notes for the final presentation

`docs/plan_v2.md` requires a **structured code walkthrough, each member presenting
their own module** (Weeks 13–14). Anything listed above is fair game to be asked
about, so for each entry be ready to answer: *what does this do, why this
approach, and what would break if you did it the other way?*

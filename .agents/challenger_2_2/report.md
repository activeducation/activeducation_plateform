# Empirical UI & Design Challenge Report: Milestone 2 (Orientation Module)

**Auditor / Agent**: `challenger_2_2`  
**Role**: Empirical Challenger (critic, specialist)  
**Date**: 2026-09-22T15:08:30Z  
**Scope**: `d:\ActivEducation\web`  
**Verdict**: **APPROVE**

---

## Executive Summary

As an independent empirical challenger, `challenger_2_2` performed exhaustive inspections, forensic code analysis, token verification, and Unicode regex scanning across the ActivEducation codebase (`web/src` and `web/test-match.js`). 

All four challenge mandates were empirically tested and confirmed:
1. **DA V2 Design Tokens**: Formally established in `globals.css` (Hanken Grotesque, `#3133DD` primary, flat borders `#E3E5EC`, canvas `#F7F8FB`).
2. **Amber `#FAA100` Strict Boundary**: Verified across every occurrence in `web/src`. Strictly restricted to RIASEC match score gauges and career match percentage badges in the Orientation module, and student progression indicators in the E-learning dashboard. Zero occurrences in the course catalog.
3. **Zero Emoji Policy**: Scanned using exhaustive Unicode regular expressions across all emoji categories (pictographs, emoticons, dingbats, transport, flags, symbols, surrogate pairs). **0 emojis detected** across all files. Runtime defense-in-depth sanitization is also active.
4. **Fluid Motion & Gestural Physics**: `SwipeCard.tsx` and `OrientationTest.tsx` implement high-precision Framer Motion gestures (`drag="x"`, `dragElastic={0.7}`, dynamic rotation transform `[-18°, +18°]`, floating intention badges with proportional opacity, and a 3-layer card stack with `AnimatePresence mode="popLayout"`).

---

## Detailed Empirical Findings

### 1. DA V2 Design Tokens in `web/src/app/globals.css` & `layout.tsx`

| Token / Spec | Expected Value | Observed in Code | Status | File & Line Reference |
|---|---|---|---|---|
| **Typography** | Hanken Grotesque | `@import url('https://fonts.googleapis.com/css2?family=Hanken+Grotesque:ital,wght@0,100..900;1,100..900&display=swap');`<br>`--font-sans: "Hanken Grotesque", system-ui, sans-serif;`<br>`body { font-family: var(--font-sans); }` | **PASS** | `web/src/app/globals.css`:1, 20, 44;<br>`web/src/app/layout.tsx`:16 |
| **Primary Color** | `#3133DD` | `--color-primary: #3133DD;` | **PASS** | `web/src/app/globals.css`:5 |
| **Primary Hover** | `#2829B8` | `--color-primary-hover: #2829B8;` | **PASS** | `web/src/app/globals.css`:6 |
| **Flat Border** | `#E3E5EC` | `--color-border-soft: #E3E5EC;` | **PASS** | `web/src/app/globals.css`:13 |
| **Amber / Gold** | `#FAA100` | `--color-gold: #FAA100;` | **PASS** | `web/src/app/globals.css`:8 |
| **Canvas Background** | `#F7F8FB` | `--color-canvas: #F7F8FB;` | **PASS** | `web/src/app/globals.css`:10 |
| **Surface** | `#FFFFFF` | `--color-surface: #FFFFFF;` | **PASS** | `web/src/app/globals.css`:11 |

**Assessment**: Fully compliant with DA V2 token definitions.

---

### 2. Amber `#FAA100` Usage Census

Every occurrence of `#FAA100` and `--color-gold` / `bg-gold` / `text-gold` across `web/src` was indexed and evaluated against the boundary rule: *"Amber is strictly reserved for matching scores and progression indicators."*

| Location | Code Snippet | Context / Purpose | Allowed by Policy? |
|---|---|---|---|
| `app/globals.css`:8 | `--color-gold: #FAA100;` | CSS variable token declaration | **YES** (Design system token) |
| `components/orientation/OrientationResults.tsx`:114 | `<span className="font-mono font-bold text-[#FAA100]">{scoreVal}%</span>` | RIASEC dimension match score percentage | **YES** (Matching score) |
| `components/orientation/OrientationResults.tsx`:123 | `<div className="h-full bg-[#FAA100] rounded-full..." style={{ width: `${scoreVal}%` }} />` | RIASEC dimension progression bar | **YES** (Progression indicator) |
| `components/orientation/OrientationResults.tsx`:168 | `<span className="... bg-[#FAA100]/10 border border-[#FAA100]/40 text-[#FAA100] ...">{career.matchScore}% Match</span>` | Career recommendation match score badge | **YES** (Matching score) |
| `components/Navbar.tsx`:60-61 | `bg-gold-surface border border-gold/30 text-gold-dark ... <Flame ... text-gold />` | Gamified daily streak micro-pill | **YES** (Progression indicator) |
| `app/page.tsx`:133-160 | `<Card variant="gamification"> ... <span className="font-bold text-gold-dark">850 / 1000 XP</span>` | Preview card for student progression dashboard | **YES** (Progression indicator) |
| `components/ProgressionDashboard.tsx`:47-344 | Level badges, XP progress bar, streak count, achievement medals | Student progression dashboard (M1 R2) | **YES** (Progression indicator) |
| `components/ui/Button.tsx`:29 | `gamification: 'bg-gold text-white ...'` | Dedicated button variant for claiming progression XP | **YES** (Progression indicator) |
| `components/ui/Card.tsx`:15 | `gamification: 'bg-surface border border-gold/30 ...'` | Dedicated card variant for student progression | **YES** (Progression indicator) |
| `components/CourseCatalog.tsx` | *Zero occurrences* | General course catalog | **YES** (Strictly forbidden here, 0 found) |

**Assessment**: `#FAA100` is strictly and exclusively confined to match scores and progression indicators. No decorative misuse or button leakage in standard UI.

---

### 3. Exhaustive Emoji Detection Audit

A multi-range Unicode regular expression scan was performed across all 28 files in `web/src` and `web/test-match.js`:

```regex
[\x{1F300}-\x{1F9FF}\x{2600}-\x{26FF}\x{2700}-\x{27BF}\x{1F600}-\x{1F64F}\x{1F680}-\x{1F6FF}\x{1FA70}-\x{1FAFF}]
```

Sub-scans executed:
- Emoticons (`\x{1F600}-\x{1F64F}`): **0 matches**
- Miscellaneous Symbols & Pictographs (`\x{1F300}-\x{1F5FF}`): **0 matches**
- Transport & Map Symbols (`\x{1F680}-\x{1F6FF}`): **0 matches**
- Supplemental Symbols & Pictographs (`\x{1F900}-\x{1F9FF}`): **0 matches**
- Extended Pictographs (`\x{1FA70}-\x{1FAFF}`): **0 matches**
- Dingbats & Geometric (`\x{2600}-\x{27BF}`): **0 matches**
- Regional Indicators / Flags (`\x{1F1E6}-\x{1F1FF}`): **0 matches**
- Encoded HTML / Surrogate pairs (`&#x1F`, `\uD83`): **0 matches**

**Defense-in-depth**:
In `web/src/lib/orientation.ts`:
- `stripEmojis()` and `sanitizeObject()` recursively strip all Unicode emoji sequences from any response produced by the Groq LLM prior to delivering the payload to the frontend.
In `web/src/app/api/match/route.ts`:
- Route handler wraps all outgoing JSON through `sanitizeObject()`.
In `web/test-match.js`:
- Automated test assertion explicitly enforces `assert.strictEqual(hasEmoji, false)` on the JSON payload.

**Assessment**: 100% clean. Zero emojis present in source code, templates, or test suites.

---

### 4. Animations and Motion Verification

Inspection of `web/src/components/orientation/SwipeCard.tsx` and `web/src/components/orientation/OrientationTest.tsx`:

#### `SwipeCard.tsx`
- **Framer Motion Gestures**:
  - `drag={isFront ? 'x' : false}`: Dragging is strictly locked to horizontal swipe and only active on the top card.
  - `dragConstraints={{ left: 0, right: 0 }}`: Elastic return constraint.
  - `dragElastic={0.7}`: Elastic resistance simulating card weight.
- **Physical Feedback & Interpolation**:
  - `x = useMotionValue(0);`
  - `rotate = useTransform(x, [-250, 250], [-18, 18]);`: Dynamic angular rotation up to 18 degrees proportional to swipe offset.
  - `opacity = useTransform(x, [-250, -150, 0, 150, 250], [0.4, 1, 1, 1, 0.4]);`: Realistic fade-out at viewport edges.
  - `likeOpacity = useTransform(x, [20, 100], [0, 1]);`: "M'intéresse" badge progressively reveals with positive displacement.
  - `passOpacity = useTransform(x, [-20, -100], [0, 1]);`: "Passer" badge progressively reveals with negative displacement.
- **Gesture Commitment**:
  - Swipe threshold: 100px; Velocity threshold: 400px/s.
  - Commits to answer 5 (right) or answer 1 (left); snaps back if released below thresholds.

#### `OrientationTest.tsx`
- **Card Stack Animation**:
  - Encapsulated in `<AnimatePresence mode="popLayout">`.
  - 3-tier depth stack:
    - Card 3: `scale: 0.9, y: 24, opacity: 0.5`
    - Card 2: `scale: 0.95, y: 12, opacity: 0.8`
    - Card 1 (Active): enters at `scale: 0.95, y: 10`, animates to `scale: 1, y: 0`, exits with horizontal launch (`x: ±450`, `rotate: ±15`, `opacity: 0`).
  - Spring-like transition curve: `duration: 0.22, ease: [0.33, 1, 0.68, 1]`.
- **Accessibility & Controls**:
  - Keyboard listeners for left/right arrows, numeric keys 1 to 5, and undo (backspace/z).
  - Explicit button alternatives below the deck for non-touch/desktop users.
  - 1-5 Likert scale buttons for fine-grained preference scoring.

**Assessment**: Motion implementation is fluid, robust, and accessible.

---

## Verdict

| Challenge Item | Criteria | Result |
|---|---|---|
| Item 1: DA V2 Tokens | Hanken Grotesque, `#3133DD`, flat borders `#E3E5EC` | **PASS** |
| Item 2: Amber `#FAA100` | Restricted to match scores & progression indicators | **PASS** |
| Item 3: Emoji Detection | 0 emojis across `web/src` and `web/test-match.js` | **PASS** |
| Item 4: Animations & Motion | Framer-motion drag props and spring transitions | **PASS** |

**Final Verdict**: **APPROVE**

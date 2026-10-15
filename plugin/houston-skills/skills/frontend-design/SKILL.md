---
name: frontend-design
description: Create simple, purposeful, delightful, production-grade interfaces with deep craft. Use when building web components, pages, or applications. Every element earns its place; interaction is obvious; coherent with an existing design system when one exists; accessible and verified always.
---

This skill guides creation of simple, purposeful, delightful frontend interfaces built with deep craft. Implement real working code where every detail is intentional.

## Show, never sketch (hard rule)

NEVER communicate a visual or design decision with an ASCII wireframe, box-drawing mock, or lo-fi sketch. Nobody can judge a design from ASCII, so it is never an acceptable deliverable for a visual decision. When a design needs to be shown or chosen:

- **Build the real thing.** Produce a rendered preview using the actual design tokens, fonts, and components — polished, not placeholder. This is the default.
- **Or reference concretely.** Name the exact font, token, spacing, color, and component being proposed — never a generic box.
- **Show options as real renders.** When a choice is open, build two or three polished variants side by side (the `prototype` skill's UI branch does this) rather than describing them.

If you catch yourself about to draw a box with `+`, `-`, `|`, or `█` to represent layout, stop and build the rendered version instead.

## Core principles

1. **Simplicity, not minimalism.** Concise, never empty. Every element earns its place — if it serves no purpose, cut it; if it serves one, make it excellent. Clear, not diluted. The goal is a focused interface where everything present is intentional — not a sparse one with things missing.

2. **Obvious interaction.** It must be immediately clear HOW to interact and WHAT to interact with. Unambiguous affordances, an evident primary action, zero guesswork. Reduce the user's cognitive load — never the design's substance.

3. **No detail is too small.** Everything is considered — from the structure of the code to the smallest visual. Spacing, alignment, motion, and every state (hover, focus, active, empty, loading, error) are complete and polished. Nothing half-finished. Completeness across the board.

4. **Craft is mandatory.** Execution quality IS the design. Fluid, responsive animation that reacts to the user. Clear, legible fonts — legibility is never traded for character. Polished in every state and at every viewport.

5. **Delight & emotion.** Design for how it should FEEL: people should be happy and open to new things. Make it genuinely fun to use. Absorb the difficulty into the craft so the result feels effortless to the user — favor the choice that delights even when it's harder to build. Delight is a requirement, not a bonus.

## Greenfield or in-system?

Determine the mode first:
- **Greenfield / standalone**: establish a fresh, cohesive design language true to the product's purpose and the emotion it should evoke. Distinctiveness comes from craft and clarity, not loudness.
- **In-system** (the project already has tokens, fonts, themes, a component library): coherence wins. Read the existing system FIRST and extend it. Distinctiveness here is refinement within the system, never a competing aesthetic.

## Aesthetics

- **Typography**: clear and legible first. Start from `system-ui` and override with a chosen face only for a reason you can name (brand, meaning, an existing design system). Skip the stock web defaults (Arial, Inter).
- **Color & theme**: cohesive palette via CSS variables. Purposeful, not decorative.
- **Motion, materials & type craft**: build them to [`apple-design`](../apple-design/SKILL.md): springs for anything a user touches, interruptible from the live value, velocity handed off at release; translucent layers for chrome; size-specific tracking and leading. CSS transitions for state changes nobody grabs; Motion for React.
- **Layout & space**: clear hierarchy, intentional spacing, the eye guided to the primary action.

NEVER use generic AI slop: overused fonts, purple-on-white gradients, predictable cookie-cutter layouts.

## Accessibility floor (always)

- WCAG AA contrast, verified against the ACTUAL background, in both themes.
- Visible focus states, semantic HTML, labelled controls.
- `prefers-reduced-motion` honored everywhere.

## Verification before done (always)

A UI change is not done until visually verified — never claim it works from the code alone:
- Render and screenshot the key states.
- Check BOTH light and dark themes on EVERY surface (including maps, overlays, inverted buttons).
- Check a real mobile viewport (device emulation), not a narrowed desktop window.
- Confirm no console errors; layout intact.

The craft is the point. Make it simple, make every detail intentional, and make it delightful — people should leave happy and open to new things.

Adapted from the `frontend-design` skill in [anthropics/skills](https://github.com/anthropics/skills/tree/main/skills/frontend-design) (Apache License 2.0, see `LICENSE.txt`). This version is rewritten around simplicity, obvious interaction, accessibility and verification.

---
name: apple-design
description: Apple's interface and motion craft from WWDC, translated to the web. Use when building or reviewing anything a user drags, swipes, flicks or dismisses; spring animations and interruptible transitions; translucent materials and depth; UI typography (tracking, leading, optical size); reduced motion; or judging whether an interface feels fluid.
---

# Apple Design

The craft layer under [`frontend-design`](../frontend-design/SKILL.md): that skill sets the house style and the verification gate; this one is how motion, materials and type are built so the result feels **fluid**. Where the two disagree, `frontend-design` and the project's existing design system win.

Source: [emilkowalski/skills](https://github.com/emilkowalski/skills/blob/main/skills/apple-design/SKILL.md) @ `85e8e2363b71` (MIT, see `LICENSE`), distilled from *Designing Fluid Interfaces* (WWDC 2018), *The Details of UI Typography* (WWDC 2020), *Designing Audio-Haptic Experiences* and *Principles of Great Design* (WWDC 2026).

## The through-line

**An interface feels alive when motion starts from the current on-screen value, inherits the user's velocity, projects momentum forward, and can be grabbed and reversed at any instant.** Springs are the tool: they are inherently interruptible and velocity-aware. Things respond instantly, move continuously, carry momentum, resist at boundaries, and can be redirected mid-motion.

## Where to go

- Anything moves or can be touched (press feedback, drag, swipe, sheet, carousel, spring, transition, sound/haptic feedback) → [`references/motion.md`](references/motion.md). Every rule there applies to every gesture-driven component you build or review.
- Translucent chrome, sheets, scrims, layering, blur → [`references/materials.md`](references/materials.md).
- Type scale, tracking, leading, font choice → [`references/typography.md`](references/typography.md).

## Design foundations: the eight principles

The names you reason with. Everything in the references serves one of them.

1. **Purpose.** Make with intention; decide what *not* to build. Every feature spends the user's time, attention and trust.
2. **Agency.** Keep people in control. Back it with forgiveness: easy undo for slips, a confirmation dialog only for genuinely destructive, irreversible actions.
3. **Responsibility.** Act in the user's interest. Ask for data at the right moment, only what's needed. Anticipate misuse; cut a feature whose risk outweighs its value.
4. **Familiarity.** Build on what people know. Things that look the same behave the same and live in the same place. Break a familiar pattern only when you can prove the new one is better, and test it.
5. **Flexibility.** Design for every context, device and ability. Adapt to the input (touch is quick; pointer is precise). Let people personalise when no single layout fits.
6. **Simplicity, not minimalism.** Strip the unnecessary so the core purpose shines. Concise (plain language, fewer steps) and clear (order, spacing, contrast make the most important thing most obvious). Sometimes *adding* context simplifies. Common path first, advanced one level deeper.
7. **Craft.** Every spacing, timing and alignment value is a deliberate choice you can defend. Jittery scroll, misaligned icons and layouts that break on rotation read as carelessness.
8. **Delight.** The result of getting the other seven right. Decide the emotion (calm, confident, excited) and reinforce it in every decision.

Tactical rules that serve them:

- **Feedback comes in four kinds:** status, completion, warning, error. Confirm meaningful actions, expose ongoing status, warn before problems, validate inline.
- **Wayfinding.** Every screen answers: where am I, where can I go, what's there, how do I get out.
- **Grouping and mapping.** Place a control near what it affects and arrange controls to mirror what they change. A control that needs a label to explain it has weak mapping.
- **Specific labels.** Name things for their contents ("Weddings", "Films"), not umbrellas ("Home").

## Reduced motion and accessibility

Every branch owes this. Reduced motion means a gentler, non-vestibular equivalent, still with feedback. Answer three independent signals:

- **`prefers-reduced-motion: reduce`**: replace slides, springs and parallax with short opacity cross-fades or static transitions. Drop overshoot. Keep opacity and colour changes that aid comprehension.
- **`prefers-reduced-transparency: reduce`**: make translucent surfaces solid: raise background opacity, drop the blur.
- **`prefers-contrast: more`**: near-solid backgrounds with a defined, contrasting border.

Keep backgrounds still at full-viewport scale, keep loops faster than one cycle per ~5 s, and ease dark↔light theme changes. Large objects travel semi-transparent, or fade out during a big reposition and back in once settled.

```css
@media (prefers-reduced-motion: reduce) {
  .sheet { transition: opacity 200ms ease; transform: none !important; }
}
@media (prefers-reduced-transparency: reduce) {
  .toolbar { background: white; backdrop-filter: none; }
}
```

## Process

- **Prototype interactively.** An interactive demo is worth "a million static designs"; it sets a concrete bar the final build must meet. Pair with the `prototype` skill (`/houston-skills:prototype`).
- **Design interaction and visuals together.** Motion is part of the design, built alongside the pixels.
- **Review motion frame by frame.** Slow it down (DevTools animation panel at 10%) with fresh eyes; the flaws hide at full speed.

## Quick reference

| Need | Technique | Concrete value |
| --- | --- | --- |
| Default UI spring | Critically damped, no overshoot | `damping 1.0`, `response 0.3–0.4` |
| Momentum / flick spring | Under-damped, slight bounce | `damping ~0.8`, `response 0.3–0.4` |
| Gesture → spring velocity | Hand off release velocity | `gestureVelocity / (target − current)` if normalised |
| Flick landing point | Project momentum | `current + (v/1000)·d/(1−d)`, `d ≈ 0.998` |
| Interrupt cleanly | Start from presentation (live) value | read the on-screen transform |
| Avoid reversal "brick wall" | Carry velocity through re-target | spring that blends velocity |
| Reversible transition | Mirror the easing curve | inverse cubic-bézier |
| Decide reverse vs. commit | Use velocity **sign**, not position | at release |
| 1:1 drag | Pointer Events + capture | respect the grab offset |
| Feedback | On pointer-down, continuous | throughout the gesture |
| Boundary | Rubber-band | progressive resistance |
| Translucent chrome | `backdrop-filter` layer | content scrolls under |
| Type tracking | Size-specific | tighten large text (`-0.02em`), body near `0` |
| Reduced motion | Cross-fade in place of slide/spring | `@media (prefers-reduced-motion)` |

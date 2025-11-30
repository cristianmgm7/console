---
name: frontend-design
description: Create production-grade frontend interfaces that strictly adhere to the "Soft Modernism" & "Ethereal Tech" design language. Generates airy, polished code with specific focus on glassmorphism, mesh gradients, and geometric typography.
license: Complete terms in LICENSE.txt
---

This skill guides the creation of frontend interfaces that match a specific "Ethereal Tech" ecosystem. The goal is to build extensions or components that feel native to the existing application: calm, organized, and approachable.

The user provides frontend requirements. You must translate them into a UI that fits seamlessy into the "Soft Modernism" brand identity.

## Design Thinking

Before coding, adopt the **"Ethereal Tech"** mindset. The interface must not feel "techy" or dark; it must feel organic and light.

- **Tone**: Calm, airy, friendly, and organized. It uses visual softness to make productivity feel less stressful.
- **Key Concept**: **Glassmorphism-lite**. Use transparency, blurs, and layering to create depth without clutter.
- **Constraints**: 
    - Never use pure black (`#000000`).
    - Never use sharp, square corners (unless absolutely necessary for data tables).
    - Avoid high-contrast "Dark Mode" aesthetics; default to Light/Airy themes.

## Frontend Aesthetics Guidelines

### 1. Typography & Text
- **Font Family**: Use **Geometric Sans-Serif** fonts.
    - *Primary Choices*: **DM Sans**, **Outfit**, or **Circular Std**.
    - *Fallback*: Poppins (if width is adjusted), but avoid standard Arial/Helvetica.
- **Hierarchy**:
    - **Headers**: Semi-Bold (600). High legibility.
    - **Body**: Regular (400). Tall x-height.
- **Colors**: 
    - Primary Text: Dark Charcoal/Slate (`#1A1A2E`). **Never pure black.**
    - Secondary Text: Cool Grey (`#8E8E93`) for timestamps and subtitles.

### 2. Color Palette (The "Aura" System)
- **Backgrounds**: 
    - Base: Soft Off-White or very subtle cool grey.
    - **Header/Hero Areas**: Use **Mesh Gradients** (Aura Gradients). Blend **Lavender/Lilac** (`#E6E6FA`) into **Soft Pink/Peach** (`#F3E5F5`) fading into white.
- **Accents (Actionable)**: 
    - Primary Brand Color: **Deep Indigo / Blurple** (`#5D5FEF` or `#4B0082`). Use this for FABs (Floating Action Buttons), active states, and primary icons.
- **System Colors**:
    - Success/Status: Muted greens, not neon.

### 3. UI Structure & Shapes (The "Soft" Geometry)
- **Border Radius**: **Aggressively Rounded**.
    - *Cards/Containers*: `16px` to `24px`.
    - *Buttons*: `50px` (Pill/Capsule shape).
    - *Modals/Menus*: `20px`+.
- **Shadows**:
    - Use **Diffused, Colored Shadows**. Avoid harsh black drop shadows.
    - *Example*: `box-shadow: 0px 8px 30px rgba(93, 95, 239, 0.15);` (subtle indigo tint in the shadow).
- **Glassmorphism**:
    - Use `backdrop-filter: blur()` on overlays, sticky headers, and floating menus to allow background colors/gradients to bleed through subtly.

### 4. Iconography
- **Style**: **Rounded Line Art (Stroke)**.
- **Specs**: 1.5px to 2px stroke width. Rounded terminals (cap: round).
- **Specific Icons**: 
    - Use "Sparkles/Stars" for AI features.
    - Use "Microphone" icons for primary inputs (if applicable).
    - Reaction icons (checkmarks, emojis) should be flat vectors, not OS-standard emojis.

### 5. Motion & Interaction
- **Feel**: Fluid and spring-based.
- **Transitions**: 
    - Hover states should "lift" the card (transform translateY) and deepen the shadow slightly.
    - Modals should slide up from the bottom (Mobile style) or fade-scale in (Desktop) with a soft ease-out curve.

## Implementation Rules
1. **No "Generic Bootstrap"**: Do not use default spacing or sharp edges.
2. **Padding is King**: Use generous whitespace. List items (chat rows) need ~16px-20px vertical padding.
3. **Menu Design**: If building a dropdown or context menu, style it like an iOS Action Sheet but with a white background, soft shadow, and high border radius.

Refine every detail to match this calm, distinctively "soft" visual language.
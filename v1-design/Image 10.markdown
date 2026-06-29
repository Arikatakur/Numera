---
name: Luminous Ledger
colors:
  surface: '#101419'
  surface-dim: '#101419'
  surface-bright: '#36393f'
  surface-container-lowest: '#0b0e13'
  surface-container-low: '#181c21'
  surface-container: '#1d2025'
  surface-container-high: '#272a30'
  surface-container-highest: '#32353b'
  on-surface: '#e0e2ea'
  on-surface-variant: '#c2c9b3'
  inverse-surface: '#e0e2ea'
  inverse-on-surface: '#2d3036'
  outline: '#8d937f'
  outline-variant: '#434938'
  surface-tint: '#9ed752'
  primary: '#fdfff1'
  on-primary: '#203600'
  primary-container: '#b8f36a'
  on-primary-container: '#456f00'
  inverse-primary: '#426900'
  secondary: '#5ddbbd'
  on-secondary: '#00382d'
  secondary-container: '#00a389'
  on-secondary-container: '#003027'
  tertiary: '#fffdff'
  on-tertiary: '#3d2847'
  tertiary-container: '#f6d7ff'
  on-tertiary-container: '#735b7d'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#b9f46b'
  primary-fixed-dim: '#9ed752'
  on-primary-fixed: '#112000'
  on-primary-fixed-variant: '#304f00'
  secondary-fixed: '#7cf8d9'
  secondary-fixed-dim: '#5ddbbd'
  on-secondary-fixed: '#002019'
  on-secondary-fixed-variant: '#005142'
  tertiary-fixed: '#f7d9ff'
  tertiary-fixed-dim: '#dabce3'
  on-tertiary-fixed: '#271331'
  on-tertiary-fixed-variant: '#553e5e'
  background: '#101419'
  on-background: '#e0e2ea'
  surface-variant: '#32353b'
  surface-secondary: '#0B1118'
  surface-card: '#101823'
  surface-elevated: '#151F2B'
  text-primary: '#F8FAFC'
  text-secondary: '#9AA6B2'
  text-tertiary: '#64748B'
  danger: '#FF6B6B'
  warning: '#F8C46B'
  chart-purple: '#A78BFA'
  chart-orange: '#FDBA74'
  chart-pink: '#F472B6'
  border-glass: rgba(255, 255, 255, 0.08)
typography:
  display-money:
    fontFamily: Plus Jakarta Sans
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  display-money-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 34px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '600'
    lineHeight: 24px
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-caps:
    fontFamily: Plus Jakarta Sans
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.05em
  caption:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  base: 8px
  margin-mobile: 20px
  margin-desktop: 40px
  gutter: 16px
  card-padding: 24px
---

## Brand & Style

The design system is engineered for a premium, private, and high-performance financial tracking experience. It adopts a **Modern-Corporate** aesthetic fused with **Glassmorphism** to create a UI that feels like a precision instrument. The brand personality is calm and authoritative, replacing the typical anxiety of expense tracking with a sense of mastery and "private wealth management."

The target audience consists of tech-forward professionals who appreciate high-end hardware and dark-mode-first interfaces. The emotional response should be one of "digital serenity"—where complex financial data is contained within elegant, soft-edged modules that feel tangible and high-quality.

## Colors

This design system utilizes a "Deep-Sea" dark mode palette. The background is not a flat black, but a tiered series of charcoal-blue surfaces that provide depth and reduce eye strain.

- **Primary Accent:** A vibrant "Mint-Volt" (#B8F36A) used exclusively for positive growth, income, and primary calls to action.
- **Surface Strategy:** Layers are defined by increasing lightness. The deeper the layer, the further back it sits.
- **Data Visualization:** A secondary palette of soft neon pastels is reserved for charts to ensure categorical distinction without clashing with the primary brand accent.
- **Glass Effects:** Interactive elements use a thin, low-opacity white stroke to simulate the edge of a glass pane, catching "light" from the UI.

## Typography

The typography system leverages **Plus Jakarta Sans** (as a high-character alternative to SF Pro Rounded) to maintain a modern, friendly yet professional tone.

**Financial Clarity:** All currency values must use **tabular/monospaced digits**. This ensures that decimal points align vertically in lists and transaction logs, allowing for instant visual scanning of amounts.

**Hierarchy:** Large title levels use a tighter letter-spacing to feel "locked in," while labels and metadata use slightly increased tracking to maintain legibility against dark backgrounds.

## Layout & Spacing

The layout follows a **Fluid-Inset** model. While the overall container stretches to the screen width, content is housed within high-radius cards that have generous internal breathing room.

- **Grid:** A standard 8pt rhythm governs all spacing.
- **Safe Zones:** Mobile layouts must maintain a 20px horizontal margin to ensure content does not feel "pinched" by the device edge.
- **One-Handed Priority:** Heavy interaction elements (Add Button, Keypad, Tab Bar) are anchored to the bottom third of the screen. 
- **Grouping:** Use whitespace (32px+) to separate distinct data sections (e.g., Daily Spend vs. Monthly Budget) rather than horizontal rules.

## Elevation & Depth

Depth is communicated through **Tonal Layering** supplemented by **Backdrop Blurs**. Shadows are used not to simulate height, but to create a "glow" or soft separation between similar tones.

- **Level 0 (Base):** #070A0F. The infinite canvas.
- **Level 1 (Modules):** #101823 with a 1px border at 8% opacity. This is the primary container for data.
- **Level 2 (Interaction):** #151F2B. Used for active states, pressed cards, or high-priority modals.
- **Level 3 (Overlay):** Standard iOS system blurs (Ultra Thin Material) for navigation bars and tab bars to maintain context of the content scrolling underneath.
- **Shadows:** Use large-radius (20-40px), low-opacity (15%) shadows tinted with the primary accent color for the "Add" button to make it feel like it is emitting light.

## Shapes

The shape language is defined by **Continuous Curvature** (squicles). 

- **Primary Containers:** Cards use a significant 28pt radius to appear soft and premium.
- **Action Elements:** Buttons and Category Icons use a 16pt radius or are fully pill-shaped (rounded-full) if they contain labels.
- **Input Fields:** Search bars and text fields should match the card radius (24-28pt) to maintain a cohesive silhouette when nested.

## Components

### Buttons
- **Primary:** Solid #B8F36A background with black text. Pill-shaped. No shadow, just a subtle glow on hover/tap.
- **Secondary:** Ghost style with the 1px `border-glass` and Text Primary labels.
- **Icon Buttons:** Circular #151F2B background with a centered SF Symbol.

### Cards
- **Dashboard Modules:** #101823 background, 28pt radius, 1px white stroke (8% opacity). Internal padding should be 24px.
- **Transaction Row:** Flat layout on the card with a 48pt circular icon container on the left for category symbols.

### Inputs & Keypad
- **Keypad:** Large, borderless numbers with high-contrast active states. Haptic feedback is mandatory for every tap.
- **Text Inputs:** Subtle bottom-border only or fully enclosed glass-style containers with 24pt radius.

### Feedback & Status
- **Success:** A subtle pulse animation using the Primary Accent.
- **Privacy Mode:** When active, all monospaced digits are replaced with a high-gaussian blur (20px), maintaining the layout structure while obscuring data.
- **Chips:** Small, fully rounded pills used for "Category Tags" or "Account Names" with a low-opacity fill of the chart colors.
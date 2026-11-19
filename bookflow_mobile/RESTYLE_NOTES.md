# BookFlow restyle: what changed

## Root cause of the light/dark bug
Most screens hardcoded the dark palette (`AppColors.warmIvory` text, `deepSage` cards, ...) inside
`const` styles, so light mode rendered ivory-on-white and some widgets never updated on switch.
`AppColors` is now a set of live getters backed by the active theme (light or dark), and
`PaletteScope` rebuilds the whole tree in the same frame when the theme or brightness changes,
then cross-fades from a snapshot of the old look.

## New / rewritten
- `lib/theme.dart`      5 themes (Crimson default, Champagne, Ocean, Amethyst, Emerald), each with light + dark.
- `lib/widgets/palette_scope.dart`  applies palette, force-rebuilds, cross-fade, status bar style.
- `lib/screens/splash_screen.dart`  animated splash modelled on the reference video + SplashGate.
- `lib/screens/landing/landing_screen.dart`  new look: drifting colour blobs, orbiting illustrations, parallax, staggered entrance.
- `lib/screens/shells.dart`  nav bar with sliding indicator + fade-through tab transitions.
- `lib/screens/shared/account_screen.dart`  colour-theme picker next to Light/Auto/Dark.
- `lib/state/app_state.dart`  persists the chosen theme.
- `assets/images/bookflow_mark.png`  the "B" mark extracted from the video (transparent PNG).

## Migrated (mechanical)
Every screen: old colour names -> live names (`warmIvory`->`text`, `mutedSage`->`muted`,
`champagneGold`->`accent`, `midnightForest`->`bg`, `deepSage`->`surface`, `sageBorder`->`border`),
and `const` removed wherever a dynamic colour sits inside it.
Text/icons drawn on the accent colour use `AppColors.onAccent`.

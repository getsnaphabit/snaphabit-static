# /images/press/ — Press-Kit Asset Serving Directory

Public-facing press-kit assets served on `getsnaphabit.com`.

These assets are mirrored from the awareflow-static repo so both sites
can serve the same canonical Apple-sourced badge without cross-origin
hotlinking. When the awareflow-static copy is re-pulled, mirror the
refresh here as well.

## Files served

- `app-store-badge-black.svg`: Apple "Download on the App Store" badge,
  preferred black variant per Apple identity guidelines.
- `app-store-badge-white.svg`: Apple "Download on the App Store" badge,
  white variant for dark surfaces.

## Source

All assets sourced from Apple's App Store Marketing Tools toolbox:
https://toolbox.marketingtools.apple.com/en-us/app-store/us

The toolbox returns territory-specific assets. These are the US App Store
variants.

## Apple identity guidelines

- One App Store badge per page.
- Badge is subordinate to the main message of the page; not the main visual.
- Descriptive copy should accompany the badge.
- The badge graphic itself must not be used on social media. Link to the
  App Store Content Link instead:
  https://apps.apple.com/app/awareflow/id6746681323
- Black variant preferred; white variant for dark surfaces only.
- Do not modify the badge: no recolors, no rotations, no gradient overlays,
  no drop shadows Apple did not provide.

## Re-pull cadence

Re-pull from the toolbox (and mirror the awareflow-static copy) when:
- Apple updates the badge design (rare; check Apple's Design Resources page).
- A new App Store territory is added and territory-specific variants are
  needed.

Otherwise treat these as static canonical assets.

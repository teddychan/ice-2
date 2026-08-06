# Layout Pane — Manual Test Plan

The Layout pane's on-screen behavior (moving items, showing/hiding sections,
applying profiles) is driven by real `NSStatusItem`s and the scromble EventTap
barrier, which need **granted TCC permissions** and therefore cannot be
covered by the automated `IceTests` suite. Run this checklist by hand.

## Preconditions

- [ ] Run a **TCC-permissioned build** — the release-identity build **or** the
      installed app — **not** the isolated `com.dragonapp.ice.debug` build
      (it cannot hold the grants).
- [ ] **Accessibility** and **Screen Recording** are granted to that build.
- [ ] Start from a known menu bar with at least two movable third-party items.
- [ ] Open **Settings ▸ Layout**.

## 1. Move items among sections

- [ ] Drag a third-party item from the **Visible** bar to the **Hidden** bar.
  - Expected (menu bar): the item disappears from the always-visible strip and
    only appears when the Hidden section is revealed.
  - Expected (Layout pane): the item now sits in the Hidden bar; Visible bar loses it.
- [ ] Reveal the Hidden section (click the hidden control item / Ice icon).
  - Expected (menu bar): the moved item becomes visible.
- [ ] Drag the item from **Hidden** to **Always-Hidden**.
  - Expected (menu bar): item hidden until the always-hidden section is revealed.
  - Expected (Layout pane): item now in the Always-Hidden bar.
- [ ] Drag it back to **Visible**.
  - Expected (menu bar): item returns to the always-visible strip.
  - Expected (Layout pane): item back in the Visible bar.
- [ ] Attempt to drag the **Clock** and **Control Center** items.
  - Expected: they cannot be moved (immovable).
- [ ] Attempt to move a non-hideable system item (e.g. FaceTime) into Hidden.
  - Expected: it refuses to hide.

## 2. Backup / Update / Apply profile

- [ ] With a known arrangement, enter a name and click **Save Current Layout**.
  - Expected (Layout pane): a profile row appears with per-section counts.
- [ ] Rearrange several items, then click **Apply** on the saved profile.
  - Expected (menu bar): items snap back to the saved arrangement.
  - Expected (Layout pane): the three bars match the saved profile.
- [ ] Rearrange again, then click **Update** on the profile.
  - Expected (Layout pane): the profile's counts update to the new arrangement.
- [ ] Disable the Always-Hidden section (Advanced settings), then **Apply** a
      profile that contains always-hidden items.
  - Expected: the Always-Hidden section auto-enables, then items place correctly.
- [ ] Full backup round-trip: export an `.icebackup`, change the layout,
      restore the file, relaunch.
  - Expected: the exact layout from the backup returns.

## 3. Other important cases

- [ ] **Spacers:** add a spacer and adjust its width slider.
  - Expected (menu bar): the gap between items changes live.
- [ ] Delete the spacer.
  - Expected (menu bar): the gap disappears.
- [ ] Save a profile while a spacer exists, then inspect the profile.
  - Expected: the spacer is **not** captured into the profile.
- [ ] **Relaunch persistence:** create a profile, quit Ice, relaunch.
  - Expected: the profile still lists with correct counts.
- [ ] **Empty-section edges:** apply a profile with an empty section; save a
      profile with nothing hidden.
  - Expected: no crash; bars reflect the empty sections.
- [ ] **Permission gating:** revoke Screen Recording in System Settings.
  - Expected (Layout pane): the pane disables with its explanation.
- [ ] Re-grant Screen Recording and return to the app.
  - Expected (Layout pane): the pane re-enables.

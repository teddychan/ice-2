# Frequent Issues <!-- omit in toc -->

- [Items are moved to the always-hidden section](#items-are-moved-to-the-always-hidden-section)
- [Ice 2 removed an item](#ice-2-removed-an-item)
- [Ice 2 does not remember the order of items](#ice-2-does-not-remember-the-order-of-items)
- [How do I solve the `Ice 2 cannot arrange menu bar items in automatically hidden menu bars` error?](#how-do-i-solve-the-ice-2-cannot-arrange-menu-bar-items-in-automatically-hidden-menu-bars-error)

## Items are moved to the always-hidden section

By default, macOS adds new items to the far left of the menu bar, which is also the location of Ice 2's always-hidden section. Most apps are configured
to remember the positions of their items, but some are not. macOS treats the items of these apps as new items each time they appear. This results in
these items appearing in the always-hidden section, even if they have been previously been moved.

Ice 2 does not currently manage individual items, and in fact cannot, as of the current release. Once issues
[#6](https://github.com/jordanbaird/Ice/issues/6) and [#26](https://github.com/jordanbaird/Ice/issues/26) are implemented, Ice 2 will be able to
monitor the items in the menu bar, and move the ones it recognizes to their previous locations, even if macOS rearranges them.

## Ice 2 removed an item

Ice 2 does not have the ability to move or remove items. It likely got placed in the always-hidden section by macOS. Option + click the Ice 2 icon to show
the always-hidden section, then Command + drag the item into a different section.

## Ice 2 does not remember the order of items

This is not a bug, but a missing feature. It is being tracked in [#26](https://github.com/jordanbaird/Ice/issues/26).

## How do I solve the `Ice 2 cannot arrange menu bar items in automatically hidden menu bars` error?

1. Open `System Settings` on your Mac
2. Go to `Control Center`
3. Select `Never` as shown in the image below
4. Update your `Menu Bar Items` in `Ice 2`
5. Return `Automatically hide and show the menu bar` to your preferred settings

![Disable Menu Bar Hiding](https://github.com/user-attachments/assets/74c1fde6-d310-4fe3-9f2b-703d8ccb636a)

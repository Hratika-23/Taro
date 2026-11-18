# Taro — a cat who lives in your iPhone widget

## What's inside
- **CatWidget/** — the widget itself
  - `CatState.swift` — Taro's life: hunger, fun, energy, naps, reactions
  - `CatIntents.swift` — what each tap does (pet, feed, play, lights)
  - `RoomView.swift` — the room (large widget): window, ticking clock, lamp, bed, bowl, yarn
  - `CatView.swift` — Taro himself, drawn with shapes, in every pose
  - `LiveMotion.swift` — the trick that makes the tail swish, eyes blink and Zzz float on the home screen
  - `Theme.swift` — colours, and **the cat's name** (change `CatInfo.name`)
- **CatHome/** — the small app that carries the widget onto your phone

## Taps
| Tap | What happens |
|---|---|
| Taro | Pet him (hearts + purr) |
| Bowl | Feed him (he walks over and eats) |
| Yarn | Play (he bats the rolling yarn) |
| Lamp or bed | Bedtime / wake up |

## Live motion
Tail swish, blinking, breathing while asleep, floating Zzz and hearts, rolling yarn and a ticking wall clock.
These use the clock-hand rotation trick through the open-source
[ClockHandRotationKit](https://github.com/octree/ClockHandRotationKit) package (Xcode downloads it automatically).
This trick is not officially supported by Apple. If a future iOS update breaks it, the moving parts
freeze, but everything else keeps working.

## Requirements
- A Mac with Xcode 16 or newer
- iPhone on iOS 17 or newer
- A free Apple ID works; the app then needs re-installing from Xcode every 7 days

# Boo Knight — LEDGER

Goal: SMB1-style spooky-cute 8-bit side-scroller for a 6-year-old, GDScript/Godot 4.7.2, browser-served. MC workspace 11611, feature 11612 (anchor rules: cards 11613 T1 code / 11614 T3 test / 11615 T2 sprites / 11617 T2a gpu-window budget / 11641 vm100 IO finding).

STATUS: ACTIVE — game built & core rules browser-verified; art pass BLOCKED on vm100 storage (MC 11641, owner decision pending).

| date | card | line |
|---|---|---|
| 2026-10-28 | 11612 | scaffold, sprite manifest (19 files), briefs |
| 2026-10-28 | 11613 | T1 build: full game + sim/smoke gates (commit 771730c), red-capable; orchestrator re-ran green 24 PASS/exit 0, red exit 1 |
| 2026-10-28 | 11617 | gpu-window comfy boot budget 180s->480s->1320s (session/gwfix + vm100 hot-patch); open healthy after 1011s VERIFIED (events.log 21:13:45Z) |
| 2026-10-28 | 11614 | T3 pass1: A1-A5 VERIFIED in real browser + sim; A6 pending art; A7 browser leg pending balance fix; P2 balance finding (spawn slimes kill in 5-12s) |
| 2026-10-28 | 11641 | vm100 storage finding: ~3.5MB/s cap, IO PSI ~85% idle; owner options filed (NVMe / mlock / quiet-hours batching) |

Acceptance rows (parent 11612): A1 VERIFIED browser · A2 VERIFIED sim · A3 VERIFIED sim · A4 VERIFIED sim · A5 VERIFIED sim+browser · A6 PENDING (sprites, blocked by 11641) · A7 sim VERIFIED, browser pending balance-fix round.

Open rounds when unblocked: (R1) sprite batch on fixed/decided GPU path -> assets/sprites; (R2) code pass: spawn-balance fix + wire real art + drive A7 in browser; (R3) re-export, final vision verify, serve + hand URL to owner; release = bryn1/boo-knight repo + LEDGER/README/release notes per GitHub doctrine.

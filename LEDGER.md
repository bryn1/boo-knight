# Boo Knight — LEDGER

Goal: SMB1-style spooky-cute 8-bit side-scroller for a 6-year-old, GDScript/Godot 4.7.2, browser-served. MC workspace 11611, feature 11612 (anchor rules: cards 11613 T1 code / 11614 T3 test / 11615 T2 sprites / 11617 T2a gpu-window budget / 11641 vm100 IO finding).

STATUS: COMPLETE — acceptance A1-A7 all VERIFIED in real browser + gates; T4 animation SHIPPED (16 frames + hero/mob facing, 2026-10-30); served at https://192.168.5.231:8792/ (plain http://192.168.5.231:8791/ now 301-redirects there — Godot web needs a secure context; see OPS/OPS2 rows + commits 7dea84c/e21908c)

| date | card | line |
|---|---|---|
| 2026-10-28 | 11612 | scaffold, sprite manifest (19 files), briefs |
| 2026-10-28 | 11613 | T1 build: full game + sim/smoke gates (commit 771730c), red-capable; orchestrator re-ran green 24 PASS/exit 0, red exit 1 |
| 2026-10-28 | 11617 | gpu-window comfy boot budget 180s->480s->1320s (session/gwfix + vm100 hot-patch); open healthy after 1011s VERIFIED (events.log 21:13:45Z) |
| 2026-10-28 | 11614 | T3 pass1: A1-A5 VERIFIED in real browser + sim; A6 pending art; A7 browser leg pending balance fix; P2 balance finding (spawn slimes kill in 5-12s) |
| 2026-10-28 | 11641 | vm100 storage finding: ~3.5MB/s cap, IO PSI ~85% idle; owner options filed (NVMe / mlock / quiet-hours batching) |

Acceptance rows (parent 11612): A1 VERIFIED browser · A2 VERIFIED sim · A3 VERIFIED sim · A4 VERIFIED sim · A5 VERIFIED sim+browser · A6 VERIFIED R2 (real sprites render in browser + ART REAL in smoke; no-art fallback boots) · A7 VERIFIED R2 (3 s grace: headless probe 30->30 in-grace / 30->28 after; slimes >=42 tiles from spawn; browser walk + 0 console errors; full-vision pass is R3).

| 2026-10-29 | 11613 | knut VERIFIED (T1 close stood) |
| 2026-10-29 | 11615 | T2 sprites DONE: owner unblocked vm100 ("Vm100 and comfy ui up and tunning"); 19 renders in one clean window (~40s ea), published as manifest filenames, commit 09704d6, knut VERIFIED |
| 2026-10-29 | 11641 | RESOLVED by owner session: llama-swap --load-mode dio (eviction war ended; reload preserves torch page-cache, disk PSI ~0, reload 19s) + gpu-window 1320s budget squash-landed to agent-town master (801e4d6d); card cancelled; gwfix branch redundant, removed |
| 2026-10-29 | 11612 | R2 round spawned: wire real art + kid-friendly spawn grace + re-export; then browser A7 + final vision pass |
| 2026-10-29 | 11612 | R2 code DONE: real sprites wired (--import step, aspect-true display sizes, ground tile 256->16 halving-average, heart_half HUD live), 3 s spawn contact-grace per run/level (blinks via existing i-frame code), L1 first slimes 14/30->44/52 (min spawn-mob dist 12->42 tiles; no rule numbers touched); sim 24 PASS exit 0, --plant-bad exit 1; smoke exit 0 "ART REAL"+SMOKE OK, mutation exit 1 (assembly assertion added, false-green closed); no-art fallback boot exit 0; web re-export exit 0, pck 43KB->3.16MB with all 19 ctex, served :8791 byte-identical; browser 0 console errors, title+gameplay art screenshots (.audits/) |
| 2026-10-29 | 11612 | R3 code DONE: gated debug start-tile hook — ?start=<int> via JSBridge on Web (platform-name guard: 4.7.2 registers JSBridge on desktop too, get_eval answers null-ish off-web) + BOOKNIGHT_START_TILE env on desktop/headless, clamped forward to first solid non-pit non-wall ground tile; unset = byte-for-byte default; zero rule numbers touched; sim exit 0 / plant-bad exit 1, smoke exit 0 + env=160 deep-start assertion exit 0, mutation (clamp dead) exit 1, clamp edges VERIFIED (pit 151->154, 58->61, wall 197->198, past-end -> default); web export exit 0, served :8791 index.pck byte-identical (md5 b0689aa6); evidence .audits/R3-RESULT.md |

Open rounds when unblocked: ~~(R1) sprite batch~~ DONE (T2, commit 09704d6) · ~~(R2) code pass~~ DONE 2026-10-29 (this commit) · (R3) final vision verify, serve + hand URL to owner; release = bryn1/boo-knight repo + LEDGER/README/release notes per GitHub doctrine.
| 2026-10-29 | 11612 | FINAL: A7 browser VERIFIED (?start=171 hook; orchestrator fixed JS-bridge calls 7f22467+16a8e7d) — Stone Sword pickup + heart_half on screen (.audits/a7-deep-v2.png); A1-A7 all VERIFIED |
| 2026-10-30 | 11612 | OPS: owner hit Godot "Secure Context" error on LAN (http://IP is not a secure context; localhost was) -> systemd boo-knight.service HTTPS :8792 self-signed SAN IP (unit + serve_tls.py committed, keys gitignored, enabled) |
| 2026-10-30 | 11612 | OPS2: owner got ERR_CONNECTION_RESET (Chrome typed http:// on the TLS port) -> serve_tls.py is now a gateway: TLS serves, plain-HTTP from LAN 301-redirects to https, loopback still served plain for tests; VERIFIED 301->200 follow, title renders in browser via gateway (.audits/gw-title.png) |
| 2026-10-30 | 11716+11715 | T4 ANIMATION: 16 QA-locked frames (T4a knut-VERIFIED 67d616e) + wiring commit e8188ac (walk/attack anims, hero+mob facing, slime squash, blink latent-bug fix); gates re-run by closer (sim 0/bad 1/smoke 0x2); browser: walk+face-left+blink+slime-frames VERIFIED live (an2-walk-r2, an4-facing-left, an4-walk-r) |

Goal: "Boo Knight" — a browser-playable 8-bit-style side-scrolling action platformer for a 6-year-old, close in feel to Super Mario Bros 1 (NES) but spooky-cute: kid knight fights skeletons, zombies, ghosts, vampires and slimes across 3 levels + boss.
Project dir: /home/claudecode/Games/boo-knight (Godot 4.7.2, GDScript, web export served locally).
Owner-stated rules (verbatim from owner): start with wooden sword dmg 1; upgrades stone dmg 2, iron dmg 3, diamond dmg 5; player has 30 hearts; food replenishes hearts; mobs have 2-10 hp; upon death you start from the beginning. Sprites must be real images generated on the vm100 3090. Spooky but age-suitable (no gore, goofy-cute).
Owner rulings this session: language = GDScript; play target = Browser.
Acceptance criteria: (each row proven before done)
A1 game boots in browser at a served URL, title -> level 1 playable (browser + vision verified)
A2 sword damage table wood1/stone2/iron3/diamond5 applied to mob HP (headless sim, red-capable gate)
A3 mobs HP within 2-10 per spec (slime2 ghost3 zombie4 skeleton6 vampire8 lord10) (sim)
A4 30-heart HP, food heals, cap at 30 (sim)
A5 death -> full restart from level 1 with wooden sword + full hearts (sim + browser)
A6 real generated sprites render in game (browser + vision verified)
A7 gear chests upgrade sword stone/iron/diamond across levels 1-3 (sim + browser)

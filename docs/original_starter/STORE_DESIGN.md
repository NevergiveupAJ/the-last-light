# Optional In-Game Store

## Recommended store philosophy
Keep the base horror story fully playable without paying. Avoid pay-to-win upgrades that trivialize the monster.
Use cosmetics and optional soundtrack/artbook products only. Clearly label every price and what is included.

## Example catalog
- Storm Coat — cosmetic survivor outfit.
- Research Suit — cosmetic outfit.
- Vintage Beam — flashlight appearance only; no extra gameplay power.
- Original Soundtrack — optional audio album.
- Digital Artbook — concept art and production notes.

## Do not implement until ready
- Real-money purchases require Apple/Google billing integration, product setup, receipt validation, refund handling,
  parental safeguards, and privacy disclosures.
- Never store card details yourself.
- Never claim purchases are implemented in the starter project; `store_manager.gd` only demonstrates a catalog signal.
- If using ads, disclose them and do not interrupt intense gameplay or mislead players.

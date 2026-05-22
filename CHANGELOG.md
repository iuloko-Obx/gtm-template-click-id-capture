# Changelog

All notable changes to this template will be documented here.

## [1.0.1] - 2026-05-22

### Fixed
- Corrected permission `publicId` from `read_url` to `get_url` so the template imports without "Unknown entity type" errors

## [1.0.0] - 2026-05-22

Initial release.

### Added
- Captures 9 click IDs from URL parameters:
  - `gclid` (Google Ads, 90 days)
  - `gbraid` (Google Ads iOS app, 90 days)
  - `wbraid` (Google Ads iOS web, 90 days)
  - `fbclid` (Meta, 90 days, builds `_fbc`)
  - `msclkid` (Microsoft Ads, 90 days)
  - `ttclid` (TikTok, 30 days)
  - `rdtclid` (Reddit, 90 days)
  - `li_fat_id` (LinkedIn, 90 days)
  - `twclid` (X / Twitter, 90 days)
- Per-click-ID toggle in template UI
- First-party cookie storage on root domain (auto-detected)
- localStorage backup for ITP recovery
- Meta `_fbc` auto-construction in `fb.1.{timestamp}.{fbclid}` format
- `click_ids_ready` dataLayer event with all captured IDs
- Debug logging toggle (preview mode only)

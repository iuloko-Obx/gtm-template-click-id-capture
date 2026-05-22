================================================================================
OBx CLICK ID CAPTURE
GTM Custom Template
================================================================================

A Google Tag Manager Custom Template that captures ad platform click IDs from
URL parameters, stores them in first-party cookies and localStorage with
platform-specific attribution windows, and pushes them to the dataLayer for
forwarding to server-side GTM.

Built by OuterBox (outerbox.com) for the sGTM migration toolkit.


================================================================================
WHAT IT DOES
================================================================================

When a user lands on your site with one of these URL parameters, the template
captures it:

   CLICK ID      PLATFORM                 STORAGE DURATION
   ----------    ---------------------    -----------------
   gclid         Google Ads               90 days
   gbraid        Google Ads (iOS app)     90 days
   wbraid        Google Ads (iOS web)     90 days
   fbclid        Meta                     90 days (auto-builds _fbc)
   msclkid       Microsoft Ads            90 days
   ttclid        TikTok                   30 days
   rdtclid       Reddit                   90 days
   li_fat_id     LinkedIn                 90 days
   twclid        X / Twitter              90 days

Each click ID gets stored in three places:

   1. First-party cookie under the root domain
      (e.g., _obx_gclid on .client.com)

   2. localStorage as a backup
      (for ITP recovery when Safari purges cookies)

   3. dataLayer via a click_ids_ready event
      (for GTM tags to consume)


================================================================================
SPECIAL HANDLING: META _fbc
================================================================================

When fbclid is captured, the template also writes the Meta CAPI-formatted _fbc
value to the _obx_fbc cookie:

   fb.1.{timestamp_ms}.{fbclid}

This is the exact format Meta CAPI expects, so you can plug the cookie value
straight into your sGTM Meta tag's user_data.fbc field. No transformation
needed on the server side.


================================================================================
INSTALL
================================================================================

OPTION A: Community Template Gallery (recommended once published)
-----------------------------------------------------------------

   1. In your GTM web container, go to Templates > Search Gallery
   2. Search for "OBx Click ID Capture"
   3. Click "Add to workspace"


OPTION B: Manual import
-----------------------

   1. Download template.tpl from the GitHub repo
   2. In your GTM web container, go to Templates > New
   3. Click the three-dot menu in the top right > Import
   4. Select the template.tpl file
   5. Click Save


================================================================================
SETUP
================================================================================

   1. Go to Tags > New
   2. Under Tag Configuration, select "OBx Click ID Capture" in the Custom
      section
   3. Toggle the click IDs you want to capture for this client
   4. Set the trigger to "Consent Initialization - All Pages"
      (or "Initialization - All Pages" if not using Consent Mode)
   5. Save and submit


================================================================================
USE IN sGTM
================================================================================

The template writes both cookies and a dataLayer event, so you have two paths:


PATH 1: First-Party Cookie variables (simpler)
----------------------------------------------

Create GTM variables of type "1st-Party Cookie" pointing at:

   _obx_gclid
   _obx_fbc       (Meta CAPI-ready)
   _obx_msclkid
   _obx_ttclid
   ...etc

Then add them as Event Parameters to your GA4 event tag, which forwards to your
sGTM endpoint.


PATH 2: dataLayer variables
---------------------------

Listen for the click_ids_ready event and pull individual keys (gclid, fbc, etc.)
or the full click_ids object.


================================================================================
PERMISSIONS
================================================================================

This template requires:

   - Reads URL (for query parameters)

   - Reads cookies:
        _obx_gclid, _obx_gbraid, _obx_wbraid, _obx_fbclid, _obx_fbc,
        _obx_msclkid, _obx_ttclid, _obx_rdtclid, _obx_li_fat_id, _obx_twclid

   - Sets cookies: same list as above

   - Accesses localStorage: keys prefixed with obx_click_

   - Writes to dataLayer: event, click_ids, and the individual click ID keys

   - Logs to console (debug mode only)


================================================================================
IMPORTANT NOTES ON ITP AND ATTRIBUTION WINDOWS
================================================================================

Safari ITP caps JavaScript-set first-party cookies at 7 days of inactivity, and
localStorage at 7 days too. Setting a 90-day expiry on the cookie doesn't
override that. The real durability comes from:

   1. Sending click IDs to your server (via sGTM) on every event

   2. Storing them server-side in your CRM tied to a lead or user ID

   3. Refreshing the cookie on every visit
      (which this template does on cookie reads)

For client-side use alone, expect cookies to die at 7 days for Safari users.
For full server-side persistence, use the click_ids_ready dataLayer event to
forward click IDs to sGTM, which can write its own HttpOnly cookie with a true
90-day lifetime.


================================================================================
WHY WE MADE THIS
================================================================================

OBx manages measurement for clients across many ad platforms. Every sGTM
migration we do needs the same component: reliably capturing click IDs on the
client side so they can be forwarded server-side for CAPI integrations (Meta,
Microsoft, TikTok, LinkedIn, X).

Instead of copy-pasting Custom HTML tags into every container, we built one
template that any team member can deploy in 5 minutes per client.


================================================================================
CONTRIBUTING
================================================================================

Issues and PRs welcome.

To modify the template:

   1. Clone the repo
   2. Import template.tpl into a GTM workspace
      (Templates > New > Import)
   3. Make changes in the GTM template editor
   4. Export the template and replace template.tpl with the new file
   5. Update metadata.yaml with the new commit SHA
   6. Open a PR

Do NOT edit template.tpl by hand. Always use the GTM template editor to ensure
validation passes.


================================================================================
LICENSE
================================================================================

Apache 2.0 - see LICENSE file in the repo.


================================================================================
SUPPORT
================================================================================

Repo: github.com/iuloko-Obx/gtm-template-click-id-capture
Issues: github.com/iuloko-Obx/gtm-template-click-id-capture/issues
OuterBox: outerbox.com

================================================================================

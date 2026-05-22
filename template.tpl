___INFO___

{
  "type": "TAG",
  "id": "cvt_temp_public_id",
  "version": 1,
  "securityGroups": [],
  "displayName": "OBx Click ID Capture",
  "categories": ["UTILITY", "ANALYTICS"],
  "brand": {
    "id": "outerbox",
    "displayName": "OuterBox"
  },
  "description": "Captures ad platform click IDs (gclid, gbraid, wbraid, fbclid, msclkid, ttclid, rdtclid, li_fat_id, twclid) from URL parameters. Stores them in first-party cookies and localStorage with platform-specific attribution windows. Automatically builds the Meta _fbc value for CAPI. Pushes everything to the dataLayer as a click_ids_ready event so server-side GTM can forward them downstream.",
  "containerContexts": ["WEB"]
}


___TEMPLATE_PARAMETERS___

[
  {
    "type": "GROUP",
    "name": "clickIdToggles",
    "displayName": "Click IDs to capture",
    "groupStyle": "ZIPPY_OPEN",
    "subParams": [
      {
        "type": "CHECKBOX",
        "name": "captureGclid",
        "checkboxText": "gclid (Google Ads, 90 days)",
        "simpleValueType": true,
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "captureGbraid",
        "checkboxText": "gbraid (Google Ads iOS app, 90 days)",
        "simpleValueType": true,
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "captureWbraid",
        "checkboxText": "wbraid (Google Ads iOS web, 90 days)",
        "simpleValueType": true,
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "captureFbclid",
        "checkboxText": "fbclid (Meta, 90 days, builds _fbc for CAPI)",
        "simpleValueType": true,
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "captureMsclkid",
        "checkboxText": "msclkid (Microsoft Ads, 90 days)",
        "simpleValueType": true,
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "captureTtclid",
        "checkboxText": "ttclid (TikTok, 30 days)",
        "simpleValueType": true,
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "captureRdtclid",
        "checkboxText": "rdtclid (Reddit, 90 days)",
        "simpleValueType": true,
        "defaultValue": false
      },
      {
        "type": "CHECKBOX",
        "name": "captureLiFatId",
        "checkboxText": "li_fat_id (LinkedIn, 90 days)",
        "simpleValueType": true,
        "defaultValue": false
      },
      {
        "type": "CHECKBOX",
        "name": "captureTwclid",
        "checkboxText": "twclid (X / Twitter, 90 days)",
        "simpleValueType": true,
        "defaultValue": false
      }
    ]
  },
  {
    "type": "GROUP",
    "name": "advancedSettings",
    "displayName": "Advanced settings",
    "groupStyle": "ZIPPY_CLOSED",
    "subParams": [
      {
        "type": "TEXT",
        "name": "cookieDomain",
        "displayName": "Cookie domain (leave 'auto' for root domain auto-detect)",
        "simpleValueType": true,
        "defaultValue": "auto"
      },
      {
        "type": "CHECKBOX",
        "name": "enableLocalStorageBackup",
        "checkboxText": "Use localStorage as ITP recovery backup (recommended)",
        "simpleValueType": true,
        "defaultValue": true
      },
      {
        "type": "CHECKBOX",
        "name": "enableLogging",
        "checkboxText": "Enable debug logging (preview mode only)",
        "simpleValueType": true,
        "defaultValue": true
      }
    ]
  }
]


___SANDBOXED_JS_FOR_WEB_TEMPLATE___

// OBx Click ID Capture
// Captures ad platform click IDs from URL, stores in cookies + localStorage,
// pushes to dataLayer for sGTM forwarding.

const getUrl = require('getUrl');
const getQueryParameters = require('getQueryParameters');
const getCookieValues = require('getCookieValues');
const setCookie = require('setCookie');
const localStorage = require('localStorage');
const createQueue = require('createQueue');
const getTimestampMillis = require('getTimestampMillis');
const logToConsole = require('logToConsole');
const makeString = require('makeString');

const dataLayerPush = createQueue('dataLayer');
const COOKIE_PREFIX = '_obx_';
const STORAGE_PREFIX = 'obx_click_';
const MS_PER_DAY = 86400000;

const log = function(msg) {
  if (data.enableLogging) {
    logToConsole('[OBx Click ID Capture] ' + msg);
  }
};

// Build the list of click IDs to process based on user toggles
const clickIdConfig = [];
if (data.captureGclid) {
  clickIdConfig.push({ param: 'gclid', cookie: '_obx_gclid', days: 90 });
}
if (data.captureGbraid) {
  clickIdConfig.push({ param: 'gbraid', cookie: '_obx_gbraid', days: 90 });
}
if (data.captureWbraid) {
  clickIdConfig.push({ param: 'wbraid', cookie: '_obx_wbraid', days: 90 });
}
if (data.captureFbclid) {
  clickIdConfig.push({ param: 'fbclid', cookie: '_obx_fbclid', days: 90 });
}
if (data.captureMsclkid) {
  clickIdConfig.push({ param: 'msclkid', cookie: '_obx_msclkid', days: 90 });
}
if (data.captureTtclid) {
  clickIdConfig.push({ param: 'ttclid', cookie: '_obx_ttclid', days: 30 });
}
if (data.captureRdtclid) {
  clickIdConfig.push({ param: 'rdtclid', cookie: '_obx_rdtclid', days: 90 });
}
if (data.captureLiFatId) {
  clickIdConfig.push({ param: 'li_fat_id', cookie: '_obx_li_fat_id', days: 90 });
}
if (data.captureTwclid) {
  clickIdConfig.push({ param: 'twclid', cookie: '_obx_twclid', days: 90 });
}

// Compute cookie domain. 'auto' resolves to root domain (.outerbox.com style).
const resolveCookieDomain = function() {
  if (data.cookieDomain && data.cookieDomain !== 'auto') {
    return data.cookieDomain;
  }
  const host = getUrl('host') || '';
  // localhost or IP: return as-is
  if (host === 'localhost' || host.indexOf(':') === 0) {
    return host;
  }
  const parts = host.split('.');
  if (parts.length <= 2) {
    return '.' + host;
  }
  return '.' + parts[parts.length - 2] + '.' + parts[parts.length - 1];
};

const cookieDomain = resolveCookieDomain();
log('Resolved cookie domain: ' + cookieDomain);

// Helper: write cookie + localStorage backup together
const writeValue = function(cookieName, storageKey, value, days) {
  const options = {
    domain: cookieDomain,
    path: '/',
    'max-age': days * 24 * 60 * 60,
    secure: true,
    samesite: 'Lax'
  };
  setCookie(cookieName, value, options, false);
  log('Set cookie ' + cookieName + ' = ' + value);

  if (data.enableLocalStorageBackup) {
    const payload = {
      value: value,
      expires: getTimestampMillis() + (days * MS_PER_DAY)
    };
    // localStorage stores strings; build a simple delimited format to avoid JSON.stringify
    // which isn't available in the sandbox.
    const serialized = payload.value + '|' + makeString(payload.expires);
    localStorage.setItem(STORAGE_PREFIX + storageKey, serialized);
    log('Set localStorage ' + STORAGE_PREFIX + storageKey);
  }
};

// Helper: read first cookie value (getCookieValues returns array)
const readCookie = function(name) {
  const values = getCookieValues(name);
  if (values && values.length > 0) {
    return values[0];
  }
  return null;
};

// Helper: read localStorage backup, returns null if expired or missing
const readStorage = function(storageKey) {
  if (!data.enableLocalStorageBackup) return null;
  const raw = localStorage.getItem(STORAGE_PREFIX + storageKey);
  if (!raw) return null;
  const sepIndex = raw.lastIndexOf('|');
  if (sepIndex === -1) return null;
  const value = raw.substring(0, sepIndex);
  const expiresStr = raw.substring(sepIndex + 1);
  const expires = expiresStr * 1;
  if (!expires || getTimestampMillis() > expires) {
    localStorage.removeItem(STORAGE_PREFIX + storageKey);
    return null;
  }
  return value;
};

// Build Meta _fbc value: fb.1.{unix_ms}.{fbclid}
const buildFbc = function(fbclid, timestampMs) {
  return 'fb.1.' + makeString(timestampMs) + '.' + fbclid;
};

// Pull all URL query params once
const queryParams = getQueryParameters() || {};
const now = getTimestampMillis();
const captured = {};

// Process each enabled click ID
for (let i = 0; i < clickIdConfig.length; i++) {
  const cfg = clickIdConfig[i];
  const fromUrl = queryParams[cfg.param];
  const fromCookie = readCookie(cfg.cookie);
  const fromStorage = readStorage(cfg.param);

  let value = null;

  if (fromUrl) {
    // New click: write fresh to both stores
    value = makeString(fromUrl);
    writeValue(cfg.cookie, cfg.param, value, cfg.days);

    // Special handling: fbclid also generates _fbc in Meta's required format
    if (cfg.param === 'fbclid') {
      const fbc = buildFbc(value, now);
      writeValue('_obx_fbc', 'fbc', fbc, cfg.days);
      captured.fbc = fbc;
    }
  } else if (fromCookie) {
    value = fromCookie;
    // Heal localStorage if cookie exists but storage missing
    if (data.enableLocalStorageBackup && !fromStorage) {
      const payload = value + '|' + makeString(now + (cfg.days * MS_PER_DAY));
      localStorage.setItem(STORAGE_PREFIX + cfg.param, payload);
    }
  } else if (fromStorage) {
    // Cookie wiped (ITP, manual clear): restore from localStorage backup
    value = fromStorage;
    writeValue(cfg.cookie, cfg.param, value, cfg.days);
    log('Restored ' + cfg.param + ' from localStorage backup');
  }

  if (value) {
    captured[cfg.param] = value;
  }
}

// Heal _fbc cookie from storage if fbclid is known but cookie is gone
if (data.captureFbclid && captured.fbclid && !readCookie('_obx_fbc')) {
  const storedFbc = readStorage('fbc');
  if (storedFbc) {
    writeValue('_obx_fbc', 'fbc', storedFbc, 90);
    captured.fbc = storedFbc;
  }
}

// Push the unified event to dataLayer
const dlPayload = {
  event: 'click_ids_ready',
  click_ids: captured
};
if (captured.gclid)     dlPayload.gclid = captured.gclid;
if (captured.gbraid)    dlPayload.gbraid = captured.gbraid;
if (captured.wbraid)    dlPayload.wbraid = captured.wbraid;
if (captured.fbclid)    dlPayload.fbclid = captured.fbclid;
if (captured.fbc)       dlPayload.fbc = captured.fbc;
if (captured.msclkid)   dlPayload.msclkid = captured.msclkid;
if (captured.ttclid)    dlPayload.ttclid = captured.ttclid;
if (captured.rdtclid)   dlPayload.rdtclid = captured.rdtclid;
if (captured.li_fat_id) dlPayload.li_fat_id = captured.li_fat_id;
if (captured.twclid)    dlPayload.twclid = captured.twclid;

dataLayerPush(dlPayload);
log('Pushed click_ids_ready to dataLayer');

data.gtmOnSuccess();


___WEB_PERMISSIONS___

[
  {
    "instance": {
      "key": {
        "publicId": "logging",
        "versionId": "1"
      },
      "param": [
        {
          "key": "environments",
          "value": {
            "type": 1,
            "string": "debug"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "read_url",
        "versionId": "1"
      },
      "param": [
        {
          "key": "urlParts",
          "value": {
            "type": 1,
            "string": "any"
          }
        },
        {
          "key": "queriesAllowed",
          "value": {
            "type": 1,
            "string": "any"
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "get_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "cookieAccess",
          "value": {
            "type": 1,
            "string": "specific"
          }
        },
        {
          "key": "cookieNames",
          "value": {
            "type": 2,
            "listItem": [
              {"type": 1, "string": "_obx_gclid"},
              {"type": 1, "string": "_obx_gbraid"},
              {"type": 1, "string": "_obx_wbraid"},
              {"type": 1, "string": "_obx_fbclid"},
              {"type": 1, "string": "_obx_fbc"},
              {"type": 1, "string": "_obx_msclkid"},
              {"type": 1, "string": "_obx_ttclid"},
              {"type": 1, "string": "_obx_rdtclid"},
              {"type": 1, "string": "_obx_li_fat_id"},
              {"type": 1, "string": "_obx_twclid"}
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "set_cookies",
        "versionId": "1"
      },
      "param": [
        {
          "key": "allowedCookies",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "name"},
                  {"type": 1, "string": "domain"},
                  {"type": 1, "string": "path"},
                  {"type": 1, "string": "secure"},
                  {"type": 1, "string": "session"}
                ],
                "mapValue": [
                  {"type": 1, "string": "_obx_gclid"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "any"},
                  {"type": 1, "string": "any"}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "name"},
                  {"type": 1, "string": "domain"},
                  {"type": 1, "string": "path"},
                  {"type": 1, "string": "secure"},
                  {"type": 1, "string": "session"}
                ],
                "mapValue": [
                  {"type": 1, "string": "_obx_gbraid"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "any"},
                  {"type": 1, "string": "any"}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "name"},
                  {"type": 1, "string": "domain"},
                  {"type": 1, "string": "path"},
                  {"type": 1, "string": "secure"},
                  {"type": 1, "string": "session"}
                ],
                "mapValue": [
                  {"type": 1, "string": "_obx_wbraid"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "any"},
                  {"type": 1, "string": "any"}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "name"},
                  {"type": 1, "string": "domain"},
                  {"type": 1, "string": "path"},
                  {"type": 1, "string": "secure"},
                  {"type": 1, "string": "session"}
                ],
                "mapValue": [
                  {"type": 1, "string": "_obx_fbclid"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "any"},
                  {"type": 1, "string": "any"}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "name"},
                  {"type": 1, "string": "domain"},
                  {"type": 1, "string": "path"},
                  {"type": 1, "string": "secure"},
                  {"type": 1, "string": "session"}
                ],
                "mapValue": [
                  {"type": 1, "string": "_obx_fbc"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "any"},
                  {"type": 1, "string": "any"}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "name"},
                  {"type": 1, "string": "domain"},
                  {"type": 1, "string": "path"},
                  {"type": 1, "string": "secure"},
                  {"type": 1, "string": "session"}
                ],
                "mapValue": [
                  {"type": 1, "string": "_obx_msclkid"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "any"},
                  {"type": 1, "string": "any"}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "name"},
                  {"type": 1, "string": "domain"},
                  {"type": 1, "string": "path"},
                  {"type": 1, "string": "secure"},
                  {"type": 1, "string": "session"}
                ],
                "mapValue": [
                  {"type": 1, "string": "_obx_ttclid"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "any"},
                  {"type": 1, "string": "any"}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "name"},
                  {"type": 1, "string": "domain"},
                  {"type": 1, "string": "path"},
                  {"type": 1, "string": "secure"},
                  {"type": 1, "string": "session"}
                ],
                "mapValue": [
                  {"type": 1, "string": "_obx_rdtclid"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "any"},
                  {"type": 1, "string": "any"}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "name"},
                  {"type": 1, "string": "domain"},
                  {"type": 1, "string": "path"},
                  {"type": 1, "string": "secure"},
                  {"type": 1, "string": "session"}
                ],
                "mapValue": [
                  {"type": 1, "string": "_obx_li_fat_id"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "any"},
                  {"type": 1, "string": "any"}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "name"},
                  {"type": 1, "string": "domain"},
                  {"type": 1, "string": "path"},
                  {"type": 1, "string": "secure"},
                  {"type": 1, "string": "session"}
                ],
                "mapValue": [
                  {"type": 1, "string": "_obx_twclid"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "*"},
                  {"type": 1, "string": "any"},
                  {"type": 1, "string": "any"}
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "access_local_storage",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keys",
          "value": {
            "type": 2,
            "listItem": [
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "key"},
                  {"type": 1, "string": "read"},
                  {"type": 1, "string": "write"}
                ],
                "mapValue": [
                  {"type": 1, "string": "obx_click_gclid"},
                  {"type": 8, "boolean": true},
                  {"type": 8, "boolean": true}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "key"},
                  {"type": 1, "string": "read"},
                  {"type": 1, "string": "write"}
                ],
                "mapValue": [
                  {"type": 1, "string": "obx_click_gbraid"},
                  {"type": 8, "boolean": true},
                  {"type": 8, "boolean": true}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "key"},
                  {"type": 1, "string": "read"},
                  {"type": 1, "string": "write"}
                ],
                "mapValue": [
                  {"type": 1, "string": "obx_click_wbraid"},
                  {"type": 8, "boolean": true},
                  {"type": 8, "boolean": true}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "key"},
                  {"type": 1, "string": "read"},
                  {"type": 1, "string": "write"}
                ],
                "mapValue": [
                  {"type": 1, "string": "obx_click_fbclid"},
                  {"type": 8, "boolean": true},
                  {"type": 8, "boolean": true}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "key"},
                  {"type": 1, "string": "read"},
                  {"type": 1, "string": "write"}
                ],
                "mapValue": [
                  {"type": 1, "string": "obx_click_fbc"},
                  {"type": 8, "boolean": true},
                  {"type": 8, "boolean": true}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "key"},
                  {"type": 1, "string": "read"},
                  {"type": 1, "string": "write"}
                ],
                "mapValue": [
                  {"type": 1, "string": "obx_click_msclkid"},
                  {"type": 8, "boolean": true},
                  {"type": 8, "boolean": true}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "key"},
                  {"type": 1, "string": "read"},
                  {"type": 1, "string": "write"}
                ],
                "mapValue": [
                  {"type": 1, "string": "obx_click_ttclid"},
                  {"type": 8, "boolean": true},
                  {"type": 8, "boolean": true}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "key"},
                  {"type": 1, "string": "read"},
                  {"type": 1, "string": "write"}
                ],
                "mapValue": [
                  {"type": 1, "string": "obx_click_rdtclid"},
                  {"type": 8, "boolean": true},
                  {"type": 8, "boolean": true}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "key"},
                  {"type": 1, "string": "read"},
                  {"type": 1, "string": "write"}
                ],
                "mapValue": [
                  {"type": 1, "string": "obx_click_li_fat_id"},
                  {"type": 8, "boolean": true},
                  {"type": 8, "boolean": true}
                ]
              },
              {
                "type": 3,
                "mapKey": [
                  {"type": 1, "string": "key"},
                  {"type": 1, "string": "read"},
                  {"type": 1, "string": "write"}
                ],
                "mapValue": [
                  {"type": 1, "string": "obx_click_twclid"},
                  {"type": 8, "boolean": true},
                  {"type": 8, "boolean": true}
                ]
              }
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  },
  {
    "instance": {
      "key": {
        "publicId": "write_data_layer",
        "versionId": "1"
      },
      "param": [
        {
          "key": "keyPatterns",
          "value": {
            "type": 2,
            "listItem": [
              {"type": 1, "string": "event"},
              {"type": 1, "string": "click_ids"},
              {"type": 1, "string": "click_ids.*"},
              {"type": 1, "string": "gclid"},
              {"type": 1, "string": "gbraid"},
              {"type": 1, "string": "wbraid"},
              {"type": 1, "string": "fbclid"},
              {"type": 1, "string": "fbc"},
              {"type": 1, "string": "msclkid"},
              {"type": 1, "string": "ttclid"},
              {"type": 1, "string": "rdtclid"},
              {"type": 1, "string": "li_fat_id"},
              {"type": 1, "string": "twclid"}
            ]
          }
        }
      ]
    },
    "clientAnnotations": {
      "isEditedByUser": true
    },
    "isRequired": true
  }
]


___TESTS___

scenarios: []


___NOTES___

OBx Click ID Capture v1.0
Built for OuterBox sGTM migration playbook.
Captures: gclid, gbraid, wbraid, fbclid, msclkid, ttclid, rdtclid, li_fat_id, twclid
Special handling: fbclid auto-generates Meta _fbc value (fb.1.{timestamp}.{fbclid})
Storage: First-party cookies + localStorage backup (ITP recovery)
Output: dataLayer push 'click_ids_ready' with all captured IDs

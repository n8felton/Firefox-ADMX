Notice:
Firefox 60 will feature a new component named Policy Engine that will provide GPO support on Windows, allowing system administrators to control Firefox instances deployed across an internal network.

Work on this feature has been progressing according to plan, and its launch is still scheduled for Firefox 60 — Firefox ESR 60 version, as well. According to a Mozilla Firefox release calendar, Firefox 60 is scheduled for release on May 8, 2018.

Because of this, further work on this project will be canceled.  This project will be frozen until after Firefox 60 is released.  Until then, this project will be available to assist with currently available versions of Firefox.

 
 # Installation

## ADMX Templates
To install the Firefox ADMX templates, copy the contents of the `ADMX` folder into `\\ad.domain.example.com\SYSVOL\ad.domain.example.com\Policies\Policy Definitions`

## firefox_startup.vbs
In order for the polices you set to apply, you need to add the `firefox_start.vbs` script to the `Computer Configuration > Windows Settings > Scripts > Startup` section of the GPO you are applying to an OU.

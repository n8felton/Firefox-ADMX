# Project Archived

Now that Mozilla officially supports [Customizing Firefox Using Group Policy on Windows](https://support.mozilla.org/en-US/kb/customizing-firefox-using-group-policy-windows), this project has been archived.

Be sure to check out the [policy templates](https://mozilla.github.io/policy-templates/) and the [latest releases](https://github.com/mozilla/policy-templates/releases).

# Installation

## ADMX Templates
To install the Firefox ADMX templates, copy the contents of the `ADMX` folder into `\\ad.domain.example.com\SYSVOL\ad.domain.example.com\Policies\Policy Definitions`

## firefox_startup.vbs
In order for the polices you set to apply, you need to add the `firefox_start.vbs` script to the `Computer Configuration > Windows Settings > Scripts > Startup` section of the GPO you are applying to an OU.
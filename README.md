# Installation

## ADMX Templates
To install the Firefox ADMX templates, copy the contents of the `ADMX` folder into `\\ad.domain.example.com\SYSVOL\ad.domain.example.com\Policies\Policy Definitions`

## firefox_startup.vbs
In order for the polices you set to apply, you need to add the `firefox_start.vbs` script to the `Computer Configuration > Windows Settings > Scripts > Startup` section of the GPO you are applying to an OU.
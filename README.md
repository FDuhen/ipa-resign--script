# IPA Resign

This script allows you to resign any APK with any certificate.  
It will also increment the build number by 1 (which should be optional I guess but is mandatory for now)

### Prerequisites

You'll need 
- the IPA(s) you want to re-sign 
- the Certificate installed in your keychain (called CertificateName in our example)
- the Provisioning profile  

### Disclamer  

Only native IPAs were re-signed with this script, never tried anything else but it should work fine.

### How to

1) Clone this project.  
2) Put the Provisioning Profile anywhere nearby
3) Execute the signing Script with the following command line  
```
./resign.sh Path/To/IPA.ipa Path/To/MobileProvision.mobileprovision "CertificateName"
```  
4) Optional : If you have multiple IPAs to resign, put them all in the folder of the "automate_resign.sh" and the the following command 
```
./automate_resign.sh Path/To/MobileProvision.mobileprovision "CertificateName"
```  

## Authors

* **Florian DUHEN**
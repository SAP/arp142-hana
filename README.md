# saphana-checks

## How to run

* [Download released version v0.1](https://github.wdf.sap.corp/SAP-COE-HPTI/saphana-checks/releases/download/v0.1/saphana-checks-v0.1.zip) or [latest development](https://github.wdf.sap.corp/SAP-COE-HPTI/saphana-checks/archive/master.zip)
* extract scripts directory to Linux server
* cd scripts/bin
* run ./saphana-check.sh

![Example Output](/docs/Example-Output.png?raw=true "Example Output")

## Commandline options

#### no parameter    (execute all checks) 

``` 
  ./saphana-check.sh
```

#### -c    (execute single checks) 

``` 
  ./saphana-check.sh -c "001_os_kernel_sles 020_ulimit_package"
```
> checks are located within subfolder lib/check - specify without file extention .check


#### -c    (execute checkset) 

``` 
  ./saphana-check.sh -C SLESonX64only
```
> checksets are located within subfolder lib/checkset - specify without file extention .checkset


#### -h    (usage)
```
./saphana-check.sh -h

 USAGE: ./saphana-check.sh [flags]  
 flags:  
 -c,--checks:  <"check1 check2 ...">  A space-separated list of checks that will be performed. (default: '')
 -C,--checkset:  <Checkset>  A textfile containing the various checks to perform. (default: '')
 -l,--loglevel:  notify/silent=0 (always), error=1, warn=2, info=3, debug=5, trace=6 (default: 4)
 -v,--[no]verbose:  enable chk_verbose mode (set loglevel=4) (default: false)
 -d,--[no]debug:  enable debug mode (set loglevel=5) (default: false)
 -t,--[no]trace:  enable trace mode (set loglevel=6) (default: false)
 -h,--help:  show this help (default: false)
```


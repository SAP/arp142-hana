# saphana-checks

Linux OS checks for SAP HANA environments - SLES,RHEL for Intel x64 and IBM Power

## FAQ
Q: Does it work on all linux versions - independend from distributions, kernel, filesystem, hana version?  
A: Yes, checks themselves will verify if they are applicable for environment. However, checks are not complete, eg. filesystems/HANA specifics are not included so far.

Q: Does it change anything on the system?  
A: No, scripts only read data. Nothing is changed or written.

Q: Are there any restrictions attention should be paid to?  
A: Some checks require root permission in order to read certain kernel parameter values. The check suite itself could run as non-root user, but root required checks would be skipped.

## How to run

#### as root user - extract scripts to Linux server & run saphana-check.sh
* download release

* install rpm (installed to /opt/sap/saphana-checks)
```
  rpm -Uvh saphana-checks-*.rpm
```
* just run it or redirect output: 
```
  /opt/sap/saphana-checks/bin/saphana-check.sh
  /opt/sap/saphana-checks/bin/saphana-check.sh 2>&1 | tee -a $(hostname)_SHC.txt
```

![Example Output](/docs/Example-Output.png?raw=true "Example Output")

## Commandline options

#### no parameter    (execute all checks)
```
  ./saphana-check.sh
```

#### -c    (execute single checks)
```
  ./saphana-check.sh -c 0800_sap_host_agent  (single check - fully specified checkname)
  ./saphana-check.sh -c 0800                 (single check - fully specified checkid)
  ./saphana-check.sh -c 08*                  (multiple checks - beginning with 08)
  ./saphana-check.sh -c 0*                   (multiple checks - all checks from category 0)
  ./saphana-check.sh -c 0010,0020            (multiple checks - ids seperated by comma)
  ./saphana-check.sh -c 0010,5*              (combination of above examples)
```
> checks are located within subfolder lib/check - specify without file extention .check


#### -C    (execute checkset)
```
  ./saphana-check.sh -C SLESonX64only
```
> checksets are located within subfolder lib/checkset - specify without file extention .checkset


#### -h    (usage)
```
./saphana-check.sh -h

flags:
  -c,--checks:  <"check1,check2,..."> a comma-separated list of checks that will be performed. (default: '')
  -C,--checkset:  <Checkset> a textfile stored within lib/checkset containing the various checks to perform. (default: '')
  -l,--loglevel:  notify/silent=0 (always), error=1, warn=2, info=3, debug=5, trace=6 (default: 4)
  -v,--[no]verbose:  enable chk_verbose mode (set loglevel=4) (default: false)
  -d,--[no]debug:  enable debug mode (set loglevel=5) (default: false)
  -t,--[no]trace:  enable trace mode (set loglevel=6) (default: false)
  --[no]color:  enable color mode (default: false)
  --[no]timestamp:  show timestamp (default for debug/trace) (default: false)
  -h,--help:  show this help (default: false)

```

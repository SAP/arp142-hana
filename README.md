[![REUSE status](https://api.reuse.software/badge/github.com/SAP/arp142-hana)](https://api.reuse.software/info/github.com/SAP/arp142-hana)

# saphana-checks

Linux OS checks for SAP HANA environments - SLES,RHEL for Intel x64 and IBM Power

## FAQ
Q: Does it work on all linux versions - independend from distributions, kernel, filesystem, hana version?  
A: The tool supports SLES (12.5+) and RHEL (7.9+) on Intel x64 and IBM Power architectures. Early OS validation will block execution on unsupported distributions (Ubuntu, Debian, CentOS, Fedora) and end-of-life OS versions. Individual checks verify if they are applicable for the environment. However, checks are not complete, eg. filesystems/HANA specifics are not included so far.

Q: Does it change anything on the system?  
A: No, scripts only read data. Nothing is changed or written.

Q: Are there any restrictions attention should be paid to?  
A: Some checks require root permission in order to read certain kernel parameter values. The check suite itself could run as non-root user, but root required checks would be skipped.

Q: What happens if I run this on an unsupported OS?  
A: By default, the tool performs early OS validation and will exit with an error if run on unsupported distributions or end-of-life versions (SAP Notes #2235581, #936887). You can bypass this validation using `--skip_os_validation` flag for testing purposes.

## Recent Enhancements

### New Features
- **Early OS Validation**: Automatically blocks execution on unsupported distributions (Ubuntu, Debian, CentOS, Fedora) and end-of-life OS versions
- **OS Override Capability**: New `--os_override` flag allows testing checks against different OS versions without system changes

### Platform Support
- **IBM Power11**: Added support for new S1122, E1150, and E1180 systems on IBM Cloud

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
  --[no]skip_os_validation:  skip early OS validation checks (for testing/backward compatibility) (default: false)
  --os_override:  override detected OS for testing (format: SLES:15.5 or RHEL:9.2) (default: '')
  -h,--help:  show this help (default: false)

```


#### --os_override    (override detected OS for testing)
```
  ./saphana-check.sh --os_override SLES:15.5
  ./saphana-check.sh --os_override RHEL:9.2
```
> Allows testing checks against different OS versions without requiring actual system changes. Format: `<OS_NAME>:<OS_VERSION>` where OS_NAME is SLES, RHEL, or OLS. Warning messages are displayed when override is active.


#### --skip_os_validation    (skip early OS validation)
```
  ./saphana-check.sh --skip_os_validation
```
> Bypasses the early OS validation that blocks execution on unsupported distributions (Ubuntu, Debian, CentOS) or end-of-life OS versions. Useful for testing or backward compatibility scenarios.


## Contribute
Contribution and feedback are encouraged and always welcome. For more information about how to contribute see [SAP's Open Source Project Contribution Guidelines](https://github.com/SAP/.github/blob/main/CONTRIBUTING.md).

## License
Copyright (c) 2016 SAP SE or an SAP affiliate company. All rights reserved.
This file is licensed under the Apache Software License, v. 2 except as noted otherwise in the [LICENSE file](LICENSE).
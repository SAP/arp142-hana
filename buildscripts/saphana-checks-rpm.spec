#both variables passed by rpmbuild comdline
#rpmbuild -v -bb  --define '_version 0.4dev' --define '_release b271_g43d14da4' saphana-checks-rpm.spec
#%define _version        0.4dev
#%define _release        b271_g43d14da4


Name: saphana-checks
Summary: OS checks for SAP HANA landscapes
Version: %{_version}
Release: %{_release}
Group: Applications/System
Vendor: SAP SE - DBS - CoE EMEA HANA Platform & Technical Infrastructure
License: SAP SE
Autoreq: 0
BuildArch: noarch
 
 
%description
Linux configuration checks for HANA OS recommendations - running on SLES,RHEL for Intel x64 and IBM Power

%prep
echo %{buildroot}
echo $RPM_BUILD_ROOT 

%build
exit 0

%clean
exit 0

%install
exit 0
 
%files
/opt/sap/saphana-checks/

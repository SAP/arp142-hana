# both variables passed by rpmbuild comdline
# rpmbuild -v -bb  --define '_version 0.4dev' --define '_release b271_g43d14da4' saphana-checks-rpm.spec
# %%define _version        1.0
# %%define _release        b001_g00000000

Name: saphana-checks
Summary: Linux OS checks for SAP HANA hosts
Version: %{_version}
Release: %{_release}
Group: Applications/System
Vendor: SAP SE - DBS - CoE EMEA HANA Platform & Technical Infrastructure
License: SAP SE
Autoreq: 0
BuildArch: noarch


%description
Check Linux OS configuration recommendations for SAP HANA hosts - running on SLES,RHEL for Intel x64 and IBM Power

%prep
echo %{buildroot}
echo %{_version}
echo %{_release}

%build
exit 0

%clean
exit 0

%install
exit 0

%files
/opt/sap/saphana-checks/

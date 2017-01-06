%global debug_package   %{nil}

# container-selinux
%global git0 https://github.com/projectatomic/container-selinux
%if 0%{?fedora}
%global commit0 513572d0fff7899196d57721ed81577ee3dc8414
%else
%global commit0 a85092bf995b99f26b9be7103345805f846f647c
%endif
%global shortcommit0 %(c=%{commit0}; echo ${c:0:7})

# container-selinux stuff (prefix with ds_ for version/release etc.)
# Some bits borrowed from the openstack-selinux package
%global selinuxtype targeted
%global moduletype services
%global modulenames container

# Usage: _format var format
# Expand 'modulenames' into various formats as needed
# Format must contain '$x' somewhere to do anything useful
%global _format() export %1=""; for x in %{modulenames}; do %1+=%2; %1+=" "; done;

# Relabel files
%global relabel_files() %{_sbindir}/restorecon -R %{_bindir}/docker %{_localstatedir}/run/containerd.sock %{_localstatedir}/run/docker.sock %{_localstatedir}/run/docker.pid %{_sysconfdir}/docker %{_localstatedir}/log/docker %{_localstatedir}/log/lxc %{_localstatedir}/lock/lxc %{_unitdir}/docker.service %{_unitdir}/docker-containerd.service %{_sysconfdir}/docker %{_libexecdir}/docker &> /dev/null || :

# Version of SELinux we were using
%if 0%{?fedora} >= 22
%global selinux_policyver 3.13.1-220
%else
%global selinux_policyver 3.13.1-39
%endif

Name: container-selinux
%if 0%{?fedora} || 0%{?centos}
Epoch: 2
%endif
Version: 2.0
Release: 1%{?dist}
License: GPLv2
URL: %{git0}
Summary: SELinux policies for container runtimes
Source0: %{git0}/archive/%{commit0}/%{name}-%{shortcommit0}.tar.gz
BuildArch: noarch
BuildRequires: git
BuildRequires: pkgconfig(systemd)

# RE: rhbz#1195804 - ensure min NVR for selinux-policy
Requires: selinux-policy >= %{selinux_policyver}

BuildRequires: selinux-policy
BuildRequires: selinux-policy-devel
Requires(post): selinux-policy-base >= %{selinux_policyver}
Requires(post): policycoreutils
%if 0%{?fedora}
Requires(post): policycoreutils-python-utils
%else
Requires(post): policycoreutils-python
%endif
Requires(post): libselinux-utils
Obsoletes: %{name} <= 2:1.12.5-13
Obsoletes: docker-selinux <= 2:1.12.4-28
Provides: docker-selinux = %{epoch}:%{version}-%{release}

%description
SELinux policy modules for use with container runtimes.

%prep
%autosetup -Sgit -n %{name}-%{commit0}

%build
make

%install
# install policy modules
%_format MODULES $x.pp.bz2
install -d %{buildroot}%{_datadir}/selinux/packages
install -d -p %{buildroot}%{_datadir}/selinux/devel/include/services
install -p -m 644 container.if %{buildroot}%{_datadir}/selinux/devel/include/services
install -m 0644 $MODULES %{buildroot}%{_datadir}/selinux/packages

# remove %%{repo}-selinux rpm spec file
rm -rf container-selinux.spec

%check

%post
# Install all modules in a single transaction
if [ $1 -eq 1 ]; then
    %{_sbindir}/setsebool -P -N virt_use_nfs=1 virt_sandbox_use_all_caps=1
fi
%_format MODULES %{_datadir}/selinux/packages/$x.pp.bz2
%{_sbindir}/semodule -n -s %{selinuxtype} -r container 2> /dev/null
%{_sbindir}/semodule -n -s %{selinuxtype} -d %{repo} 2> /dev/null
%{_sbindir}/semodule -n -s %{selinuxtype} -d gear 2> /dev/null
%{_sbindir}/semodule -n -X 200 -s %{selinuxtype} -i $MODULES > /dev/null
if %{_sbindir}/selinuxenabled ; then
    %{_sbindir}/load_policy
    %relabel_files
    if [ $1 -eq 1 ]; then
	restorecon -R %{_sharedstatedir}/%{repo} &> /dev/null || :
    fi
fi

%postun
if [ $1 -eq 0 ]; then
%{_sbindir}/semodule -n -r %{modulenames} docker &> /dev/null || :
if %{_sbindir}/selinuxenabled ; then
%{_sbindir}/load_policy
%relabel_files
fi
fi

#define license tag if not already defined
%{!?_licensedir:%global license %doc}

%files
%doc README.md
%{_datadir}/selinux/*

%changelog
* Fri Jan 06 2017 Lokesh Mandvekar <lsm5@fedoraproject.org> - 2:2.0-1
- Resolves: #1406517 - bump to v2.0 (first upload to Fedora as a
standalone package)
- include projectatomic/RHEL-1.12 branch commit for building on centos/rhel

* Mon Dec 19 2016 Lokesh Mandvekar <lsm5@fedoraproject.org> - 2:1.12.4-29
- new package (separated from docker)

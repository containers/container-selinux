%global debug_package %{nil}

# container-selinux stuff (prefix with ds_ for version/release etc.)
# Some bits borrowed from the openstack-selinux package
%global selinuxtype targeted
%global moduletype services
%global modulenames container

# Usage: _format var format
# Expand 'modulenames' into various formats as needed
# Format must contain '$x' somewhere to do anything useful
%global _format() export %1=""; for x in %{modulenames}; do %1+=%2; %1+=" "; done;

# RHEL < 10 and Fedora < 40 use file context entries in /var/run
%if %{defined rhel} && 0%{?rhel} < 10 || %{defined fedora} && 0%{?fedora} < 40
%define legacy_var_run 1
%endif

# https://github.com/containers/container-selinux/issues/203
%if %{!defined fedora} && %{!defined rhel} || %{defined rhel} && 0%{?rhel} <= 9
%define no_user_namespace 1
%endif

# copr_build is more intuitive than copr_username
%if %{defined copr_username}
%define copr_build 1
%endif

Name: container-selinux
# Set different Epochs for copr and koji
%if %{defined copr_build}
Epoch: 102
%else
Epoch: 2
%endif
# Keep Version in upstream specfile at 0. It will be automatically set
# to the correct value by Packit for copr and koji builds.
# IGNORE this comment if you're looking at it in dist-git.
Version: 0
Release: %autorelease
License: GPL-2.0-only
URL: https://github.com/containers/%{name}
Summary: SELinux policies for container runtimes
Source0: %{url}/archive/v%{version}.tar.gz
BuildArch: noarch
BuildRequires: make
BuildRequires: git-core
BuildRequires: pkgconfig(systemd)
BuildRequires: selinux-policy >= %_selinux_policy_version
BuildRequires: selinux-policy-devel >= %_selinux_policy_version
# RE: rhbz#1195804 - ensure min NVR for selinux-policy
Requires: selinux-policy >= %_selinux_policy_version
Requires(post): selinux-policy-base >= %_selinux_policy_version
Requires(post): selinux-policy-targeted >= %_selinux_policy_version
Requires(post): policycoreutils
Requires(post): libselinux-utils
Requires(post): sed
Obsoletes: %{name} <= 2:1.12.5-13
Obsoletes: docker-selinux <= 2:1.12.4-28
Provides: docker-selinux = %{?epoch:%{epoch}:}%{version}-%{release}
Conflicts: udica < 0.2.6-1
Conflicts: k3s-selinux <= 0.4-1

%description
SELinux policy modules for use with container runtimes.

%prep
%autosetup -Sgit %{name}-%{version}

sed -i 's/^man: install-policy/man:/' Makefile
sed -i 's/^install: man/install:/' Makefile

%if %{defined no_user_namespace}
sed -i '/user_namespace/d' container.te
%endif

%if %{defined legacy_var_run}
sed -i 's|^/run/|/var/run/|' container.fc
%endif

%build
make

%install
# install policy modules
%_format MODULES $x.pp.bz2
%{__make} DATADIR=%{buildroot}%{_datadir} SYSCONFDIR=%{buildroot}%{_sysconfdir} install install.udica-templates install.selinux-user

# Ref: https://bugzilla.redhat.com/show_bug.cgi?id=2209120
rm %{buildroot}%{_mandir}/man8/container_selinux.8

%pre
%selinux_relabel_pre -s %{selinuxtype}

%post
# Install all modules in a single transaction
if [ $1 -eq 1 ]; then
   %{_sbindir}/setsebool -P -N virt_use_nfs=1 virt_sandbox_use_all_caps=1
fi
%_format MODULES %{_datadir}/selinux/packages/$x.pp.bz2
%{_sbindir}/semodule -n -s %{selinuxtype} -r container 2> /dev/null
%{_sbindir}/semodule -n -s %{selinuxtype} -d docker 2> /dev/null
%{_sbindir}/semodule -n -s %{selinuxtype} -d gear 2> /dev/null
%selinux_modules_install -s %{selinuxtype} $MODULES
. %{_sysconfdir}/selinux/config
sed -e "\|container_file_t|h; \${x;s|container_file_t||;{g;t};a\\" -e "container_file_t" -e "}" -i /etc/selinux/${SELINUXTYPE}/contexts/customizable_types
matchpathcon -qV %{_sharedstatedir}/containers || restorecon -R %{_sharedstatedir}/containers &> /dev/null || :

%postun
if [ $1 -eq 0 ]; then
   %selinux_modules_uninstall -s %{selinuxtype} %{modulenames} docker
fi

%posttrans
%selinux_relabel_post -s %{selinuxtype}

#define license tag if not already defined
%{!?_licensedir:%global license %doc}

%files
%doc README.md
%{_datadir}/selinux/*
%dir %{_datadir}/containers/selinux
%{_datadir}/containers/selinux/contexts
%dir %{_datadir}/udica/templates/
%{_datadir}/udica/templates/*
# Ref: https://bugzilla.redhat.com/show_bug.cgi?id=2209120
#%%{_mandir}/man8/container_selinux.8.gz
%{_sysconfdir}/selinux/targeted/contexts/users/*
%ghost %{_sharedstatedir}/selinux/%{selinuxtype}/active/modules/200/%{modulenames}

%triggerpostun -- container-selinux < 2:2.162.1-3
if %{_sbindir}/selinuxenabled ; then
    echo "Fixing Rootless SELinux labels in homedir"
    %{_sbindir}/restorecon -R /home/*/.local/share/containers/storage/overlay*  2> /dev/null
fi

%changelog
%if %{defined autochangelog}
%autochangelog
%else
# NOTE: This changelog will be visible on CentOS 8 Stream builds
# Other envs are capable of handling autochangelog
* Tue Jun 13 2023 RH Container Bot <rhcontainerbot@fedoraproject.org>
- Placeholder changelog for envs that are not autochangelog-ready.
- Contact upstream if you need to report an issue with the build.
%endif

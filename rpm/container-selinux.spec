%global debug_package %{nil}

# container-selinux upstream
%global git0 https://github.com/containers/container-selinux

# container-selinux stuff (prefix with ds_ for version/release etc.)
# Some bits borrowed from the openstack-selinux package
%global selinuxtype targeted
%global moduletype services
%global modulenames container

# Usage: _format var format
# Expand 'modulenames' into various formats as needed
# Format must contain '$x' somewhere to do anything useful
%global _format() export %1=""; for x in %{modulenames}; do %1+=%2; %1+=" "; done;

# copr_username is only set on copr environments, not on others like koji
%if "%{?copr_username}" != "rhcontainerbot"
%bcond_with copr
%else
%bcond_without copr
%endif

# RHEL 8 doesn't allow watch and systemd_chat_resolved
%if 0%{?rhel} == 8
%bcond_without no_watch
%bcond_without no_systemd_chat_resolved
%else
%bcond_with no_watch
%bcond_with no_systemd_chat_resolved
%endif

# https://github.com/containers/container-selinux/issues/203
%if 0%{?fedora} <= 37 || 0%{?rhel} <= 9
%bcond_without no_user_namespace
%else
%bcond_with no_user_namespace
%endif

Name: container-selinux
# Set different Epochs for copr and koji
%if %{with copr}
Epoch: 101
%else
Epoch: 2
%endif
# Keep Version in upstream specfile at 0. It will be automatically set
# to the correct value by Packit for copr and koji builds.
# IGNORE this comment if you're looking at it in dist-git.
Version: 0
Release: %autorelease
License: GPL-2.0-only
URL: %{git0}
Summary: SELinux policies for container runtimes
Source0: %{git0}/archive/v%{version}.tar.gz
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

%if %{with no_watch}
sed -i 's/watch watch_reads//' container.if
sed -i 's/watch watch_reads//' container.te
sed -i '/sysfs_t:dir watch/d' container.te
%endif

%if %{with no_systemd_chat_resolved}
sed -i '/^systemd_chat_resolved/d' container.te
%endif

%if %{with no_user_namespace}
sed -i '/user_namespace/d' container.te
%endif

%build
make

%install
# install policy modules
%_format MODULES $x.pp.bz2
%{__make} DATADIR=%{buildroot}%{_datadir} SYSCONFDIR=%{buildroot}%{_sysconfdir} install install.udica-templates install.selinux-user

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
%{_mandir}/man8/container_selinux.8.gz
%{_sysconfdir}/selinux/targeted/contexts/users/*
%ghost %{_sharedstatedir}/selinux/%{selinuxtype}/active/modules/200/%{modulenames}

%triggerpostun -- container-selinux < 2:2.162.1-3
if %{_sbindir}/selinuxenabled ; then
    echo "Fixing Rootless SELinux labels in homedir"
    %{_sbindir}/restorecon -R /home/*/.local/share/containers/storage/overlay*  2> /dev/null
fi

%changelog
%if 0%{?centos} <= 8
* Mon May 01 2023 RH Container Bot <rhcontainerbot@fedoraproject.org>
- Dummy changelog for CentOS Stream 8
%else
%autochangelog
%endif

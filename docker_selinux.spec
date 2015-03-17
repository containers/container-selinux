# vim: sw=4:ts=4:et
%define selinux_policyver 3.13.1-101

Name:   docker_selinux
Version:	1.0
Release:	1%{?dist}
Summary:	SELinux policy module for docker

Group:	System Environment/Base		
License:	GPLv2+	
# This is an example. You will need to change it.
URL:		http://HOSTNAME
Source0:	docker.pp
Source1:	docker.if
Source2:	docker_selinux.8


Requires: policycoreutils, libselinux-utils
Requires(post): selinux-policy-base >= %{selinux_policyver}, policycoreutils
Requires(postun): policycoreutils
Requires(post): docker
BuildArch: noarch

%description
This package installs and sets up the  SELinux policy security module for docker.

%install
install -d %{buildroot}%{_datadir}/selinux/packages
install -m 644 %{SOURCE0} %{buildroot}%{_datadir}/selinux/packages
install -d %{buildroot}%{_datadir}/selinux/devel/include/contrib
install -m 644 %{SOURCE1} %{buildroot}%{_datadir}/selinux/devel/include/contrib/
install -d %{buildroot}%{_mandir}/man8/
install -m 644 %{SOURCE2} %{buildroot}%{_mandir}/man8/docker_selinux.8
install -d %{buildroot}/etc/selinux/targeted/contexts/users/


%post
semodule -n -i %{_datadir}/selinux/packages/docker.pp
if /usr/sbin/selinuxenabled ; then
    /usr/sbin/load_policy
    %relabel_files

fi;
exit 0

%postun
if [ $1 -eq 0 ]; then
    semodule -n -r docker
    if /usr/sbin/selinuxenabled ; then
       /usr/sbin/load_policy
       %relabel_files
    fi;
fi;
exit 0

%files
%attr(0600,root,root) %{_datadir}/selinux/packages/docker.pp
%{_datadir}/selinux/devel/include/contrib/docker.if
%{_mandir}/man8/docker_selinux.8.*

%changelog
* Tue Mar  17 2015 Dan Walsh <dwalsh@redhat.com> 1.0-1
- Initial version


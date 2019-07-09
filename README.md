# SELinux Policy for Container Runtimes

## Blogs on SELinux Policy

**[Docker and SELinux](https://www.projectatomic.io/docs/docker-and-selinux/)**  
Interaction between SELinux policy and Docker

**[Issues with Docker Volumes and SELinux](https://www.projectatomic.io/blog/2015/06/using-volumes-with-docker-can-cause-problems-with-selinux/  )**  
Use of volume mounted content with SELinux

**[Docker SELinux Flag](https://www.projectatomic.io/blog/2016/07/docker-selinux-flag/)**  
Information on `–selinux-enabled` flag in Docker daemon

**[SELinux Policy for Containers](https://www.projectatomic.io/blog/2017/02/selinux-policy-containers/)**  
Tightening of SELinux policy to prevent information leaks

**[Extending SELinux Policy for Containers](https://www.projectatomic.io/blog/2016/03/selinux-and-docker-part-2/)**  
Policy module for running containers as securely as possible

**[Practical SELinux and Containers](https://www.projectatomic.io/blog/2016/03/dwalsh_selinux_containers/)**  
How to make SELinux and containers work well together with best security separation

**[`no-new-privileges` Security Flag in Docker ](https://www.projectatomic.io/blog/2016/03/no-new-privs-docker/)**  
Explains `--no-new-privileges` flag usage

**[Container Labeling](https://danwalsh.livejournal.com/81269.html)**  
Explains `container_t` vs c`ontainer_var_lib_t`

**[`container_t` versus `svirt_lxc_net_t`](https://danwalsh.livejournal.com/79191.html)**  
Clarifys `container_t` versus `svirt_lxc_net_t` aliases

**[SELinux, Podman, and Libvert](https://danwalsh.livejournal.com/81143.html)**  
Information regarding SELinux blocking Podman container from talking to Libvirt

**[Caution Relabeling Volumes with Container Runtimes](https://danwalsh.livejournal.com/76016.html)**  
Explains effects of relabeling volumes with `:Z`

**[Container Domains (Types)](https://danwalsh.livejournal.com/81756.html)**  
Explanation of SELinux Domain types.

**[Containers and MLS](https://danwalsh.livejournal.com/77830.html)**  
Container-selinux policy support of MLS (Multi Level Security).  

.PHONY: basic_check
basic_check:
	semodule --list=full | grep container
	semodule -B

.PHONY: podman_e2e_test
podman_e2e_test:
	bash ./podman-tests.sh e2e

.PHONY: podman_system_test
podman_system_test:
	bash ./podman-tests.sh system

clean:
	rm -rf podman-*dev* podman.spec

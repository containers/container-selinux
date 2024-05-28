.PHONY: basic_check
basic_check:
	semodule --list=full | grep container
	semodule -B

.PHONY: podman_e2e_test_upstream
podman_e2e_test_upstream:
	bash ./podman-tests.sh e2e upstream

.PHONY: podman_e2e_test_downstream
podman_e2e_test_downstream:
	bash ./podman-tests.sh e2e downstream

.PHONY: podman_system_test_upstream
podman_system_test_upstream:
	bash ./podman-tests.sh system upstream

.PHONY: podman_system_test_downstream
podman_system_test_downstream:
	bash ./podman-tests.sh system downstream

clean:
	rm -rf podman-*dev* podman.spec

# Variables
ENDPOINT ?=
API_ADDRESS ?= $(ENDPOINT)
TOKEN ?=
CERTHASH ?=
NODE_LABELS ?= net.mcserverhosting.node/ephemeral=true,kubernetes.io/os=MCSH

NTP_SERVER_IP = 192.168.67.1

# Kernel version to use
LINUX ?= linux-lts

# Feature levels
FEATURE_LEVELS = x86-64-v3

# Kubernetes version
K8S_VERSION ?= $(shell curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt | tr -d 'v')

# Packages
NVIDIA_PACKAGES_LIST = nvidia-dkms nvidia-container-toolkit
AMD_PACKAGES_LIST = amdgpu-pro-installer-debug rocm-hip-sdk rocm-opencl-sdk radeontop
UNIX_TOOLS_LIST = openssh nano vim vi curl wget htop bpytop btop


ENABLE_NVIDIA ?= 0
ENABLE_AMD ?= 0

# Kernel modules to load
KERNEL_MODULES = br_netfilter ip6_tables ip_tables ip6table_mangle ip6table_raw ip6table_filter xt_socket erofs

# Paths
OUTPUT_DIR = baseline/airootfs/usr/local/bin

INCLUDE_OPENSSH = $(shell grep -w 'openssh' baseline/packages.x86_64 >/dev/null && echo 1 || echo 0)

all: template-linux template-kubeadm ssh-keys package-list init-script ntp-conf $(addprefix build-iso-,$(FEATURE_LEVELS))


# Process kubeadm.conf.yaml.template
template-kubeadm:
	@echo "Templating kubeadm.conf.yaml with provided variables."
	@cp baseline/airootfs/etc/kubeadm/kubeadm.conf.yaml.template baseline/airootfs/etc/kubeadm/kubeadm.conf.yaml
	@if [ -n "$(API_ADDRESS)" ]; then \
	  sed -i 's|{{API_ADDRESS}}|$(API_ADDRESS)|g' baseline/airootfs/etc/kubeadm/kubeadm.conf.yaml; \
	else \
	  echo "No API_ADDRESS provided; leaving placeholder for runtime substitution."; \
	fi
	@if [ -n "$(TOKEN)" ]; then \
	  sed -i 's|{{TOKEN}}|$(TOKEN)|g' baseline/airootfs/etc/kubeadm/kubeadm.conf.yaml; \
	else \
	  echo "No TOKEN provided; leaving placeholder for runtime substitution."; \
	fi
	@if [ -n "$(CERTHASH)" ]; then \
	  sed -i 's|{{CERT_HASH}}|$(CERTHASH)|g' baseline/airootfs/etc/kubeadm/kubeadm.conf.yaml; \
	else \
	  echo "No CERTHASH provided; leaving placeholder for runtime substitution."; \
	fi
	@sed -i 's|{{NODE_LABELS}}|$(NODE_LABELS)|g' baseline/airootfs/etc/kubeadm/kubeadm.conf.yaml

# Generate package list based on enabled features
package-list:
	@echo "Generating package list..."
	@( \
		export LINUX="$(LINUX)"; \
		if [ "$(ENABLE_NVIDIA)" -eq "1" ]; then \
		  NVIDIA_PACKAGES="$$(printf '%s\n' $(NVIDIA_PACKAGES_LIST))"; \
		else \
		  NVIDIA_PACKAGES=""; \
		fi; \
		if [ "$(ENABLE_AMD)" -eq "1" ]; then \
		  AMD_PACKAGES="$$(printf '%s\n' $(AMD_PACKAGES_LIST))"; \
		else \
		  AMD_PACKAGES=""; \
		fi; \
		UNIX_TOOLS="$$(printf '%s\n' $(UNIX_TOOLS_LIST))"; \
		export NVIDIA_PACKAGES; \
		export AMD_PACKAGES; \
		export UNIX_TOOLS; \
		envsubst < baseline/packages.x86_64.template > baseline/packages.x86_64; \
	)

# Ensure SSH keys have correct permissions
ssh-keys:
	@if [ -d baseline/airootfs/root/.ssh ]; then \
	  chmod 700 baseline/airootfs/root/.ssh; \
	  if [ -f baseline/airootfs/root/.ssh/authorized_keys ]; then \
	    chmod 600 baseline/airootfs/root/.ssh/authorized_keys; \
	  fi; \
	fi

# Generate init.sh with modprobe commands and conditional SSH
init-script:
	@echo "Generating init.sh with modprobe commands and SSH configuration..."
	@cp baseline/airootfs/root/init.sh.template baseline/airootfs/root/init.sh
	@sed -i '/# Load Kernel modules/a \
$(foreach module,$(KERNEL_MODULES),modprobe $(module);)' baseline/airootfs/root/init.sh
	@if [ "$(INCLUDE_OPENSSH)" -eq "1" ]; then \
	  echo "Enabling SSH in init script..."; \
	  sed -i 's|#ENABLE_SSH||' baseline/airootfs/root/init.sh; \
	else \
	  echo "SSH will not be enabled as openssh is not included."; \
	  sed -i '/#ENABLE_SSH/d' baseline/airootfs/root/init.sh; \
	fi
	@chmod +x baseline/airootfs/root/init.sh

# Update ntp.conf with the specified NTP server IP
ntp-conf:
	@echo "Configuring ntp.conf..."
	@sed -i 's|^server .*|server $(NTP_SERVER_IP)|' baseline/airootfs/etc/ntp.conf

# Process all .template files
template-linux:
	@echo "Templating files with LINUX=$(LINUX) and FEATURE_LEVEL=$(FEATURE_LEVEL)"
	@find baseline -type f -name "*.template" | while read template; do \
	  target="$${template%.template}"; \
	  echo "Processing $$template -> $$target"; \
	  sed 's|{{LINUX}}|$(LINUX)|g; s|{{FEATURE_LEVEL}}|$(FEATURE_LEVEL)|g' "$$template" > "$$target"; \
	done

# Process pacman.conf.template to generate pacman.conf
pacman-conf:
	@echo "Templating pacman.conf with FEATURE_LEVEL=$(FEATURE_LEVEL)"
	@sed 's|{{FEATURE_LEVEL}}|$(FEATURE_LEVEL)|g' baseline/pacman.conf.template > baseline/pacman.conf

# Build ISO for each feature level
$(addprefix build-iso-,$(FEATURE_LEVELS)):
	@echo "Building ISO for feature level: $(@:build-iso-%=%)"
	@$(MAKE) build-iso FEATURE_LEVEL=$(@:build-iso-%=%)

# Build the ISO using Docker
build-iso: pacman-conf
	@echo "Building ISO for FEATURE_LEVEL=$(FEATURE_LEVEL)"
	# Ensure the pacman.conf has the correct Architecture
	@mkdir -p baseline/out/tmp
	@mkarchiso -v -w /tmp/mkarchiso -o baseline/out/tmp baseline -quiet=y
	@mv baseline/out/tmp/*.iso baseline/out/MCSHOS-$(K8S_VERSION)-$(FEATURE_LEVEL).iso
	@rm -rf /tmp/mkarchiso/*
	@rm -rf /var/cache/pacman

# Clean target
clean:
	rm -rf baseline/out/*.iso

# Phony targets
.PHONY: all clean build-iso $(addprefix build-iso-,$(FEATURE_LEVELS))

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
FEATURE_LEVELS = x86-64-v2 x86-64-v3 x86-64-v4

# Kubernetes version
K8S_VERSION ?= $(shell curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt | tr -d 'v')

NVIDIA_PACKAGES = nvidia-dkms nvidia-container-toolkit
AMD_PACKAGES = amdgpu-pro-installer-debug rocm-hip-sdk rocm-opencl-sdk radeontop
UNIX_TOOLS = openssh nano vim vi curl wget htop bpytop btop

ENABLE_NVIDIA ?= 0
ENABLE_AMD ?= 0

# Kernel modules to load
KERNEL_MODULES = br_netfilter ip6_tables ip_tables ip6table_mangle ip6table_raw ip6table_filter xt_socket erofs

# Paths
OUTPUT_DIR = baseline/airootfs/usr/local/bin

INCLUDE_OPENSSH := $(shell grep -w 'openssh' baseline/packages.x86_64 >/dev/null && echo 1 || echo 0)

# Ensure init.sh is executable
permissions:
	@chmod +x baseline/airootfs/root/init.sh

all: template-linux template-kubeadm permissions ssh-keys package-list init-script ntp-conf $(addprefix build-iso-,$(FEATURE_LEVELS))

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
	@cp baseline/packages.x86_64.template baseline/packages.x86_64
	@if [ "$(ENABLE_NVIDIA)" -eq "1" ]; then \
	  echo "Including NVIDIA packages: $(NVIDIA_PACKAGES)"; \
	  sed -i 's|{{NVIDIA_PACKAGES}}|$(NVIDIA_PACKAGES)|' baseline/packages.x86_64; \
	else \
	  sed -i '/{{NVIDIA_PACKAGES}}/d' baseline/packages.x86_64; \
	fi
	@if [ "$(ENABLE_AMD)" -eq "1" ]; then \
	  echo "Including AMD packages: $(AMD_PACKAGES)"; \
	  sed -i 's|{{AMD_PACKAGES}}|$(AMD_PACKAGES)|' baseline/packages.x86_64; \
	else \
	  sed -i '/{{AMD_PACKAGES}}/d' baseline/packages.x86_64; \
	fi
	@echo "Including UNIX tools: $(UNIX_TOOLS)"
	@sed -i 's|{{UNIX_TOOLS}}|$(UNIX_TOOLS)|' baseline/packages.x86_64

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

# Process template files to replace {{LINUX}} with the actual kernel package name
template-linux:
	@echo "Templating files with LINUX=$(LINUX)"
	@find baseline -type f -name "*.template" | while read template; do \
	  target="$${template%.template}"; \
	  echo "Processing $$template -> $$target"; \
	  sed 's|{{LINUX}}|$(LINUX)|g' "$$template" > "$$target"; \
	done

# Build ISO for each feature level
$(addprefix build-iso-,$(FEATURE_LEVELS)):
	@echo "Building ISO for feature level: $(@:build-iso-%=%)"
	@$(MAKE) build-iso FEATURE_LEVEL=$(@:build-iso-%=%)

# Build the ISO using Docker
build-iso:
	@echo "Building ISO for FEATURE_LEVEL=$(FEATURE_LEVEL)"
	@sed -i 's/^Architecture = .*$$/Architecture = $(FEATURE_LEVEL)/' baseline/pacman.conf
	@mkarchiso -v -w /tmp -o baseline/out baseline -quiet=y
	@mv baseline/out/*.iso baseline/out/MCSHOS-$(K8S_VERSION)-$(FEATURE_LEVEL).iso


# Clean target
clean:
	rm -rf baseline/out/*.iso

# Phony targets
.PHONY: all clean build-iso $(addprefix build-iso-,$(FEATURE_LEVELS))
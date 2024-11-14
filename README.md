# MCSH-OS

![Splash Image](https://github.com/mcserverhosting-net/OS/blob/main/baseline/syslinux/splash.png?raw=true)

Welcome to the MCSH-OS project! This ISO provides a ready-to-use, ephemeral Arch Linux-based system designed to automatically join a Kubernetes cluster on boot. It simplifies scaling your Kubernetes cluster with minimal effort and customization.

## Table of Contents

- [MCSH-OS](#mcsh-os)
  - [Table of Contents](#table-of-contents)
  - [Overview](#overview)
  - [Features](#features)
  - [Usage](#usage)
    - [Quick Start](#quick-start)
    - [DHCP Options for Auto-Join](#dhcp-options-for-auto-join)
      - [Example ISC DHCP Server Configuration](#example-isc-dhcp-server-configuration)
  - [Customization](#customization)
    - [Building from Prebuilt Docker Image](#building-from-prebuilt-docker-image)
    - [Enabling NVIDIA or AMD Packages](#enabling-nvidia-or-amd-packages)
    - [Customizing Packages](#customizing-packages)
    - [Kernel Modules](#kernel-modules)
    - [NTP Configuration](#ntp-configuration)
  - [Feature Levels](#feature-levels)
  - [Contributing](#contributing)
  - [License](#license)
  - [Original Reddit Post](#original-reddit-post)

## Overview

This project provides a lightweight, customizable ISO for quickly adding worker nodes to a Kubernetes cluster. By booting from this ISO, nodes can automatically join a cluster using predefined values from an HTTP server, eliminating the need for manual configuration.

Originally developed by our hosting service to manage nodes at scale, this ISO is ideal for environments where ephemeral worker nodes are beneficial, such as test clusters, CI/CD pipelines, or dynamic scaling scenarios.

## Features

- **Automatic Kubernetes Cluster Join**: Nodes booting from the ISO automatically join your Kubernetes cluster using DHCP-provided configurations.

- **Ephemeral Nodes**: Designed for stateless, ephemeral nodes that can be easily restarted or replaced.

- **Multiple x86-64 Feature Levels**: Optimized for `x86-64-v2`, `x86-64-v3`, and `x86-64-v4` architectures for improved performance.

- **Optional NVIDIA and AMD Support**: Include NVIDIA or AMD packages to support GPU workloads.

- **Customizable**: Build your own ISO using the provided Docker image and Makefile for full customization.

- **Lightweight**: The default ISO is approximately 800MB; with NVIDIA packages, it is around 1.4GB.

## Usage

### Quick Start

You don't need to build the ISO yourself unless you want to customize it. You can download the latest prebuilt ISO from the [Releases](https://github.com/mcserverhosting-net/OS/releases) page. (We currently cannot build v4, you'll have to do that yourself)

1. **Download the ISO**:

   Visit the [Releases](https://github.com/mcserverhosting-net/OS/releases) page and download the latest ISO artifact.

2. **Set Up HTTP Options**:

   Configure an HTTP server to provide the necessary options for the nodes to auto-join your Kubernetes cluster. See [HTTP Options for Auto-Join](#http-options-for-auto-join) below.

3. **Boot the Node**:

   Boot your machine using the downloaded ISO (via USB, PXE, or virtual machine). The node will automatically format the first available disk, load necessary kernel modules, and join your Kubernetes cluster.

### HTTP Options for Auto-Join

To enable nodes to automatically join your Kubernetes cluster, configure your HTTP server to have the following files:

| Path | Name                        | Description                                                |
|-------------|-----------------------------|------------------------------------------------------------|
| /token       | Token                | The token for kubeadm join.                                   |
| /apiServerEndpoint      | API Server Endpoint                     | The API Address and port for your kubernetes cluster.                             |
| /certHash       | CA Cert Hash        | The CA Cert Hash for your cluster.                                         |
## Customization

### Building from Prebuilt Docker Image

If you wish to customize the ISO, you can build it yourself using the prebuilt Docker image provided.

1. **Clone the Repository**:

```bash
git clone https://github.com/mcserverhosting-net/OS.git
cd OS
```

2. **Build the ISO**:

```bash
docker run --privileged
    -v $(pwd):/workspace
    ghcr.io/mcserverhosting-net/os:latest
    make clean && make
```
   This command uses the prebuilt Docker image `ghcr.io/mcserverhosting-net/os:latest` to build the ISO inside a container.

3. **Find Your ISO**:

   The generated ISO files will be located in the `baseline/out/` directory.

### Enabling NVIDIA or AMD Packages

To include NVIDIA or AMD packages in your custom ISO, set the `ENABLE_NVIDIA` or `ENABLE_AMD` environment variable when running `make`.

- **Enable NVIDIA Packages**:

```bash
make ENABLE_NVIDIA=1
```

- **Enable AMD Packages**:

```bash
make ENABLE_AMD=1
```

### Customizing Packages

Edit the `packages.x86_64.template` file in the `baseline/` directory to add or remove packages according to your needs.

- **Add Packages**: Add package names to the list in `packages.x86_64.template`.

- **Remove Packages**: Comment out or delete package names from the list.

### Kernel Modules

Specify the kernel modules to load during boot by modifying the `KERNEL_MODULES_LIST` variable in the `Makefile`.

```makefile
KERNEL_MODULES_LIST = br_netfilter ip6_tables ip_tables ip6table_mangle ip6table_raw ip6table_filter xt_socket erofs
```

### NTP Configuration

Set your NTP server IP address in the `Makefile`:

```makefile
NTP_SERVER_IP = your.ntp.server.ip
```

## Feature Levels

This project references [ALHP.GO](https://somegit.dev/ALHP/ALHP.GO), which provides Arch Linux packages optimized with different x86-64 feature levels, `-O3` optimizations, and LTO (Link Time Optimization). You can build ISOs optimized for different CPU architectures:

- **x86-64-v2**: For CPUs supporting SSE3 and other basic extensions.
- **x86-64-v3**: For CPUs with AVX, AVX2, and FMA3 instructions.
- **x86-64-v4**: For the latest CPUs supporting AVX512 instructions.

To build an ISO for a specific feature level, set the `FEATURE_LEVEL` variable:

```bash
make FEATURE_LEVEL=x86-64-v4
```

## Contributing

Contributions are welcome! If you have improvements or bug fixes, please open an issue or submit a pull request.

## License

This project is licensed under the GNU GENERAL PUBLIC LICENSE. See the [LICENSE](LICENSE) file for details.

## Original Reddit Post

For historical context, this project was announced on [Reddit](https://www.reddit.com/r/kubernetes/comments/zjk605/releasing_our_kubeadmbased_os_to_the_public/)

In loving memory of Bradley Joseph Root and his dog, [Elli](https://kubernetes.io/blog/2024/08/13/kubernetes-v1-31-release/)

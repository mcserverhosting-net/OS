We made a reddit post

https://www.reddit.com/r/kubernetes/comments/zjk605/releasing_our_kubeadmbased_os_to_the_public/

***As a reminder, using this image will zap your first device by default***


Usage Examples:
Build with default settings:

```bash
Copy code
make
make build-iso
```
Build with NVIDIA support:
```bash
Copy code
make ENABLE_NVIDIA=1
make build-iso
```
Build with both NVIDIA and AMD support:
```bash
Copy code
make ENABLE_NVIDIA=1 ENABLE_AMD=1
make build-iso
```
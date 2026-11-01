# EJBCA-Automated-Lab

A PKI lab that runs Keyfactor EJBCA Community Edition on Azure Kubernetes Service. Terraform builds the Azure side (AKS, PostgreSQL, Key Vault with CA keys, storage, Bastion, and Windows Server 2025 and RHEL 9 VMs for enrolment testing); a deploy script then installs EJBCA with a Helm chart, plus ingress, Linkerd, Prometheus, Loki, OpenTelemetry, Harbor and Argo CD.

## Repository layout

| Folder | What it is | State |
|---|---|---|
| [`EJBCA---Automated-Lab/`](EJBCA---Automated-Lab/) | AKS version: Terraform, Helm chart, Kubernetes values, Argo CD apps, Ansible, scripts | Terraform validates; this is the version to use |
| [`EJBCA---Automated-Lab-Docker/`](EJBCA---Automated-Lab-Docker/) | Lower-cost variant with EJBCA on Docker Compose on Azure VMs | Incomplete: its Terraform does not validate, and the Compose file mounts `nginx/`, `prometheus/` and `grafana/` config folders that are not in the repository |

## What the AKS version builds

**Azure (`EJBCA---Automated-Lab/terraform/`):**

| Resource | Details |
|---|---|
| AKS | Kubernetes 1.28 by default, autoscaling system pool plus `apps` and `pki` node pools, `Standard_D4s_v3` nodes |
| Database | Azure Database for PostgreSQL Flexible Server 15 (`GP_Standard_D4s_v3`) for EJBCA |
| Key Vault | Root and subordinate CA keys (`ejbca-root-ca-key`, `ejbca-sub-ca-key`), a wildcard TLS certificate, and generated passwords for PostgreSQL, the EJBCA superadmin, Harbor, Argo CD and the Windows VM |
| Storage | Containers for EJBCA backups, issued certificates and logs, plus a file share |
| Network | VNet with AKS, VM and Bastion subnets, NSGs, Azure Bastion, a DNS zone |
| Test clients | Windows Server 2025 and RHEL 9.3 VMs (`Standard_D4s_v3`), reached through Bastion |
| Other | Azure Container Registry, Log Analytics workspace |

**Kubernetes (`scripts/deploy.sh`):** Linkerd and Linkerd Viz, ingress-nginx, kube-prometheus-stack, Loki, the OpenTelemetry Collector, Harbor, Argo CD, then EJBCA CE 8.3 from `helm/ejbca-ce`. Argo CD is given a project and applications from `argocd/`. Values for Tempo and JFrog Artifactory are included but not installed by the script.

**Configuration:** `configs/ejbca/ca-hierarchy.yaml` and `certificate-profiles.json` describe the intended CA hierarchy and profiles; `ansible/` prepares the Windows and RHEL test clients.

## Requirements

- Azure subscription with rights to create AKS, PostgreSQL, Key Vault and role assignments
- Azure CLI, Terraform 1.6+, kubectl, Helm 3, and the `linkerd` CLI
- Ansible, for the test-client playbooks

## Quick start

```bash
git clone https://github.com/adrian207/EJBCA-Automated-Lab.git
cd EJBCA-Automated-Lab/EJBCA---Automated-Lab

cp terraform/terraform.tfvars.example terraform/terraform.tfvars
# Edit terraform.tfvars: location, names, allowed IP addresses, and a current
# aks_kubernetes_version (list with: az aks get-versions --location <region> -o table)

./scripts/deploy.sh
```

`deploy.sh` runs Terraform, fetches AKS credentials, installs Linkerd and the Helm releases, configures Argo CD and prints the URLs. `scripts/update-my-ip.sh` updates the allowed IP when yours changes. `scripts/demo-scenarios.sh` runs demonstrations of ACME, REST API, SCEP, CMP and EST enrolment, OCSP, CRLs, code and container signing, and certificate transparency against the deployed EJBCA.

Reach the VMs with `az network bastion rdp` or `az network bastion ssh`; `terraform output` prints the exact commands.

The folder's own [README](EJBCA---Automated-Lab/README.md), [QUICKSTART](EJBCA---Automated-Lab/QUICKSTART.md) and [IMPLEMENTATION-GUIDE](EJBCA---Automated-Lab/IMPLEMENTATION-GUIDE.md) go into more detail.

## Status and limitations

- **Cost.** Three or more D4s_v3 AKS nodes, two D4s_v3 VMs, a General Purpose PostgreSQL server and Bastion add up quickly. Destroy the lab when you are not using it (`terraform destroy`).
- **Kubernetes version.** The default `1.28` may no longer be offered by AKS in your region; set a current version before applying.
- **CA setup is manual.** The Helm chart deploys EJBCA, but nothing loads `configs/ejbca/ca-hierarchy.yaml` or `certificate-profiles.json`; create the CAs and profiles in the EJBCA admin UI or CLI using them as the reference.
- **CI workflows don't run.** The GitHub Actions workflows sit in `EJBCA---Automated-Lab/.github/workflows/`; GitHub only runs workflows from the repository root's `.github/workflows/`.
- Checked with `terraform validate`, YAML parsing and shellcheck, not deployed end to end in this repository.

## Related repositories

These repositories cover different parts of PKI work:

- **EJBCA-Automated-Lab** (this repository): run an open-source CA (EJBCA Community Edition) on AKS to test enrolment and certificate automation
- **[Keyfactor-CLM-Implementation](https://github.com/adrian207/Keyfactor-CLM-Implementation)**: plan and operate certificate lifecycle management on Keyfactor Command (design, runbooks, API automation examples)
- **[PKI-Consolidation](https://github.com/adrian207/PKI-Consolidation)**: merge two or more existing AD CS hierarchies into one, for example after an acquisition

## License

MIT. See [LICENSE](LICENSE).

## Author

Adrian Johnson · [github.com/adrian207](https://github.com/adrian207)

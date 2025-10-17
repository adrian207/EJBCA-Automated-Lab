# 🌐 Dynamic IP Management Guide

This guide provides two solutions for securely accessing your Azure resources when your local computer has a dynamic (changing) IP address.

---

## 🏆 Solution 1: Azure Bastion (Recommended for All Environments)

Azure Bastion is the most secure and convenient method. It allows you to connect to your VMs from anywhere, without needing to whitelist your IP address.

**How It Works**: Bastion provides a secure connection to your VMs directly from the Azure Portal over an encrypted SSL channel. Your VMs no longer need public IP addresses for SSH or RDP access, drastically reducing their exposure to the internet.

**Cost**: ~$144/month

### How to Use It:
1.  **Enable in Terraform**: Set `enable_bastion = true` in your `terraform.tfvars` file. This is the default.
2.  **Deploy**: Run `terraform apply`.
3.  **Connect**:
    * Go to your Virtual Machine in the Azure Portal.
    * Click **Connect** > **Bastion**.
    * Enter your VM credentials to start a secure session in your browser.

**When Bastion is enabled, the security rules for direct SSH and RDP access are automatically removed, enforcing a secure-by-default architecture.**

---

## 💻 Solution 2: IP Update Script (For Development Only)

If you choose not to use Azure Bastion (e.g., to save costs in a temporary development environment), you can use the `update-my-ip.sh` script.

**How It Works**: This script automatically detects your current public IP and updates the necessary Terraform configuration files to grant you access.

### How to Use It:
1.  **Disable Bastion**: Set `enable_bastion = false` in your `terraform.tfvars` file.
2.  **Run the Script**: Execute the script from the project root whenever your IP changes.
    ```bash
    ./scripts/update-my-ip.sh
    ```
3.  The script will find your new IP, update the files, and run `terraform apply` to update the firewall rules in Azure.

**Security Note**: This method is less secure than Bastion because it requires opening administrative ports to your IP address over the internet. It should only be used for temporary development work.
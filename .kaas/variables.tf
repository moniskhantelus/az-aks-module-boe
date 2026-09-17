variable "subscription_id" {
  type        = string
  description = "Subscription ID is provided externally via KaaS pipeline mapping."
}

variable "tenant_id" {
  type        = string
  description = "Azure US Gov tenant ID used for Microsoft Entra integration and AKS RBAC."
}

variable "naming" {
  type = object({
    platform         = string
    maintain_org     = string
    environment      = string
    region_code      = string
  })
  description = "Naming segments used to derive canonical AKS, identity, and resource names."
}   

variable "resource_group" {
  type        = any
  description = "Existing resource-group object with name and location; AKS and identities are created within this RG when module owns RG."
}


variable "node_subnet_id" {
  type        = string
  description = "Subnet ID for AKS node pools."
}

variable "kubernetes_version" {
  type        = string
  nullable    = true
  description = "Desired Kubernetes version or null for AKS default."
}

variable "sku_tier" {
  type        = string
  description = "AKS SKU tier (Free, Standard, or Premium)."
}

variable "support_plan" {
  type        = string
  description = "AKS Support Plan (Official or LTS)."
}

variable "admin_group_object_ids" {
  type        = list(string)
  description = "Microsoft Entra Group Object IDs with AKS admin access."
}

variable "azure_rbac_enabled" {
  type        = bool
  description = "Enable Azure RBAC for Kubernetes authorization."
}

variable "local_account_disabled" {
  type        = bool
  description = "Disable local admin account for AKS cluster for security compliance."
}

variable "cluster_profile" {
  type        = string
  description = "Cluster profile defining lifecycle and operational characteristics."
}

variable "compliance_profile" {
  type        = string
  description = "Compliance profile governing AKS operation, diagnostics, and rules."
}

variable "platform_security" {
  type        = any
  description = "Security configuration including Defender, Azure Policy, ACNS flags, etc."
}

variable "autoscaling" {
  type        = any
  description = "Cluster Autoscaler, NAP or manual scaling settings."
}

variable "disruption_profile" {
  type        = any
  description = "Upgrade, surge settings, disruption rules for node pool operations."
}

variable "availability_policy" {
  type        = any
  description = "Configuration for AZ-based availability and resilience rules."
}

variable "approved_kubernetes_versions" {
  type        = set(string)
  description = "Approved Kubernetes versions for compliance validation."
}

variable "private_cluster" {
  type        = any
  description = "Whether to deploy the AKS API as private-only."
}

variable "network" {
  type        = any
  description = "Networking configuration for AKS, including Cilium overlay and outbound mode."
}

variable "kms_encryption" {
  type        = any
  description = "Key management settings for disk encryption and secrets store CSI."
}

variable "system_node_pool" {
  type        = any
  description = "Configuration block for system node pool (vm_size, count, labels, taints)."
}

variable "user_node_pools" {
  type        = any
  description = "List/map of user node pool configurations for workload isolation."
}

variable "auto_scaler_profile" {
  type        = any
  description = "Fine-grained autoscaler profile settings."
}

variable "automatic_upgrade_channel" {
  type        = string
  description = "AKS upgrade channel for automatic updates."
}

variable "node_os_upgrade_channel" {
  type        = string
  description = "Upgrade channel for Node OS lifecycle."
}

variable "maintenance" {
  type        = any
  description = "Maintenance window settings for upgrades and patching."
}

variable "addons" {
  type        = any
  description = "AKS-native add-ons (Prometheus, CSI, Istio, Insights, ACNS)."
}

variable "storage_profile" {
  type        = any
  description = "Storage driver settings (disk, file, snapshot, blob)."
}

variable "integrations" {
  type        = any
  description = "External integrations such as ACR, Grafana, Monitor Workspace."
}

variable "backup_integration" {
  type        = any
  description = "Backup/restore integration settings: vault, policies, CSI snapshot profile."
}

variable "pki_integration" {
  type        = any
  description = "PKI integration settings including certificates and rotation patterns."
}

variable "diagnostic_log_categories" {
  type        = set(string)
  description = "Diagnostic categories for AKS control-plane and node logging."
}

variable "tags" {
  type        = map(string)
  description = "Platform-standard tagging schema for AKS resources."
}

variable "manage_role_assignments" {
  type        = bool
  description = "Enable module-managed Azure RBAC role assignments."
}

variable "managed_identities" {
  type = object({
    create                    = bool
    control_plane_identity_id = optional(string)
    kubelet_identity_id       = optional(string)
  })
  description = "Control-plane and kubelet identity contract for AKS."
}
# variable "location" {
#   description = "Azure region in which regional AKS resources are deployed."
#   type        = string
# }

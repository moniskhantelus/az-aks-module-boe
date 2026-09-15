# ==============================================================================
# Provider / Subscription
# ==============================================================================
subscription_id = "47940328-bbc5-4070-aa25-e8d4242280a4"
tenant_id       = "bcf48bba-4d6f-4dee-a0d2-7df59cc36629"

# ==============================================================================
# General
# ==============================================================================
naming = {
  platform     = "kaas"
  maintain_org = "cdp"
  environment  = "prod"
  region_code  = "va"
}
kubernetes_version           = "1.34"
approved_kubernetes_versions = ["1.34"]
cluster_profile              = "stateful"
compliance_profile           = "fips"
resource_group = {
  create = false
  name   = "kaas-cdp-prod-va-rg"
}
manage_role_assignments = false
managed_identities = {
  create                    = false
  control_plane_identity_id = "/subscriptions/47940328-bbc5-4070-aa25-e8d4242280a4/resourceGroups/rg-platform-dev/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-aks-platform-dev-control-plane"
  kubelet_identity_id       = "/subscriptions/47940328-bbc5-4070-aa25-e8d4242280a4/resourceGroups/rg-platform-dev/providers/Microsoft.ManagedIdentity/userAssignedIdentities/id-aks-platform-dev-kubelet"
}

# ==============================================================================
# Cluster Configuration - hardened NAP baseline
# ==============================================================================
sku_tier                  = "Standard"
support_plan              = "KubernetesOfficial"
automatic_upgrade_channel = "patch"
node_os_upgrade_channel   = "NodeImage"
autoscaling = {
  mode = "nap"
}
disruption_profile = {
  consolidation   = "conservative"
  max_unavailable = 1
}
availability_policy = {
  criticality        = "tier-1"
  node_os_exceptions = {}
}
maintenance = {

  auto_upgrade = {
    frequency = "Weekly", interval = 1, duration = 4, day_of_week = "Sunday", start_time = "02:00", utc_offset = "+00:00"
    not_allowed = [
      {
        name               = "year-end-freeze"
        start              = "2026-12-15T00:00:00Z"
        end                = "2027-01-05T00:00:00Z"
        reason             = "Enterprise year-end production freeze"
        approval_reference = "CHANGE-CALENDAR-YE2026"
      }
    ]
  }
  node_os = {
    frequency   = "Weekly", interval = 1, duration = 4, day_of_week = "Sunday", start_time = "06:00", utc_offset = "+00:00"
    not_allowed = []
  }
}

# ==============================================================================
# Identity
# ==============================================================================
admin_group_object_ids           = ["24a7ad92-ed8a-4e6d-ae24-ed5a0a0a9d3b"]
mandatory_admin_group_object_ids = ["24a7ad92-ed8a-4e6d-ae24-ed5a0a0a9d3b"]
azure_rbac_enabled               = true
local_account_disabled           = true

# ==============================================================================
# Networking - existing subnet; Azure CNI Overlay + Cilium are module-enforced
# ==============================================================================
node_subnet_id = "/subscriptions/47940328-bbc5-4070-aa25-e8d4242280a4/resourceGroups/ECS-RG-VA-Networking/providers/Microsoft.Network/virtualNetworks/VNET-USGOVVIRGINIA-SPOKE-AZAMPDEV-2/subnets/Subnet1"
network = {
  pod_cidr          = "10.244.0.0/16"
  service_cidr      = "10.0.0.0/20"
  dns_service_ip    = "10.0.0.10"
  outbound_type     = "userDefinedRouting"
  load_balancer_sku = "standard"
  capacity = {
    max_nodes         = 100
    max_pods_per_node = 110
  }
}
private_cluster = {
  enabled                             = true
  private_dns_zone_id                 = "/subscriptions/47940328-bbc5-4070-aa25-e8d4242280a4/resourceGroups/chp-kaas-amp-dev-va-rg-acr-pr-20260410/providers/Microsoft.Network/privateDnsZones/privatelink.usgovvirginia.cx.aks.containerservice.azure.us"
  public_fqdn_enabled                 = false
  api_server_authorized_ips           = []
  api_server_vnet_integration_enabled = false
  api_server_subnet_id                = null
}
kms_encryption = {
  enabled                  = true
  key_vault_resource_id    = "/subscriptions/47940328-bbc5-4070-aa25-e8d4242280a4/resourceGroups/kaas-cdp-prod-va-rg/providers/Microsoft.KeyVault/vaults/kaas-cdp-prod-test-vault"
  key_vault_key_id         = "https://kaas-cdp-prod-test-vault.vault.usgovcloudapi.net/keys/kaas-key/6004a7cd8ba74ebea2a65816c37d370d"
  key_vault_network_access = "Private"
}

# ==============================================================================
# Security and fixed system pool
# ==============================================================================
platform_security = {
  fips_required               = true
  psa_enforce_level           = "restricted"
  default_deny_network_policy = true
}
system_node_pool = {
  architecture            = "amd64"
  vm_size                 = "Standard_D4pds_v6"
  min_count               = 1
  max_count               = 3
  node_count              = 1
  zones                   = ["2", "3"]
  os_sku                  = "AzureLinux"
  os_disk_type            = "Ephemeral"
  os_disk_size_gb         = 128
  max_pods                = 110
  max_surge               = "33%"
  only_critical_addons    = true
  node_labels             = { "platform.boeing.com/workload-class" = "platform" }
  host_encryption_enabled = true
  fips_enabled            = true
  temporary_rotation_name = "systemtmp"
}

user_node_pools = {}

auto_scaler_profile = {

  balance_similar_node_groups      = true
  expander                         = "least-waste"
  max_graceful_termination_sec     = 600
  max_node_provisioning_time       = "15m"
  max_unready_nodes                = 3
  max_unready_percentage           = 45
  new_pod_scale_up_delay           = "0s"
  scale_down_delay_after_add       = "10m"
  scale_down_delay_after_delete    = "10s"
  scale_down_delay_after_failure   = "3m"
  scan_interval                    = "10s"
  scale_down_unneeded              = "10m"
  scale_down_unready               = "20m"
  scale_down_utilization_threshold = 0.5
  empty_bulk_delete_max            = 10
  skip_nodes_with_local_storage    = true
  skip_nodes_with_system_pods      = true
}

# ==============================================================================
# AKS add-ons and storage
# ==============================================================================
addons = {
  azure_policy_enabled            = true
  key_vault_csi_enabled           = true
  key_vault_secret_rotation       = true
  key_vault_rotation_interval     = "2m"
  managed_prometheus_enabled      = true
  container_insights_enabled      = true
  keda_enabled                    = true
  vertical_pod_autoscaler_enabled = true
  image_cleaner_enabled           = true
  image_cleaner_interval_hours    = 48
  istio_enabled                   = true
  istio_revisions                 = ["asm-1-30"]
  istio_internal_gateway_enabled  = true
  istio_external_gateway_enabled  = false
  defender_enabled                = true
}
storage_profile = {
  blob_driver_enabled         = true
  disk_driver_enabled         = true
  file_driver_enabled         = true
  snapshot_controller_enabled = true
}

# ==============================================================================
# ACR, Log Analytics, Defender and diagnostics (existing resource IDs)
# ==============================================================================
integrations = {
  acr_id                           = "/subscriptions/47940328-bbc5-4070-aa25-e8d4242280a4/resourceGroups/chp-kaas-amp-dev-va-rg-acr-pr-20260410/providers/Microsoft.ContainerRegistry/registries/testarcpr"
  log_analytics_workspace_id       = "/subscriptions/47940328-bbc5-4070-aa25-e8d4242280a4/resourceGroups/kaas-cdp-prod-va-rg/providers/Microsoft.OperationalInsights/workspaces/kaas-prod-law"
  defender_log_analytics_id        = "/subscriptions/47940328-bbc5-4070-aa25-e8d4242280a4/resourceGroups/kaas-cdp-prod-va-rg/providers/Microsoft.OperationalInsights/workspaces/kaas-prod-law"
  audit_archive_storage_account_id = "/subscriptions/47940328-bbc5-4070-aa25-e8d4242280a4/resourceGroups/kaas-cdp-prod-va-rg/providers/Microsoft.Storage/storageAccounts/kaasprodteststorage"
}
backup_integration = { enabled = true }
pki_integration = {
  enabled                     = false
  trusted_ca_bundle_secret_id = "https://kaas-cdp-prod-test-vault.vault.usgovcloudapi.net/secrets/kaas-cdp-prod-test-vault-secret/6b09406f977e4b14b0ee8e97bfb21166"
  issuer_url                  = ""
}
diagnostic_log_categories = ["kube-apiserver", "kube-audit", "kube-audit-admin", "kube-controller-manager", "kube-scheduler", "cluster-autoscaler", "guard", "cloud-controller-manager", "csi-azuredisk-controller", "csi-azurefile-controller", "csi-snapshot-controller"]

# ==============================================================================
# Governance / ESAT tags
# ==============================================================================
tags = {
  ECS_CSF_TAG    = "{\"SIS_RESP_ORG\":\"ENT-STRATA-KAAS-EIC-AZ\",\"SIS_CONTACT_BEMS_ID\":\"REPLACE\",\"SIS_ASSET_OWNER_BEMS_ID\":\"REPLACE\",\"SIS_ENVIRONMENT_ID\":\"PRODUCTION\",\"SIS_ASE_ID\":\"strata-k8s-azure\",\"LAPIC_ADMIN_ACCOUNT\":\"replace@boeing.com\"}"
  ECS_HPOO_TAG   = "{\"HPOO_CAGASSIGNMENTGROUP\":\"ENT-STRATA-KAAS-EIC-AZ\",\"HPOO_REQUESTORBEMSID\":\"REPLACE\",\"HPOO_SISRESPONSIBLEMANAGER\":\"REPLACE\",\"HPOO_SISVENDORSUPPORT\":\"BOEING\"}"
  KAAS_TAG       = "{\"mo\":\"cdp\",\"esats_id\":\"3678542\",\"namespace\":\"cdp-platform\",\"env\":\"prod\",\"finops_uuid\":\"REPLACE\",\"classification\":\"confidential\",\"deploy_type\":\"terraform\",\"tier\":\"tier-1\",\"sla\":\"99.9\"}"
  KAAS_EXT_TAG   = "{\"dl\":\"replace@boeing.com\",\"dr_enabled\":\"true\",\"backup_policy\":\"daily\",\"data_residency\":\"us-gov\",\"response_sla\":\"1h\"}"
  KAAS_INFRA_TAG = "{\"persistence\":\"stateful\",\"storage_type\":\"disk\",\"ingress\":\"internal\",\"network_policy\":\"enabled\",\"scaling\":\"hpa\",\"secrets_provider\":\"csi-kv\",\"mesh_enabled\":\"false\"}"
}

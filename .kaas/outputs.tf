output "aks" {
  description = "Stable AKS identifiers and profile signals emitted by the module (name, id, FQDNs, OIDC issuer, node resource group, etc.)"
  sensitive   = false

  value = {
    cluster_id                   = module.aks.cluster_id
    cluster_name                 = module.aks.cluster_name
    resource_group_name          = module.aks.resource_group_name
    resource_group_created       = module.aks.resource_group_created
    oidc_issuer_url              = module.aks.oidc_issuer_url
    node_provisioning            = module.aks.node_provisioning
    nap_gitops_required          = module.aks.nap_gitops_required
    platform_security_contract   = module.aks.platform_security_contract
    aks_readiness                = module.aks.aks_readiness
    availability_readiness       = module.aks.availability_readiness
    upgrade_readiness            = module.aks.upgrade_readiness
    network_readiness            = module.aks.network_readiness
    storage_readiness            = module.aks.storage_readiness
    naming_readiness             = module.aks.naming_readiness
    normalized_cluster_contract  = module.aks.normalized_cluster_contract
    effective_kubernetes_version = module.aks.effective_kubernetes_version
    cluster_profile_contract     = module.aks.cluster_profile_contract
    backup_integration           = module.aks.backup_integration
    pki_integration_contract     = module.aks.pki_integration_contract
    connect_command              = module.aks.connect_command
  }
}
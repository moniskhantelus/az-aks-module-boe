# KaaS Platform — Long-Term Architecture and Repository Structure

**Purpose:** Explain the proposed platform structure, resource ownership and evolution path for architecture and engineering review.  
**Status:** Proposed architecture. Boeing-specific policies and accountable teams require confirmation.

## 1. The architecture recommendation

KaaS should provide a consistent way for teams to request, operate and retire Kubernetes clusters. Its responsibilities extend beyond creating AKS resources: it must validate requests, apply enterprise policy, coordinate dependencies, establish operational readiness and report lifecycle status.

Build the platform around these responsibilities. Keep the Azure implementation behind a defined interface so that Terraform can deliver AKS today and a qualified CAPI provider can perform lifecycle reconciliation later.

The immediate structural recommendation is to separate four resource lifecycles:

1. **Prerequisites:** Resource groups, networking, DNS, identities and permissions needed before cluster creation.
2. **Core cluster:** AKS, minimum system capacity and cluster-level settings.
3. **Workload capacity:** User node pools and their configuration, scaling and replacement.
4. **Kubernetes configuration:** GitOps baselines, platform services and workload configuration.

These boundaries remain useful regardless of which provisioning tool the platform uses.

## 2. What the platform looks like

```text
Application or engineering team
              |
              | Requests an approved Kubernetes service
              v
+----------------------------------------------------------+
| KaaS platform control plane                               |
|                                                          |
| Request interface -> validation -> lifecycle coordination |
|                          |                               |
|                 inventory and status                     |
+--------------------------+-------------------------------+
                           |
                           | Selects the provider implementation
                           v
+--------------------------+-------------------------------+
| Azure implementation     | Future AWS implementation     |
|                          |                               |
| Terraform -> AKS today   | Qualified EKS delivery path   |
| CAPZ -> AKS when ready   | CAPA where selected           |
+--------------------------+-------------------------------+
                           |
                           | Cluster becomes available
                           v
+----------------------------------------------------------+
| Capacity and Kubernetes services                         |
|                                                          |
| User pools | GitOps | monitoring | backup | security      |
+----------------------------------------------------------+

Central policy governs every step.
Versioned contracts define what passes between the parts.
```

A consumer requests an outcome, such as a private cluster using an approved service profile. The platform resolves that request into provider-specific configuration and coordinates its delivery.

The consumer should not need to understand which Terraform state owns a subnet or which controller provisions a node pool. Engineers operating the platform must still have that ownership information available.

## 3. The five architectural layers

The five layers describe responsibilities. They do not require five separate services or repositories.

### Layer 1 — Platform control plane

This is the service layer that consumers interact with through an API, portal or approved Git workflow.

It owns:

- Request authentication and authorization.
- Service catalog and approved profile selection.
- Coordination of create, update, upgrade and delete operations.
- Cluster inventory, operation history and readiness status.
- Dispatch to the selected provider implementation.

For example, when a team requests a cluster, this layer verifies that the team can use the selected environment, records the request and starts the appropriate workflow.

**Terminology:** The KaaS platform control plane is distinct from the Kubernetes control plane inside an AKS cluster. A future CAPI management cluster is another component: it runs lifecycle controllers on behalf of the platform.

Start with a simple implementation. A request interface, durable workflow and inventory can establish this boundary without building many microservices.

### Layer 2 — Provider implementation

This layer knows how to deliver the requested service in a particular cloud.

For Azure, it resolves approved inputs into AKS configuration, Azure resource identifiers, identity relationships and network settings. It performs or coordinates provisioning and reports the result.

Terraform is one execution mechanism within this layer. CAPZ can become another after qualification. The platform should choose one authoritative mechanism for a given resource.

Cloud differences remain explicit. A common contract should not imply that Azure and AWS offer identical networking, identity or upgrade behavior. Provider-specific profiles describe the supported implementation.

### Layer 3 — Day-2 lifecycle

This layer manages capabilities that change independently of the core cluster:

- Workload capacity and user node pools.
- GitOps bootstrap and platform baselines.
- Observability, backup and security services.
- Ongoing maintenance of platform Kubernetes configuration.

“Day-2” describes ownership and change cadence. Required services should still be installed during initial delivery. Creating the AKS resource alone does not make the KaaS service ready.

### Layer 4 — Governance and policy

This layer defines the rules that the platform must apply: naming, tagging, placement, security profiles, access requirements and exceptions.

Policy definitions belong to their central governance owners. The platform evaluates and implements them at appropriate boundaries, such as request validation, Terraform checks, cloud policy and Kubernetes admission.

The AKS implementation must not create its own interpretation of mandatory enterprise tags or security requirements without an authoritative source.

### Layer 5 — Normalized contracts

A contract is a documented, versioned agreement about inputs, outputs and behavior between components.

For example, the cluster implementation consumes a network reference whose meaning is defined: which attachment it represents, who owns it and which connectivity requirements have been verified.

Contracts allow the platform to change its implementation while preserving the consumer interface. They also make dependencies testable and prevent components from relying on undocumented outputs.

## 4. Recommended repository structure

```text
kaas-platform/
├── control-plane/
│   ├── api/                  # Request and operation interfaces
│   ├── orchestration/        # Workflow and dependency coordination
│   ├── inventory/            # Cluster identity, ownership and status
│   └── adapters/             # Dispatch to execution mechanisms
│
├── contracts/
│   ├── cluster/
│   ├── networking/
│   ├── identity/
│   └── lifecycle/
│
├── policies/
│   ├── naming/
│   ├── tagging/
│   ├── network/
│   ├── security/
│   └── compliance/
│
├── providers/
│   ├── azure/
│   │   ├── prerequisites/
│   │   ├── cluster/aks/
│   │   ├── nodepools/
│   │   ├── integrations/
│   │   └── profiles/
│   └── aws/                  # Add when there is a delivery requirement
│
├── day2/
│   ├── gitops/
│   ├── observability/
│   ├── backup/
│   └── security/
│
├── environments/
│   ├── dev/
│   ├── test/
│   └── prod/
│
├── tests/                    # Cross-component integration tests
└── docs/                     # Decisions, interfaces and runbooks
```

### How to read this structure

**`providers/` contains implementation code.** For example, the reusable AKS Terraform module and Azure user-pool module live here.

**`environments/` contains deployment composition.** It selects approved versions, binds profiles to actual environments and invokes the implementation. It should not contain copied versions of the AKS module.

**`day2/` contains platform Kubernetes services.** Azure-specific cloud resource wiring stays under the Azure provider. For example, an Azure diagnostic setting belongs in the Azure implementation, while a reusable in-cluster monitoring baseline belongs under Day-2 observability.

**`contracts/` and `policies/` define shared agreements.** Provider implementations consume them; they should not maintain competing copies.

Start with one repository when team access and release practices permit. Split repositories when separate ownership, permissions or release cadence requires it. The logical boundaries should remain the same.

A folder does not enforce isolation. Execution identities, state boundaries and controller ownership do.

## 5. Detailed Azure implementation

```text
providers/azure/
├── prerequisites/
│   ├── resource-group/
│   ├── identities/
│   ├── networking/
│   ├── dns/
│   ├── iam/
│   └── registry-access/
│
├── cluster/aks/
│   ├── main.tf
│   ├── cluster.tf
│   ├── diagnostics.tf
│   ├── security.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── locals.tf
│   ├── versions.tf
│   ├── examples/
│   └── tests/
│
├── nodepools/
├── integrations/
└── profiles/
```

### Prerequisites

This capability creates resources only where the platform has explicit ownership. Otherwise, it resolves and verifies resources supplied by enterprise services.

Examples include the target resource group, subnet, DNS integration, control-plane identity, kubelet identity and required role assignments. A shared network should remain owned by its network service; the cluster implementation consumes its reference.

Readiness includes effective permissions and connectivity, not just resource existence. The workflow must establish that deployment runners and management services can reach required private endpoints and that identity assignments have become effective.

### Core AKS module

Keep the module cohesive. It owns AKS and the minimum system capacity required by the selected implementation, together with cluster-level configuration such as networking mode, private access, identity integration, upgrade settings and supported addons.

A qualified Azure profile may select Azure CNI Overlay, Cilium, Entra integration, workload identity and approved maintenance settings. Confirm compatibility for the selected Kubernetes version, region and cloud environment before making a profile available.

The `.tf` files are logical organization within one module. Creating `security.tf` does not give security settings a separate state or lifecycle.

### User node pools

Keep user-pool capabilities in an independently managed component. Pool changes can include VM size, architecture, Spot versus regular capacity, zones, taints, scaling bounds and replacement strategy.

This preserves the capabilities without requiring every workload capacity change to run the state that owns the core cluster. Cluster and pool operations still require coordination because the cloud service can impose shared operation constraints.

## 6. Ownership and lifecycle boundaries

| Boundary | Owns | Must not assume ownership of |
|---|---|---|
| Prerequisite service | Resources and permissions explicitly assigned to it | Enterprise resources merely referenced by a cluster |
| Core cluster implementation | AKS configuration and minimum system capacity | All upstream IAM, networking or workload capacity |
| Capacity implementation | User-pool configuration and replacement | Core cluster configuration |
| Platform GitOps | Platform baseline and Kubernetes policy objects | Cloud resources owned by Terraform or CAPI |
| Workload team | Applications and workload-specific configuration | Platform-wide controllers and governance rules |

### State boundaries

Separate Terraform state according to resource ownership and change cadence. A practical starting point is:

```text
Foundation scope state
    -> publishes approved prerequisite references

Per-cluster state
    -> owns AKS and system capacity
    -> publishes the cluster reference

Per-cluster user-capacity state
    -> owns independently managed user pools

GitOps reconciliation
    -> owns the Kubernetes baseline and permitted configuration
```

A shared foundation may support several clusters, so it should not be destroyed with any one cluster. Publish minimal outputs through an authorized interface; downstream components should not require access to an entire state snapshot just to obtain an identifier.

### One writer per resource

Terraform, CAPI, GitOps and autoscalers must have explicit boundaries.

For conventional user pools, the capacity implementation owns pool configuration. Where supported, an autoscaler owns the current count within configured bounds.

For dynamic provisioning, GitOps can own supported provisioning policy objects such as NodePool and AKSNodeClass. The provisioner owns resulting dynamic capacity. Qualify the supported configuration and coexistence rules before enabling it.

Separate state reduces execution scope; it does not remove the need to serialize incompatible cluster upgrades and pool changes.

## 7. Contracts with concrete examples

Separate three kinds of information:

1. **Requested intent:** What the consumer wants.
2. **Resolved inputs:** Concrete provider settings and identifiers selected by the platform.
3. **Observed status:** What has actually been provisioned and verified.

The HCL below illustrates proposed contracts. It is not an existing module interface or a deployable AzureRM resource definition. Names and profiles are examples, not Boeing standards.

### Cluster request

```hcl
locals {
  cluster_request = {
    schema_version  = "v1alpha1"
    cluster_id      = "cluster-001"
    tenant_ref      = "tenant/example"
    provider        = "azure"
    placement_ref   = "landing-zone/approved"
    service_profile = "private-standard-v1"
    version_profile = "kubernetes-qualified-v1"
    network_ref     = "network/approved"
    identity_ref    = "identity/approved"
    capacity_mode   = "managed-pools"
    baseline_ref    = "baseline/platform-v1"
  }
}
```

The cluster ID is the stable platform identity. A profile selects a tested configuration rather than exposing every provider switch to consumers. Resolve profiles to immutable revisions before execution.

### Network and identity dependencies

```hcl
locals {
  network_contract = {
    ref            = "network/approved"
    ownership      = "external"
    attachment_ref = "subnet/approved"
    api_access     = "private"
    ipam_ref       = "allocation/approved"
    dns_ref        = "dns/approved"
    egress_ref     = "egress/approved"
  }

  identity_contract = {
    ref               = "identity/approved"
    ownership         = "external"
    control_plane_ref = "principal/cluster-control"
    node_ref          = "principal/cluster-nodes"
    workload_profile  = "federated-v1"
    access_ref        = "access/platform-admins"
  }
}
```

`external` means the cluster implementation consumes the resource and cannot delete it. The Azure adapter resolves the logical references to the correct Azure identifiers and validates permissions. Keep deployment credentials separate from cluster, node and workload identities.

### Lifecycle request and result

```hcl
locals {
  lifecycle_request = {
    operation_id    = "operation-001"
    idempotency_key = "request-001"
    cluster_id      = "cluster-001"
    generation      = 1
    action          = "reconcile"
    maintenance_ref = "maintenance/approved"
    deletion_policy = "retain-shared-prerequisites"
  }

  observed_status = {
    operation_id        = "operation-001"
    observed_generation = 1
    infrastructure_ready = true
    baseline_ready       = true
    service_ready        = true
    access_ref           = "access/cluster-001"
  }
}
```

The generation identifies the desired configuration being processed. The idempotency key lets the service recognize a repeated request. Production status should also include failure reasons, transition times and evidence references.

An infrastructure-ready cluster may still lack its required baseline. Report those conditions separately. Return an authorized access reference rather than placing credentials in inventory.

## 8. Central naming and tagging policy

Define naming and tagging from approved enterprise requirements. The AKS module should implement applicable rules without inventing mandatory keys.

The central policy definition should identify:

- Required keys and their authoritative source.
- Allowed values and casing.
- Applicable resource types.
- Caller-supplied values and centrally controlled values.
- Exception ownership and expiry.

The platform resolves the approved names and tags before provisioning. The Azure implementation checks Azure-specific constraints. If cloud policy also modifies tags, document which keys it owns and how drift is handled.

An optional `tags` input can default to an empty map in a reusable module. That does not remove enterprise requirements from the deployment composition.

**Boeing review item:** Confirm the authoritative naming and tagging sources. This architecture does not establish a new mandatory tag list.

## 9. End-state request flow

Consider a team requesting a private Azure cluster:

1. **Accept and authorize.** Verify the requester can use the selected tenant, placement and service profile.
2. **Validate intent.** Check the contract, central policy and provider capability support.
3. **Record the operation.** Persist the desired generation and operation ID before infrastructure side effects.
4. **Resolve prerequisites.** Obtain concrete references and verify ownership, effective IAM, DNS and connectivity. Report missing dependencies explicitly.
5. **Provision the cluster.** Select one implementation and coordinate conflicting operations.
6. **Establish capacity and baseline.** Create the required user capacity and reconcile the platform Kubernetes services.
7. **Verify readiness.** Check API access, system health, required networking and baseline health.
8. **Publish the service.** Return status and an authorized access path; continue observing health and drift.

```text
Request -> Authorize -> Validate -> Record operation
                                      |
                                      v
                           Verify prerequisites
                                      |
                                      v
                         Terraform OR CAPI execution
                                      |
                                      v
                         Capacity and GitOps baseline
                                      |
                                      v
                            Service readiness checks
                                      |
                                      v
                           Access, status and support
```

A timeout does not prove that provisioning failed. Re-query actual state before repeating a mutation. A baseline failure should produce an actionable degraded status, rather than automatically destroying a functioning cluster.

Deletion follows a separate coordinated flow: address workload data and retention, stop reconciliation that would recreate resources, remove owned dependencies in order, and retain shared prerequisites.

## 10. Evolution from Terraform to CAPI

The objective is continuity of the KaaS service interface while implementation capabilities improve.

| Stage | Change | Evidence required before proceeding |
|---|---|---|
| 1. Establish boundaries | Separate prerequisite, cluster, capacity and GitOps ownership | Create, change and delete without unintended shared-resource changes |
| 2. Formalize the service | Add contracts, operation tracking, policy validation and inventory | Recover interrupted operations and report readiness accurately |
| 3. Qualify CAPI | Test CAPZ for AKS; test CAPA for EKS when required | Feature coverage, cloud support, lifecycle tests and management recovery |
| 4. Introduce controller delivery | Route eligible new requests to the qualified implementation | Successful canary operation and documented support procedures |
| 5. Evaluate existing clusters | Retain Terraform, replace clusters or use a supported adoption procedure | Tested ownership transfer and recovery for the selected configuration |

CAPI does not replace the service catalog, enterprise authorization or governance. It supplies lifecycle reconciliation beneath those capabilities.

CAPZ is the Azure provider and CAPA is the AWS provider. Their managed-service paths must be qualified for AKS and EKS respectively. Do not assume that support for self-managed Kubernetes implies support for the required managed-service configuration.

Existing-cluster adoption depends on the provider model and release. Never enable a new controller over resources still actively managed by Terraform. A migration must define the old writer's shutdown, resource bindings, new desired configuration and recovery procedure.

The CAPI management environment also becomes an operational responsibility: controller upgrades, credentials, private connectivity, backup and recovery need defined owners.

## 11. Why AKS is not the entire platform

AKS delivers managed Kubernetes in Azure. KaaS delivers an enterprise service around Kubernetes.

For example, AKS does not by itself define which internal teams can request a service profile, how enterprise prerequisites are coordinated, when the platform considers the service ready, or how a future AWS offering should appear to consumers. Those are KaaS responsibilities.

Keeping that boundary explicit lets the team improve the Azure implementation without coupling every consumer to Azure resource fields or Terraform state. It also allows additional providers when there is a real requirement, without forcing artificial feature parity.

## 12. Recommendation for the architecture review

Approve the logical boundaries first. The next implementation should demonstrate one complete Azure service path rather than populate every future folder.

Agree on these decisions:

- Who owns prerequisites, core clusters, user capacity and the Kubernetes baseline.
- Which Boeing sources define naming, tagging and security requirements.
- Which Azure profile and cloud environment will be qualified first.
- Which state, credential and operation boundaries enforce ownership.
- Which checks distinguish infrastructure readiness from service readiness.

The first milestone should demonstrate cluster creation, an independent user-pool change, baseline readiness and deletion that preserves shared infrastructure. Build the orchestration and future CAPI path on that verified foundation.

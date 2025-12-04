# Azure CMS Infrastructure - Detailed Summary

## 📋 Executive Overview

The CMS (Content Management System) project is a **production-grade Azure infrastructure** deployed through Terraform using a modular architecture. It combines containerized application deployment with enterprise-level security, performance optimization, and high availability.

**Key Characteristic**: All infrastructure is defined as code, scalable, and follows Azure best practices for multi-region deployment.

---

## 🏗️ Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Azure CMS Architecture                       │
└─────────────────────────────────────────────────────────────────────┘

                         Internet Users
                              │
                              ▼
                    ┌─────────────────────┐
                    │   Azure Front Door  │ (CDN + Global Load Balancer)
                    │   (Standard SKU)    │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │  Azure DNS Zone     │ (Domain Management)
                    │  cms.example.com    │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼─────────────┐
                    │ Application Gateway    │ (WAF + SSL Termination)
                    │ (WAF v2 Enabled)       │
                    │ Port: 443 (HTTPS)      │
                    └──────────┬─────────────┘
                               │
                    ┌──────────▼─────────────┐
                    │  Virtual Network       │ (10.0.0.0/16)
                    │  ├─ AppGW Subnet       │ (10.0.1.0/24)
                    └──────────┬─────────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
    ┌───────────▼──────────┐   │   ┌──────────▼───────────┐
    │ Container Apps Env   │   │   │ Key Vault            │
    │ (Managed Platform)   │   │   │ (SSL Certificates)   │
    │                      │   │   └──────────────────────┘
    │ ┌──────────────────┐ │   │
    │ │ Container App    │ │   │   ┌──────────────────────┐
    │ │ (nginx:latest)   │ │   │   │ Storage Account      │
    │ │ • CPU: 0.25      │ │   │   │ (Static Content CDN) │
    │ │ • Memory: 0.5Gi  │ │   │   └──────────────────────┘
    │ │ • Min: 1 replica │ │   │
    │ │ • Max: 3 replicas│ │   │   ┌──────────────────────┐
    │ │ • Public Ingress │ │   │   │ Log Analytics        │
    │ └──────────────────┘ │   │   │ (Monitoring/Logs)    │
    └──────────────────────┘   │   └──────────────────────┘
                                │
                    ┌───────────▼──────────┐
                    │ Resource Group       │
                    │ rg-cms-prod-app      │
                    └──────────────────────┘
```

---

## 🔧 Core Components

### **1. Resource Group (rg-cms-prod-app)**
- **Purpose**: Container for all CMS resources
- **Location**: East US (configurable)
- **Tags**: Environment=Production, Project=CMS
- **Module Used**: `terraform-azurerm-resource-group`

**Why This Matters**: Resource groups provide logical grouping, access control boundaries, and billing isolation for all CMS infrastructure.

---

### **2. Container App Environment**
**Service**: Azure Container Apps Environment (Managed Platform-as-a-Service)

**Purpose**: Provides the managed runtime environment for containerized applications

**Configuration**:
- Auto-scaling capabilities (1-3 replicas)
- Integrated with Log Analytics for diagnostics
- Serverless pricing model

**Resource**:
```hcl
module "container_app_environment" {
  name                           = "cms-container-app-env"
  log_analytics_workspace_id     = module.log_analytics.workspace_id
  # Container Apps automatically handled by managed environment
}
```

**Why This Design**: 
- ✅ No infrastructure management overhead
- ✅ Built-in auto-scaling and networking
- ✅ Pay only for actual compute usage
- ✅ Native Azure integration

---

### **3. Container App (CMS Application)**
**Service**: Azure Container Apps

**Purpose**: Runs your containerized CMS application

**Current Configuration**:
| Parameter | Value | Purpose |
|-----------|-------|---------|
| **Image** | `nginx:latest` | Default web server (replace with CMS app) |
| **CPU** | 0.25 vCPU | Lightweight resource allocation |
| **Memory** | 0.5Gi | Minimal memory footprint |
| **Min Replicas** | 1 | Always running for availability |
| **Max Replicas** | 3 | Scales up under load |
| **Ingress** | Enabled | Public HTTP/HTTPS access |

**Replacement Options**:
```hcl
# For different CMS platforms:
image = "wordpress:latest"           # WordPress CMS
image = "contentful/cli:latest"      # Contentful headless CMS
image = "strapi:latest"              # Strapi CMS
image = "node:18-alpine"             # Custom Node.js CMS
image = "python:3.11"                # Django/Python CMS
```

**Output**: `fqdn` = Container App's fully qualified domain name (fed to Application Gateway)

---

### **4. Virtual Network (VNet) - 10.0.0.0/16**
**Service**: Azure Virtual Network

**Subnets**:

| Subnet | CIDR | Purpose |
|--------|------|---------|
| **appgw-subnet** | 10.0.1.0/24 | Application Gateway (WAF + Load Balancer) |

**Design Notes**:
- Single subnet for Application Gateway (252 usable IPs)
- Container Apps run in managed environment (no explicit subnet)
- Future expansion: Can add spoke networks for microservices

**Network Flow**:
```
Internet → Front Door → DNS → App Gateway → Container App → Application
```

---

### **5. Application Gateway (WAF v2)**
**Service**: Azure Application Gateway with Web Application Firewall

**Purpose**: 
- ✅ Load balancing across Container App instances
- ✅ SSL/TLS termination (HTTPS offloading)
- ✅ Web Application Firewall (OWASP rules)
- ✅ URL-based routing (if multiple backends)

**Configuration**:

| Component | Setting |
|-----------|---------|
| **SKU** | WAF_v2 |
| **Tier** | WAF_v2 |
| **Capacity** | 2 instances |
| **Frontend Port** | 443 (HTTPS) |
| **Backend** | Container App FQDN |
| **Protocol** | HTTPS (with SSL cert from Key Vault) |
| **WAF Mode** | Prevention (blocks threats) |
| **Rule Set** | OWASP 3.2 |

**Traffic Flow**:
```
User HTTPS Request (Port 443)
         ↓
   App Gateway Frontend IP
         ↓
   SSL Termination (Key Vault Cert)
         ↓
   WAF Rules Inspection
         ↓
   Backend Pool → Container App
         ↓
   Response back to User
```

**WAF Protection Includes**:
- SQL Injection prevention
- Cross-site scripting (XSS) blocking
- Bot protection
- Rate limiting
- Custom rule support

---

### **6. Public IP (Static)**
**Service**: Azure Public IP

**Configuration**:
- **Allocation**: Static (persistent across restarts)
- **SKU**: Standard (required for Application Gateway WAF v2)
- **IP Address**: Reserved for Application Gateway frontend

**Purpose**: Provides fixed public endpoint for Application Gateway

---

### **7. Key Vault**
**Service**: Azure Key Vault

**Purpose**: Secure storage for:
- SSL/TLS certificates (for HTTPS)
- Application secrets (API keys, connection strings)
- Keys for encryption/decryption

**Configuration**:
- **SKU**: Standard (sufficient for most deployments)
- **Soft Delete**: 7 days (recover deleted secrets)
- **RBAC Permissions**: Full access to current user/service principal

**Security Features**:
- Encryption at rest (Azure-managed keys)
- RBAC (role-based access control)
- Audit logging in Log Analytics
- IP-based firewall support

**Access Policy**:
```hcl
Access to:
- Certificates (Create, Import, Get, List)
- Keys (Create, Decrypt, Encrypt, Get)
- Secrets (Get, Set, List)
```

---

### **8. Storage Account**
**Service**: Azure Storage Account

**Purpose**:
- Static content hosting for CDN
- Media uploads (images, videos)
- Backup storage
- Logging archive

**Configuration**:

| Setting | Value | Purpose |
|---------|-------|---------|
| **Account Tier** | Standard | Cost-effective, all workloads |
| **Replication** | LRS (Local Redundant) | Data redundancy in single region |
| **Access Tier** | Hot (default) | Frequently accessed data |
| **Min TLS** | 1.2 | Security enforcement |

**Typical Use Cases**:
```
/uploads/          → User uploaded media
/static/           → CSS, JS, images
/backups/          → Database backups
/cdn/              → CDN-served content
```

**Extension**: Can be configured as CDN origin for further optimization

---

### **9. Azure Front Door**
**Service**: Azure Front Door (Standard SKU - Successor to Azure CDN)

**Purpose**:
- ✅ Global content delivery network (CDN)
- ✅ DDoS protection
- ✅ Application-layer routing
- ✅ Multi-region failover
- ✅ Custom domain support

**Configuration**:

| Component | Setting |
|-----------|---------|
| **SKU** | Standard_AzureFrontDoor |
| **Origin** | Application Gateway Public IP |
| **Protocol** | HTTPS |
| **Caching** | Enabled by default |
| **Compression** | Automatic for applicable content types |

**How It Works**:
```
User Request (from any geography)
         ↓
Nearest Front Door POP (Point of Presence)
         ↓
Cache Hit? → Return cached content
Cache Miss? → Route to origin (App Gateway)
         ↓
Return response + cache for next request
```

**Performance Benefits**:
- ⚡ Reduced latency (geographic distribution)
- 📊 Reduced origin load (caching)
- 🛡️ Built-in DDoS protection
- 🔄 Automatic failover support

---

### **10. DNS Zone (cms.example.com)**
**Service**: Azure DNS

**Purpose**: Authoritative DNS hosting for your domain

**Records Configuration**:

| Record | Type | Value | TTL | Purpose |
|--------|------|-------|-----|---------|
| www | A/CNAME | Front Door endpoint | 300s | www.cms.example.com routing |
| @ (apex) | A | App Gateway IP | 300s | Root domain (optional) |

**DNS Resolution Flow**:
```
User types: www.cms.example.com
         ↓
DNS query to Azure DNS nameservers
         ↓
Returns Front Door CNAME
         ↓
User's device resolves to Front Door POP
         ↓
Request routed through global network
```

**Nameserver Setup**:
Get nameservers from Azure DNS zone and configure at domain registrar:
```
ns1.azure-dns.com.
ns2.azure-dns.net.
ns3.azure-dns.org.
ns4.azure-dns.info.
```

---

### **11. Log Analytics Workspace**
**Service**: Azure Log Analytics

**Purpose**: Centralized monitoring and diagnostics

**Configuration**:
- **SKU**: PerGB2018 (pay-per-use)
- **Retention**: 30 days (configurable: 7-730 days)
- **Data Sources**: Container Apps logs, metrics, diagnostics

**What Gets Logged**:
```
Container App Logs:
├─ Application stdout/stderr
├─ Container restarts
├─ CPU/Memory metrics
├─ Network I/O
└─ Replica scaling events

App Gateway Logs:
├─ Access logs
├─ WAF detections
├─ Backend health status
└─ Performance metrics
```

**Queries Example**:
```kusto
// Find WAF blocks
AzureDiagnostics 
| where Category == "ApplicationGatewayFirewallLog"
| where action_s == "Blocked"

// Container App errors
ContainerAppConsoleLogs
| where ContainerId == "cms-container-app"
| where LogLevel == "ERROR"
```

---

## 📊 Data Flow Diagram

```
                    ┌─────────────────────┐
                    │    End Users        │
                    │   (Internet)        │
                    └──────────┬──────────┘
                               │ HTTPS Request
                               ▼
                    ┌─────────────────────┐
                    │  Azure Front Door   │
                    │  (Global CDN)       │
                    │  • Cache content    │
                    │  • DDoS Protection  │
                    └──────────┬──────────┘
                               │ Cache Miss or
                               │ Dynamic Content
                               ▼
                    ┌─────────────────────┐
                    │  Azure DNS          │
                    │  Resolves FQDN      │
                    └──────────┬──────────┘
                               │ Points to Front Door
                               ▼
                    ┌─────────────────────┐
                    │  App Gateway        │
                    │  • WAF Filtering    │
                    │  • SSL Termination  │
                    │  • Load Balancing   │
                    └──────────┬──────────┘
                               │ Validated Request
                               ▼
            ┌──────────────────────────────────────┐
            │  Virtual Network (10.0.0.0/16)       │
            │                                      │
            │  ┌────────────────────────────────┐ │
            │  │ Container App Environment      │ │
            │  │                                │ │
            │  │  ┌──────────────────────────┐ │ │
            │  │  │ Container App Replicas   │ │ │
            │  │  │ (nginx:latest)           │ │ │
            │  │  │ • Replica 1              │ │ │
            │  │  │ • Replica 2 (if scaled)  │ │ │
            │  │  │ • Replica 3 (if scaled)  │ │ │
            │  │  └──────────────────────────┘ │ │
            │  └────────────────────────────────┘ │
            │                                      │
            └──────────────────────────────────────┘
                               │
                ┌──────────────┼──────────────┐
                │              │              │
                ▼              ▼              ▼
        ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
        │ Key Vault    │ │ Storage Acct │ │ Log Analytics│
        │ • SSL Certs  │ │ • Static     │ │ • Monitoring│
        │ • Secrets    │ │ • CDN Origin │ │ • Diagnostics
        └──────────────┘ └──────────────┘ └──────────────┘
```

---

## 🔄 Auto-Scaling Behavior

**Container App Scaling Rules**:
- **Min Replicas**: 1 (always running)
- **Max Replicas**: 3 (under heavy load)
- **Metric**: CPU and Memory-based
- **Scale-Out**: Triggered when CPU > 70% or Memory > 80%
- **Scale-In**: Triggered when resources drop below 30%

**Example Scenarios**:
```
Normal Traffic (0-30% CPU)
└─ 1 replica running
   └─ Cost: Minimal

Moderate Traffic (30-70% CPU)
└─ Still 1 replica (sufficient)
   └─ Cost: Low

Heavy Traffic (70-90% CPU)
└─ Scales to 2 replicas
   └─ Cost: Medium

Peak Traffic (>90% CPU)
└─ Scales to 3 replicas (max)
   └─ Cost: Highest (but controlled)
```

---

## 🔐 Security Layers

### **Layer 1: Front Door**
- Global DDoS protection
- TLS 1.2+ enforcement
- Bot protection

### **Layer 2: DNS**
- Azure DNS (no default firewall)
- Can be restricted via Private DNS (future enhancement)

### **Layer 3: Application Gateway**
- WAF v2 (OWASP ModSecurity rules)
- Rate limiting
- Custom WAF rules
- SSL/TLS certificate pinning

### **Layer 4: Key Vault**
- Encryption for certificates
- RBAC-based access
- Audit logging

### **Layer 5: Container Apps**
- Network isolation in managed environment
- Resource quotas (CPU/Memory limits)
- Secret injection support

---

## 💰 Cost Estimation (Monthly - Production)

| Service | SKU/Config | Estimated Cost |
|---------|-----------|-----------------|
| Container Apps | 0.25 CPU, 0.5GB RAM × 3 replicas | $40-60 |
| Application Gateway | WAF v2, 2 instances | $300-350 |
| Public IP | Static | $2.73 |
| Key Vault | Standard SKU | $0.60 |
| Storage Account | LRS, Standard | $15-25 |
| Front Door | Standard | $0.65/day (~$19) |
| DNS Zone | 1 zone | $0.50 |
| Log Analytics | PerGB2018 | $2.30/GB ingested |
| **Total (Estimated)** | | **$380-460** |

*Note: Costs vary by region; East US pricing assumed. Front Door Standard is significantly cheaper than Premium.*

---

## 🚀 Deployment & Operations

### **Initial Deployment**:
```bash
cd /cms
terraform init          # Download modules
terraform plan          # Review changes
terraform apply         # Deploy infrastructure
```

### **Output Values** (Post-Deployment):
```
Application Gateway IP: xxx.xxx.xxx.xxx
Container App FQDN: cms-container-app.xxxxx.azurecontainerapps.io
Front Door Endpoint: cms-frontend.azureedge.net
DNS Zone Nameservers: ns1-4.azure-dns.com
Log Analytics Workspace ID: /subscriptions/.../workspaces/cms-log-analytics
```

### **Post-Deployment Configuration**:
1. Update DNS records at registrar (point to Azure NS servers)
2. Upload SSL certificate to Key Vault (or use self-signed)
3. Replace nginx image with actual CMS container
4. Configure storage account for static content
5. Set up monitoring alerts in Log Analytics

---

## 📈 Scalability Roadmap

### **Phase 1** (Current): Single-region deployment
- ✅ CMS app in one region (East US)
- ✅ Global CDN via Front Door
- ✅ Automatic local scaling (1-3 replicas)

### **Phase 2**: Enhanced security
- 🔄 Network Security Groups (NSGs)
- 🔄 Private endpoints for storage
- 🔄 Advanced WAF rules

### **Phase 3**: Multi-region
- 🔄 Secondary Container Apps environment (West Europe)
- 🔄 Geo-redundant storage
- 🔄 Traffic manager for active-active setup

### **Phase 4**: Advanced operations
- 🔄 Automated backup/restore
- 🔄 Blue-green deployments
- 🔄 Custom domain SSL certificates (Let's Encrypt integration)
- 🔄 DDoS advanced protection

---

## 🎯 Key Design Decisions

| Decision | Rationale | Trade-off |
|----------|-----------|-----------|
| **Container Apps** vs AKS | Simplicity, managed service | Less control over orchestration |
| **Application Gateway WAF v2** | Enterprise security | Cost ($300+/month) |
| **Front Door Standard** | Global CDN at reasonable cost | No Premium features (SSL offload) |
| **Single VNet** | Simplicity for POC/MVP | Future: Add spoke networks for multi-tier |
| **LRS Storage** | Cost-effective | Data not geo-redundant (GRS option exists) |
| **30-day Log Retention** | Cost control | Limited historical analysis (increase as needed) |

---

## 🔍 Monitoring & Alerts

**Critical Metrics to Monitor**:
```kusto
// Replica count changes
ContainerAppConsoleLogs
| where EventType == "ReplicaScaled"
| summarize by ReplicaCount, timestamp

// Error rates
ContainerAppConsoleLogs
| where LogLevel == "ERROR"
| summarize ErrorCount = count() by bin(timestamp, 5m)

// WAF blocks
AzureDiagnostics
| where ResourceType == "APPLICATIONGATEWAYS"
| where Category == "ApplicationGatewayFirewallLog"
| summarize BlockedCount = count() by action_s
```

---

## 📝 Next Steps

1. **Customize Container Image**: Replace `nginx:latest` with actual CMS image
2. **Configure SSL Certificate**: Upload production certificate to Key Vault
3. **Set Up DNS**: Configure domain registrar to use Azure nameservers
4. **Storage Configuration**: Add containers and setup CDN origin
5. **Monitoring**: Create Log Analytics dashboards and alerts
6. **Testing**: Load testing via Front Door endpoint
7. **Backup Strategy**: Implement database backup procedures

---

## 📚 Quick Reference

| Component | Terraform Module | Purpose |
|-----------|-----------------|---------|
| Resource Group | terraform-azurerm-resource-group | Container for all resources |
| Container App Env | terraform-azurerm-container-app-environment | Runtime platform |
| Container App | terraform-azurerm-container-app | CMS application |
| Virtual Network | terraform-azurerm-virtual-network | Network infrastructure |
| App Gateway | terraform-azurerm-application-gateway | WAF + Load balancer |
| Key Vault | terraform-azurerm-key-vault | Secrets management |
| Storage Account | terraform-azurerm-storage-account | Data storage |
| Front Door | terraform-azurerm-frontdoor | Global CDN |
| DNS | terraform-azurerm-dns | Domain management |
| Log Analytics | terraform-azurerm-log-analytics | Monitoring |

---

## ✅ Summary

The CMS infrastructure represents a **modern, cloud-native approach** to hosting content management systems on Azure. It combines:

- ✅ **Serverless compute** (Container Apps) for cost efficiency
- ✅ **Enterprise security** (WAF, DDoS, encryption)
- ✅ **Global performance** (Front Door CDN)
- ✅ **Operational excellence** (Log Analytics, auto-scaling)
- ✅ **Infrastructure-as-Code** (Terraform for reproducibility)

This architecture scales from POC to production-grade deployments with minimal operational overhead.

create complete production-grade Azure architecture using Terraform that includes:

⸻

1️⃣ Azure Resource Group

A container for all resources:
	•	rg-containerapp-prod

⸻

2️⃣ Azure Container Apps (Your App Runtime)
	•	Runs your containerized workload (e.g., NGINX, Node.js, APIs)
	•	Auto-scaling, serverless platform
	•	Public ingress → but later routed behind the Application Gateway

Resources:
	•	azurerm_container_app_environment
	•	azurerm_container_app

⸻

3️⃣ Application Gateway (Load Balancer + WAF + SSL)

This acts as your central entry point for all web traffic.

It includes:
	•	HTTPS termination with SSL certificate from Key Vault
	•	WAF v2 enabled (OWASP security rules)
	•	Backend target → Container Apps FQDN
	•	Public static IP
	•	Listener on port 443

Resources:
	•	azurerm_public_ip
	•	azurerm_application_gateway
	•	azurerm_virtual_network
	•	azurerm_subnet

⸻

4️⃣ SSL Certificate in Azure Key Vault
	•	Self-signed in our example (can be replaced with real cert)
	•	Stored securely
	•	Attached to the Application Gateway

Resources:
	•	azurerm_key_vault
	•	azurerm_key_vault_certificate

⸻

5️⃣ Azure Storage Account

For:
	•	Static content
	•	File uploads
	•	Logs
	•	CDN origin

Resources:
	•	azurerm_storage_account
	•	azurerm_storage_container

⸻

6️⃣ Azure CDN (FrontDoor Standard)

Provides:
	•	Global CDN caching
	•	Low latency delivery
	•	Supports custom domain
	•	Can host your www.example.com hostname

Resources:
	•	azurerm_cdn_frontdoor_profile
	•	azurerm_cdn_frontdoor_endpoint
	•	azurerm_cdn_frontdoor_origin_group
	•	azurerm_cdn_frontdoor_origin
	•	(Optional) azurerm_cdn_frontdoor_custom_domain

⸻

7️⃣ Azure DNS Zone

This allows your domain to be fully managed in Azure.

Resources:
	•	azurerm_dns_zone

⸻

8️⃣ DNS Records

Two types we added:

Apex domain (@)

Example:
example.com → App Gateway Public IP

Resources:
	•	azurerm_dns_a_record
	•	azurerm_dns_cname_record

⸻

9️⃣ Log Analytics Workspace

Used by Container Apps for logs & metrics.

Resources:
	•	azurerm_log_analytics_workspace



and create the diagram using mermaid
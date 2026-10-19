# MM Events on Azure

Terraform for running MM Events in your own Azure subscription: the Spring Boot API on
Azure Container Apps, MySQL 8 on Azure Database for MySQL Flexible Server, secrets in
Key Vault and the static Nuxt site on Azure Static Web Apps.

![Azure architecture](../../diagrams/azure.png)

| Piece | Service | Notes |
|---|---|---|
| Backend image | Azure Container Registry (Basic) | Admin user disabled; pulled with a managed identity |
| API | Container Apps (Consumption), 0.5 vCPU / 1 GiB, 0-2 replicas | `railway` Spring profile, startup and liveness probes on `/actuator/health` |
| Database | MySQL Flexible Server 8.0, `B_Standard_B1ms`, 20 GB | VNet-integrated, no public endpoint, TLS required, 7-day backups |
| Secrets | Key Vault (RBAC) | DB password and JWT secret, referenced by the Container App |
| Frontend | Static Web Apps (Free) | Global, HTTPS, SPA fallback from `staticwebapp.config.json` |
| Logs | Log Analytics workspace | 30 days |

Design choices:

- **Private database.** The Container Apps environment and MySQL share a VNet
  (`snet-apps` /23 and `snet-mysql` /24, each delegated to its service). MySQL resolves
  through a private DNS zone and has no public access.
- **Managed identity everywhere.** One user-assigned identity has `AcrPull` on the
  registry and `Key Vault Secrets User` on the vault. The Container App's secrets are Key
  Vault references, so the values never appear in the app definition.
- **No secrets in Terraform state.** Both values come from ephemeral `random_password`
  resources and are written with write-only arguments (`value_wo`,
  `administrator_password_wo`). Bump `secret_version` to generate new ones.
- **Two origins.** The site is on `*.azurestaticapps.net` and the API on
  `*.azurecontainerapps.io`; the API's `APP_CORS_ALLOWED_ORIGINS` is set to the site's URL.

## Prerequisites

- An Azure subscription you own, and `az login` as a user with **Owner** (or Contributor +
  User Access Administrator) on it: Terraform creates role assignments.
- Terraform 1.11 or newer (or the `hashicorp/terraform` Docker image), the Azure CLI,
  Docker, Node.js 20.
- If `apply` complains about an unregistered resource provider, register it once, e.g.
  `az provider register --namespace Microsoft.App`.

## Deploy

All commands start in `deploy/terraform/azure`.

```bash
cp terraform.tfvars.example terraform.tfvars   # set subscription_id
terraform init
```

**1. Create the registry first**, so that the Container App has an image to start:

```bash
terraform apply -target=azurerm_container_registry.main
```

**2. Build and push the backend image:**

```bash
ACR=$(az acr list --resource-group rg-mm-events --query '[0].name' -o tsv)
az acr login --name "$ACR"
docker build --platform linux/amd64 -t "$ACR.azurecr.io/backend:latest" ../../../main_backend
docker push "$ACR.azurecr.io/backend:latest"
```

**3. Create everything else** (MySQL takes about 10 minutes; the first apply also waits
60 seconds for the role assignments to take effect):

```bash
terraform plan -out tfplan
terraform apply tfplan
curl "$(terraform output -raw health_url)"     # {"status":"UP"}; the first call wakes the app
```

**4. Build and upload the frontend:**

```bash
API=$(terraform output -raw api_base_url)
export SWA_CLI_DEPLOYMENT_TOKEN=$(terraform output -raw static_web_app_deployment_token)

cd ../../../main_frontend/concert1
npm ci --legacy-peer-deps
NUXT_PUBLIC_BACKEND_BASE_URL="$API" npx nuxt generate
cp ../../deploy/terraform/azure/staticwebapp.config.json .output/public/
npx --yes @azure/static-web-apps-cli deploy .output/public --env production
unset SWA_CLI_DEPLOYMENT_TOKEN
```

The deployment token is a credential: keep it out of files, logs and chat. Open
`terraform output -raw frontend_url`. Flyway creates the schema on the first start.

## Day-to-day

- **New backend version:** push a new tag and set `image_tag`, then `terraform apply`. If
  you push over `latest`, run
  `az containerapp update --name ca-mm-events-backend --resource-group rg-mm-events --image "$ACR.azurecr.io/backend:latest"`.
- **Logs:** `az containerapp logs show --name ca-mm-events-backend --resource-group rg-mm-events --follow`
- **Cold starts:** with `min_replicas = 0` the first request after an idle period waits
  for Spring Boot to start. Set `min_replicas = 1` to avoid it, at about USD 20-25 a month
  more.

## Rough monthly cost

List prices in Southeast Asia, scale to zero, little traffic. Check the
[Azure Pricing Calculator](https://azure.microsoft.com/pricing/calculator/) before you
deploy.

| Item | USD / month |
|---|---|
| MySQL Flexible Server `B_Standard_B1ms` + 20 GB | ~18 |
| Container Registry Basic | ~5 |
| Container Apps (requests only, mostly free grant) | ~0-5 |
| Log Analytics, Key Vault, private DNS zone | ~2 |
| Static Web Apps Free | 0 |
| **Total** | **~25-30** |

## Destroy

```bash
terraform destroy
```

This deletes the resource group with the database and its backups. The provider is set
to purge the soft-deleted Key Vault, so the same names can be used again.

## Limits

- Photo uploads (`/api/upload`) use AWS S3 in the code and are not available here, as in
  the Railway demo.
- The login rate limit is kept in memory per replica.

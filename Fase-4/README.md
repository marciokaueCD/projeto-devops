# Fase 4 — Terraform (IaC)

> **Objetivo:** transformar toda a infraestrutura criada manualmente na Fase 3 — Resource Group, ACR, Container Apps Environment, Container App — em código declarativo, versionado, e recriável com um único comando.

## Contexto

Na Fase 3, cada recurso foi criado clicando no Portal do Azure. Isso funciona, mas tem um custo real: recriar o ambiente (nova região, novo ambiente de staging, ou recuperação de um erro) significa repetir todos os cliques manualmente, com risco de divergência e sem nenhum registro do que foi feito.

Esta fase resolve isso descrevendo toda a infraestrutura como código, usando **Terraform**.

## Estrutura do projeto

```
statusboard/
├── modules/
│   ├── resource_group/      # cria o Resource Group
│   ├── acr/                  # cria o Azure Container Registry
│   └── container_app/        # cria Environment, identidade, permissão e o Container App
│
├── lab/                 
│   ├── backend.tf         # onde o state fica armazenado
│   ├── main.tf             # chama os módulos
│   ├── variables.tf
│   ├── terraform.tfvars
│   └── outputs.tf
```

Cada módulo segue o padrão de 3 arquivos (`main.tf`, `variables.tf`, `outputs.tf`) — um define **o que** o módulo cria, outro **o que ele precisa receber**, e o terceiro **o que ele devolve** para outros módulos usarem.

## Decisões técnicas de produção

### State remoto, não local

O `.tfstate` (registro do que já foi criado) fica num Azure Storage Account dedicado, não na máquina local. Isso evita dois problemas: perda do arquivo de state, e conflito se mais de uma pessoa/pipeline rodar Terraform ao mesmo tempo (o backend remoto tem lock automático).

```hcl
backend "azurerm" {
    use_cli              = true                                    
    use_azuread_auth     = true                                    
    tenant_id            = "7185686c-e569-4a0f-b10b-0c839bbd4d8c"  
    storage_account_name = "tfstatestatusboard"                              
    container_name       = "tfstate"                               
    key                  = "statusboard-lab.tfstate"    
}
```

> Esse Storage Account é o único recurso do projeto que precisa ser criado manualmente, uma única vez, antes do primeiro `terraform init` — é um problema inevitável (o Terraform não pode criar o lugar onde ele mesmo vai guardar seu registro).

### Módulos reutilizáveis, não um único arquivo

Cada tipo de recurso vive em seu próprio módulo. Isso permite reusar a mesma definição em múltiplos ambientes (`dev`, `staging`, `prod`) sem duplicar código — só os valores em `terraform.tfvars` mudam.

### Identidade gerenciada por usuário (User-Assigned), não por sistema

O Container App precisa de permissão para puxar imagens do ACR. A abordagem inicial usava identidade `SystemAssigned` (a mais simples), mas isso criava uma **dependência circular**: a permissão só pode ser concedida depois que o Container App existe (porque precisa do `principal_id` dele), mas o Container App tenta puxar a imagem *durante* sua própria criação — antes de ter permissão pra isso. O resultado era erro de timeout (`Operation expired`) depois de ~20 minutos tentando.

A correção foi usar uma **identidade criada separadamente** (`azurerm_user_assigned_identity`), que existe de forma independente do Container App. Isso permite conceder a permissão `AcrPull` **antes** do Container App ser criado, quebrando o ciclo:

```
identidade criada → permissão concedida → Container App criado (já com permissão válida)
```

Também sem senha/usuário compartilhado do ACR (`admin_enabled = false`) — autenticação via identidade é rastreável e segue o princípio de menor privilégio.

### `resource_provider_registrations = "none"`

Por padrão, o provider `azurerm` varre e tenta registrar mais de 200 Resource Providers da Azure a cada `plan`/`apply`, mesmo os que o projeto não usa — isso tornava comandos simples lentos (vários minutos). Como os providers necessários aqui (`Microsoft.ContainerRegistry`, `Microsoft.App`) já vêm registrados por padrão em qualquer assinatura nova, essa varredura foi desativada.

### `lifecycle { ignore_changes = [template[0].container[0].image] }`

Depois que existir CI/CD (Fase 5) ou GitOps atualizando a imagem em produção, o Terraform precisa **parar de gerenciar esse campo especificamente** — senão o próximo `terraform apply` de rotina reverteria a imagem para o valor antigo do `.tfvars`, brigando com o pipeline de deploy. Terraform continua dono da infraestrutura; o pipeline passa a ser dono de qual imagem está rodando.

## Problema de ordem: infraestrutura vs. imagem da aplicação

O ACR nasce vazio. O Container App, por outro lado, precisa de uma imagem válida para conseguir provisionar sua primeira revisão. Isso cria uma dependência circular entre **criar a infraestrutura** e **ter uma imagem publicada nela**.

A solução adotada foi separar os dois ciclos, ao invés de tentar resolver tudo num único `apply`:

**1. Primeiro apply — só a infraestrutura, com uma imagem pública placeholder:**
```bash
terraform apply
```
A variável `container_image` tem um valor `default` público (`mcr.microsoft.com/azuredocs/containerapps-helloworld:latest`), que não depende do ACR nem de nenhum push prévio — garante que a infraestrutura toda suba sem depender da aplicação.

**2. Publicar a imagem real no ACR recém-criado:**
```bash
az acr login --name acrstatusboardprod
docker tag statusboard:v1.0 acrstatusboardprod.azurecr.io/statusboard:v1.0
docker push acrstatusboardprod.azurecr.io/statusboard:v1.0
```

**3. Segundo apply — agora só atualiza a imagem do Container App já existente:**
```bash
terraform apply -var="container_image=acrstatusboardprod.azurecr.io/statusboard:v1.0"
```

Esse segundo `apply` é uma **atualização** de um recurso que já existe, não uma criação do zero — muito mais confiável do que tentar fazer tudo de uma vez.

> Essa separação manual entre "infraestrutura pronta" e "imagem publicada" é exatamente o gap que a Fase 5 (CI/CD) e, futuramente, GitOps, vêm resolver — automatizando essa sequência de dois passos.

## Problemas reais encontrados (e como foram resolvidos)

Vale documentar esses incidentes.

| Problema | Causa | Solução |
|---|---|---|
| `plan` demorando vários minutos | Provider varrendo 200+ Resource Providers da Azure | `resource_provider_registrations = "none"` |
| `Operation expired` após ~20 min criando o Container App | Dependência circular entre identidade `SystemAssigned` e a permissão `AcrPull` | Migrar para identidade `UserAssigned`, criada antes do Container App |
| `ManagedEnvironmentCapacityHeavyUsageError` | Falta de capacidade da Azure na região `East US` para novos Container Apps Environments | Trocar de região (`East US 2`) |
| `MANIFEST_UNKNOWN: manifest tagged by "v1.0" is not found` | Container App tentou subir antes da imagem real estar publicada no ACR | Separar em dois `apply`s: infraestrutura com placeholder primeiro, imagem real depois |

## Como rodar

```bash
cd statusboard/lab
terraform init
terraform plan
terraform apply
```

## Antes vs depois

| | Fase 3 (manual) | Fase 4 (Terraform) |
|---|---|---|
| Como criar a infra | Cliques no Portal | `terraform apply` |
| Reprodutibilidade | Baixa | Alta — mesmo código, mesmo resultado |
| Versionamento da infra | Nenhum | Código versionado no Git |
| Autenticação do Container App no ACR | Usuário/senha admin | Identidade gerenciada, permissão mínima necessária |
| Recuperação de erros | Refazer manualmente | `terraform import` / `terraform state` |

## Próxima fase

Hoje, publicar uma nova versão da aplicação exige rodar `docker push` e `terraform apply -var=...` manualmente, na ordem certa. A Fase 5 (CD) automatiza exatamente essa sequência — o pipeline passa a fazer o push e a atualização da imagem sozinho, a cada mudança aprovada.
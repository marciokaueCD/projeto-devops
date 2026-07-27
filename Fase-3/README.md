# Fase 3 — Cloud (Azure)

> **Objetivo:** publicar o StatusBoard num ambiente real e acessível publicamente, saindo do ambiente descartável do CI (Fase 2) para uma infraestrutura persistente na nuvem. Todos os recursos desta fase foram criados manualmente pelo Portal do Azure.

## Contexto

Até a Fase 2, o CI garante que a imagem Docker builda corretamente a cada push, mas ela nunca sai do runner do GitHub Actions — é descartada ao final de cada execução. Essa fase resolve isso: a imagem passa a existir de forma permanente num registry, e a aplicação passa a rodar num serviço gerenciado, com uma URL pública real.

O deploy aqui é **manual de propósito** — o objetivo é entender cada recurso e decisão do Azure antes de automatizá-los via Terraform (Fase 4) e CD (Fase 5).

## Recursos criados no Portal

### 1. Resource Group

Agrupa todos os recursos dessa fase sob um mesmo escopo de gerenciamento e billing.

- Nome: `rg_statusboard`
- Região: `East US`

### 2. Azure Container Registry (ACR)

Onde a imagem Docker do StatusBoard fica armazenada.

- Nome: `projetodevops`
- SKU: `Basic`

### 3. Azure Container Apps Environment

Ambiente gerenciado onde o Container App roda — cuida de rede, logs e escalonamento.

- Nome: `projeto-devops-app`
- Região: East US

### 4. Azure Container App

O serviço que efetivamente executa a imagem e expõe a aplicação publicamente.

- Nome: `projeto-devops-app`
- Porta de destino: `80`
- Ingress: `externo` (necessário para gerar URL pública)
- Registry: conectado ao `projetodevops`, imagem `statusboard:v1.0`

## Enviando a imagem para o ACR

Mesmo com os recursos criados via portal, o envio da imagem para o registry ainda depende do Docker CLI:

```bash
# login no portal do azure e selecionamos a assinatura
az login
# login no acr
az acr login --name projetodevops
# marcar a imagem local com o endereço do registry
docker tag statusboard:v1.0 acrstatusboard.azurecr.io/app/statusboard:v1.0

# enviar a imagem
docker push acrstatusboard.azurecr.io/statusboard:v1.0
```

Depois do push, no portal, a imagem aparece em **Container Registry → Repositories → app/statusboard**, e pode ser selecionada diretamente na configuração do Container App.

## Decisões técnicas

**Por que ACR e não Docker Hub** — integração nativa com autenticação do Azure, e todos os recursos ficam sob o mesmo Resource Group, facilitando gerenciamento de permissões e custo.

**Por que Container Apps e não App Service** — Container Apps é feito especificamente para rodar containers com escalonamento automático, e é o passo intermediário natural antes do Kubernetes de verdade na [Fase 6].

**Por que via portal nesta fase** — o objetivo é primeiro entender visualmente cada recurso, sua configuração e suas dependências, antes de expressá-los como código (Terraform, na próxima fase). Criar manualmente também deixa claro, na prática, todo o trabalho repetitivo que a automação da Fase 4 elimina.

## Como validar

1. No portal, abrir **Container Apps → projeto-devops-app → Overview**
2. Copiar a **Application Url** exibida
3. Acessar essa URL no navegador e confirmar que o StatusBoard carrega normalmente, com os dados do `services.json`

## Antes vs depois

| | Fase 2 (CI) | Fase 3 (Cloud) |
|---|---|---|
| Onde a imagem existe | Descartada ao fim do workflow | Armazenada permanentemente no ACR |
| Acesso | Nenhum — só o próprio pipeline | URL pública, qualquer pessoa acessa |
| Como os recursos são criados | Não se aplica | Manual, via Portal do Azure |
| Reprodutibilidade da infra | Não se aplica | Baixa — depende de recriar tudo na mão |

## Limitação desta fase (gancho para a próxima)

Criar esses quatro recursos manualmente já revela o problema que a automação resolve: se esse ambiente precisar ser recriado — em outra região, para um ambiente de staging, ou depois de uma exclusão acidental — é necessário repetir todos os cliques manualmente, com risco real de esquecer uma configuração ou digitar algo diferente da primeira vez.

Isso motiva a Fase 4 (Terraform), onde toda essa infraestrutura passa a ser descrita como código, versionada e recriável com um único comando.

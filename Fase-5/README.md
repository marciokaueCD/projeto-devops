# Fase 5 — CD completo (CI/CD)

> **Objetivo:** automatizar a sequência que era feita manualmente desde a Fase 4 — build da imagem, push pro ACR, atualização da infraestrutura via Terraform — para que um merge aprovado na `main` faça tudo isso sozinho.

## Contexto

Na Fase 4, publicar uma nova versão do StatusBoard exigia rodar `docker push` e `terraform apply -var=...` manualmente, na ordem certa. Esta fase estende o pipeline de CI da Fase 2 — que só valida o build — adicionando os passos que efetivamente **entregam** a aplicação em produção.

```
CI (Fase 2)              CD (Fase 5, esta fase)
   ↓                           ↓
build + smoke test    →   docker push (ACR)
                       →   terraform apply -var (atualiza a imagem)
```

## Decisões técnicas

### Autenticação via OIDC, sem secret de longa duração

Em vez de gerar uma credencial de Service Principal e armazenar como secret fixo, o pipeline autentica na Azure via **OpenID Connect (OIDC)**: o GitHub Actions troca um token de curta duração por acesso temporário à Azure, sem nenhuma senha armazenada em lugar nenhum.

```bash
az ad app create --display-name "github-statusboard-cd"
az ad sp create --id <APP_ID>   # cria o Service Principal — não é automático em toda criação via CLI

az ad app federated-credential create \
  --id <APP_ID> \
  --parameters '{
    "name": "statusboard-main-branch",
    "issuer": "https://token.actions.githubusercontent.com",
    "subject": "repo:SEU_USUARIO/statusboard:ref:refs/heads/main",
    "audiences": ["api://AzureADTokenExchange"]
  }'
```

### `github.sha` como tag de imagem, não uma tag fixa

Tags fixas (`v1.0`) sofrem de mutabilidade — sobrescrever a mesma tag não garante que o Container App perceba a mudança. Usar o hash do commit como tag garante que cada deploy é único, imutável e rastreável: dá pra saber exatamente qual commit está rodando em produção a qualquer momento.

### Dependência entre CI e CD: `workflow_run`

Inicialmente, CI e CD disparavam em paralelo, ambos no evento `push` — sem nenhuma relação entre eles. Isso é uma falha de design: o CD podia publicar uma imagem em produção mesmo que o CI, rodando ao mesmo tempo, viesse a reprovar o mesmo commit. CI existe pra validar **antes** de entregar, não ao lado da entrega.

A correção foi fazer o CD **esperar a conclusão do CI**, usando `workflow_run`:

```yaml
on:
  workflow_run:
    workflows: ["CI"]   # precisa bater exatamente com o "name:" do workflow de CI
    types: [completed]
    branches: [main]

jobs:
  deploy:
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
```

O CD só executa depois que o workflow chamado `CI` terminar, e só segue adiante se a conclusão for `success` — se o CI falhar, o job de deploy nem chega a rodar.

### Pegadinha do `workflow_run`: qual commit é buildado

Por padrão, `actions/checkout` no evento `workflow_run` faz checkout do estado **atual** da branch — não necessariamente do commit que o CI validou. Se alguém fizer um novo push entre o CI terminar e o CD começar, o CD acabaria buildando um commit que **nunca passou pelo CI**. A correção é fixar o commit explicitamente:

```yaml
- name: Checkout do código
  uses: actions/checkout@v4
  with:
    ref: ${{ github.event.workflow_run.head_sha }}
```

## O workflow

```yaml
name: CD

on:
  workflow_run:
    workflows: ["CI"]
    types: [completed]
    branches: [main]

permissions:
  id-token: write   # obrigatório para o OIDC
  contents: read

jobs:
  deploy:
    runs-on: ubuntu-latest
    if: ${{ github.event.workflow_run.conclusion == 'success' }}
    defaults:
      run:
        working-directory: ./app

    steps:
      - name: Checkout do código
        uses: actions/checkout@v4
        with:
          ref: ${{ github.event.workflow_run.head_sha }}
    
      - name: Checkout do código
        uses: actions/checkout@v4
            
      - name: Login na Azure via OIDC
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Login no ACR
        run: az acr login --name acrstatusboardlab

      - name: Definir a tag da imagem
        run: echo "IMAGE_TAG=${{ github.event.workflow_run.head_sha || github.sha }}" >> $GITHUB_ENV

      - name: Build e tag da imagem
        run: |
          docker build -t acrstatusboardlab.azurecr.io/statusboard:${{ github.sha }} .
          docker tag acrstatusboardlab.azurecr.io/statusboard:${{ github.sha }} \
                     acrstatusboardlab.azurecr.io/statusboard:latest

      - name: Push da imagem
        run: |
          docker push acrstatusboardlab.azurecr.io/statusboard:${{ github.sha }}
          docker push acrstatusboardlab.azurecr.io/statusboard:latest
          
      - name: Instalar o Terraform
        uses: hashicorp/setup-terraform@v3
        with:
          terraform_version: "1.16.1"   # Estou travando a versão, evitando a surpresa se sair uma nova
    
      - name: Terraform apply (atualiza a imagem em produção)
        working-directory: ./Fase-4/statusboard/lab
        run: |
          terraform init
          terraform apply -auto-approve \
            -var="container_image=acrstatusboardlab.azurecr.io/statusboard:${{ github.sha }}"
```
### Permissões RBAC necessárias para o Service Principal do CD

| Escopo | Role |
|---|---|
| Storage Account do state (backend Terraform) | `Storage Blob Data Contributor` |
| Resource Group da aplicação | `Contributor` |
| ACR | `AcrPush` |

## Problemas reais encontrados (e como foram resolvidos)

| Problema | Causa | Solução |
|---|---|---|
| `terraform: command not found` | Runner `ubuntu-latest` não vem com Terraform pré-instalado | Adicionar o step `hashicorp/setup-terraform@v3`, com versão travada |
| CD publicava em produção mesmo sem o CI ter validado o commit | CI e CD disparavam em paralelo, ambos no evento `push`, sem nenhuma dependência entre eles | Encadear o CD ao CI via `workflow_run`, com `if: conclusion == 'success'` e checkout fixado em `workflow_run.head_sha` |

### Subject claim imutável do OIDC (problema específico de timing)

Ao seguir a [documentação oficial da Microsoft sobre deploy via GitHub Actions](https://learn.microsoft.com/en-us/azure/app-service/deploy-github-actions?tabs=openid%2Caspnetcore%2Cpython#generate-deployment-credentials) para configurar a `federated-credential`, o `subject` foi montado no formato tradicional:

```
repo:SEU_USUARIO/statusboard:ref:refs/heads/main
```

Esse é o formato documentado pela Microsoft (última atualização da página em novembro de 2025). Porém, o GitHub [anunciou em abril de 2026](https://github.blog/changelog/2026-04-23-immutable-subject-claims-for-github-actions-oidc-tokens/) uma mudança no formato padrão do `sub` (subject claim) dos tokens OIDC: **a partir de 15 de julho de 2026, todo repositório novo passou a usar automaticamente um formato com identificadores imutáveis do dono e do repositório**, em vez de apenas os nomes:

```
repo:octocat@123456/my-repo@456789:ref:refs/heads/main
```

Esse formato é mais seguro — nomes de usuário/repositório podem ser reciclados (alguém exclui uma conta, outra pessoa registra o mesmo nome depois), o que permitiria a um novo dono gerar tokens que ainda seriam aceitos por configurações OIDC antigas confiando apenas no nome. O ID numérico anexado nunca é reaproveitado.

Como o repositório deste projeto foi criado **depois** de 15 de julho de 2026, o GitHub passou a emitir tokens no novo formato automaticamente — mas a documentação da Microsoft, que serviu de base para configurar a `federated-credential`, ainda ensina o formato antigo. Isso gera uma incompatibilidade: o `subject` real do token (`repo:usuario@123.../statusboard@456...:ref:...`) não bate com o `subject` cadastrado na credencial federada da Azure (`repo:usuario/statusboard:ref:...`), resultando em falha de autenticação mesmo com toda a configuração aparentemente correta.

**Como resolver:** conferir o formato exato do `subject` usado pelo repositório antes de cadastrar a `federated-credential` — o GitHub disponibiliza um endpoint de preview e um toggle nas configurações OIDC do repositório/organização justamente para isso. Como alternativa mais simples, é possível também desativar o formato imutável para o repositório (mantendo o formato tradicional, compatível com a documentação da Microsoft), embora isso abra mão da proteção adicional contra reciclagem de nomes.

## Antes vs depois

| | Fase 4 (Terraform manual) | Fase 5 (CD completo) |
|---|---|---|
| Deploy de nova versão | `docker push` + `terraform apply -var` manuais | Automático a cada push na `main` |
| Autenticação com a Azure | `az login` interativo, na sua máquina | OIDC, sem credencial armazenada |
| Rastreabilidade da imagem | Tag fixa, fácil de perder controle | Tag = hash do commit, sempre rastreável |
| Risco de erro humano | Alto — múltiplos passos manuais, ordem importa | Baixo — sequência sempre idêntica |
| Relação entre validação e entrega | Não existia CD | CD só roda se o CI, no mesmo commit, tiver concluído com sucesso |

## Próxima fase

Esse pipeline ainda faz deploy direto num único Container App. A Fase 6 (Kubernetes) introduz um ambiente mais sofisticado, onde conceitos como múltiplas réplicas geridas de forma granular fazem mais sentido de implementar.
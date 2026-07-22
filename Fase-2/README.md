# Fase 2 — CI (GitHub Actions)

> **Objetivo:** automatizar a verificação de que a imagem Docker do StatusBoard continua buildando e funcionando corretamente a cada mudança no código, sem depender de testes manuais antes do push.

## Contexto

Na [Fase 1](../01-docker/README.md), o Dockerfile já garantia que a aplicação rodasse de forma reprodutível — mas validar isso ainda dependia de rodar `docker build` e `docker run` manualmente, na máquina local, sempre que algo mudasse.

CI (Continuous Integration) resolve esse ponto: a cada `push` ou `pull request`, um pipeline roda automaticamente e confirma que o build continua saudável. Se algo quebrar, isso aparece na hora, direto no GitHub — antes de qualquer decisão sobre deploy.

## O workflow

```yaml
name: CI
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

env:
  IMAGE_TAG: statusboard:v1.0

jobs:
  build-and-verify:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout do código
        uses: actions/checkout@v4

      - name: Build da imagem Docker
        run: docker build -t ${{ env.IMAGE_TAG }} ./app

      - name: Rodar o container
        run: docker run -d -p 8080:80 --name statusboard ${{ env.IMAGE_TAG }}

      - name: Verificar se a aplicação responde
        run: |
          sleep 3
          curl --fail http://localhost:8080 || exit 1

      - name: Parar o container
        run: docker stop statusboard
```

### O que cada parte faz

| Bloco | Função |
|---|---|
| `on: push / pull_request` | Dispara o pipeline em todo push na `main` e em todo PR aberto contra ela — valida o código antes de ser mesclado |
| `env: IMAGE_TAG` | Centraliza a tag da imagem em um único lugar, evitando divergência entre os steps de build e run |
| `actions/checkout@v4` | Baixa o código do repositório pro ambiente do runner |
| `docker build` | Reproduz, de forma automática, a mesma validação feita manualmente na Fase 1 |
| `docker run` | Sobe o container a partir da imagem recém-buildada |
| `curl --fail` | Smoke test: confirma que a aplicação realmente responde na porta esperada, não só que o container existe |
| `docker stop` | Encerra o container ao final do job, liberando o runner |

## Antes vs depois

| | Fase 1 (Docker) | Fase 2 (CI) |
|---|---|---|
| Quando o build é validado | Manualmente, quando alguém lembra de rodar | Automaticamente, a cada push/PR |
| Onde a validação acontece | Máquina local | Runner do GitHub Actions |
| Visibilidade de falhas | Só quem rodou localmente sabe | Visível pra qualquer colaborador, direto no PR |
| Reusabilidade | N/A | Caminho de build fixo (`./app`), independe da fase |

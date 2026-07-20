# StatusBoard

Painel de status de infraestrutura no estilo split-flap (painel de aeroporto), construído em HTML, CSS e JavaScript puro — sem frameworks, sem build step.

Essa é a **aplicação base** do projeto DevOps. Ela é intencionalmente simples: o foco do projeto não é o código da aplicação, e sim a infraestrutura e automação construídas em volta dela ao longo das fases (Docker, CI, cloud, Terraform, CD, Kubernetes, observabilidade e segurança).

## Rodando localmente (Fase 0 — baseline manual)

Não há dependências para instalar. Basta servir os arquivos estáticos:

```bash
# Opção 1: Python
python3 -m http.server 8080

# Opção 2: Node (npx, sem instalação)
npx serve .
```

Acesse `http://localhost:8080`.

## Rodando via Docker (Fase 1)

```bash
docker build -t statusboard .
docker run -p 8080:80 statusboard
```

Acesse `http://localhost:8080`.

## Estrutura

```
statusboard/
├── index.html          # marcação principal do painel
├── css/style.css        # identidade visual (tema split-flap)
├── js/script.js          # relógio, fetch dos dados, renderização das linhas
├── data/services.json    # dados mockados dos serviços monitorados
├── Dockerfile
└── .dockerignore
```

## Sobre os dados

Os dados em `data/services.json` são mockados. Nas fases futuras (observabilidade, Fase 7), esse arquivo pode ser substituído por uma API real conectada a métricas de monitoramento de verdade.

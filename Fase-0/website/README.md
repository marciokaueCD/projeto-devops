# StatusBoard

Painel de status de infraestrutura no estilo split-flap (painel de aeroporto), construído em HTML, CSS e JavaScript puro.

Essa é a **aplicação base** do projeto DevOps. Ela é intencionalmente simples: o foco do projeto não é o código da aplicação, e sim a infraestrutura e automação construídas em volta dela ao longo das fases (Docker, CI, cloud, Terraform, CD, Kubernetes, observabilidade e segurança).

## Rodando localmente (Fase 0 — baseline manual)

```
# Opção 1: Python
python3 -m http.server 8080

Acesse `http://localhost:8080`.

# Opção 2: VScode (Instalar a extenção "Live Server")
Clique com o botão direito do mouse no index.html e selecione "Open with Live Server".
```
<img width="954" height="573" alt="image" src="https://github.com/user-attachments/assets/dd263b5c-d615-4bce-b70f-947c6be15767" />

## Estrutura

```
statusboard/
├── index.html          # marcação principal do painel
├── style.css        # identidade visual (tema split-flap)
├── script.js          # relógio, fetch dos dados, renderização das linhas
├── services.json    # dados mockados dos serviços monitorados
```

## Sobre os dados

Os dados em `services.json` são mockados.

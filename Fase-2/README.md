# Fase 1 — Docker

> **Objetivo:** empacotar o StatusBoard num container, garantindo que ele rode de forma idêntica em qualquer máquina, sem depender de instalação manual de servidor ou dependências.

## Contexto

Na [Fase 0], rodar o StatusBoard exigia iniciar manualmente um servidor local (`python3 -m http.server` ou `extensão Live Server do VScode`). Isso funciona para desenvolvimento, mas cria problemas reais em produção:

- Depende de quem for rodar ter as ferramentas certas instaladas
- Nenhuma garantia de que o ambiente de quem builda é igual ao de quem executa
- Não há um jeito padronizado de expor a aplicação para monitoramento, orquestração ou deploy

Docker resolve isso empacotando a aplicação **e** o servidor que a serve dentro de uma imagem única, versionada e portátil.

## Decisões técnicas

### Por que Nginx como servidor

O StatusBoard é uma aplicação 100% estática (HTML, CSS, JS puro, sem backend). Nginx é uma escolha padrão de mercado para servir esse tipo de conteúdo: leve, rápido, e com uma imagem oficial `alpine` muito reduzida.


### O healthcheck

```dockerfile
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q --spider http://localhost || exit 1
```

Verifica a cada 30 segundos se o Nginx está respondendo dentro do container. Isso é o que permite ao Docker (e, futuramente, a orquestradores como Kubernetes na Fase 6) saber se o container está saudável ou precisa ser reiniciado/substituído — sem essa configuração, o Docker só sabe se o processo está *rodando*, não se está *funcionando*.

## Dockerfile

```dockerfile
# Imagem base - Nginx alpine (Versão leve e otimizada)
FROM nginx:alpine

# Instrução para copiar os arquivos do diretorio "X" para a imagem
COPY website/ /usr/share/nginx/html

# Expondo a porta de acesso
EXPOSE 80

# Verificação da saúde do sistema
HEALTHCHECK --interval=30s --timeout=3s \
  CMD wget -q --spider http://localhost || exit 1

# Comandos CMD para forçar o Nginx rodar em primeiro plano, evitando morrer pelo Docker
CMD [ "nginx", "-g", "daemon off;"]
```

## Como rodar

```bash
# build da imagem
docker build -t statusboard:v1.0 .

# executar o container
docker run -d -p 8080:80 --name statusboard statusboard:v1.0
```

Acesse: `http://localhost:8080`

### Verificando o healthcheck

```bash
docker ps
```

Após ~30 segundos, a coluna `STATUS` deve exibir `(healthy)`.

### Verificando o tamanho da imagem

```bash
docker images statusboard:v1.0
```

IMAGE              ID             DISK USAGE   CONTENT SIZE   EXTRA
statusboard:v1.0   a9b6e9fc1bae       91.3MB         26.1MB        

A imagem final é pequena porque herda de `nginx:alpine`, uma distribuição Linux minimalista, e não carrega nenhuma ferramenta de build.


## Antes vs depois

| | Fase 0 (manual) | Fase 1 (Docker) |
|---|---|---|
| Como rodar | Instalar Python/extensão e iniciar servidor manualmente | `docker build` + `docker run` |
| Reprodutibilidade | Depende do ambiente de quem executa | Idêntico em qualquer máquina com Docker |
| Verificação de saúde | Nenhuma | Healthcheck automático a cada 30s |
| Portabilidade | Baixa | Alta — a imagem roda igual localmente, em CI ou na nuvem |

## Próxima fase

Com a imagem funcionando localmente, o próximo passo é automatizar sua construção e validação a cada alteração no código, antes de decidir onde ela vai rodar em produção — isso é o que a [Fase 2 (CI)] resolve.
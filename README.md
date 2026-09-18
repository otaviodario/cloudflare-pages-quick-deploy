<div align="center">

# ⚡ Cloudflare Universal Quick Deployer
### Automated CLI Deployer for Cloudflare Pages & Cloudflare Workers

🌐 **Language / Idioma:**  
[🇧🇷 Português](#-português) • [🇺🇸 English](#-english)

</div>

---

# 🇧🇷 Português

Utilitário de automação CLI desenvolvido em **Batch Script** e **Node.js** voltado para desenvolvedores, estudantes e engenheiros que desejam publicar e atualizar aplicações no **Cloudflare Pages** e no **Cloudflare Workers** de forma instantânea, interativa e **100% livre da dependência do Git**.

O projeto foi concebido sob a filosofia do *"deploy raiz e pragmático"*: focado em eliminar a complexidade de esteiras pesadas de CI/CD, comandos longos de terminal ou riscos de sobrescrever configurações de nuvem acidentalmente quando o objetivo é testar, prototipar ou atualizar um serviço em produção com velocidade.

---

### ✨ Principais Recursos

- 🌐 **Multi-Serviço Unificado:** Alterne em um menu simples entre deploys de frontend (**Pages**) e backend (**Workers**).
- 🛡️ **Preservação Automática de Bindings no Worker:** Ao atualizar o código de um Worker via API, o script faz a inspeção em tempo real e **preserva automaticamente** todas as suas vinculações existentes (**KV Namespaces, D1 Databases, R2 Buckets, Queues, Services, Variáveis de Ambiente e Secrets**), evitando que bindings sejam apagadas.
- 📦 **Suporte Amplo a Formatos (Drag & Drop):**
  - **Pages:** Arraste pastas de build (`dist`, `build`, `public`) ou arquivos compactados `.ZIP` (descompactados automaticamente na memória).
  - **Workers:** Arraste arquivos de script `.js`, `.ts` ou até mesmo `.txt` (convertidos automaticamente).
- 👥 **Seletor Dinâmico de Múltiplas Contas:** Consulta todas as contas vinculadas à sua autenticação Cloudflare e gera um menu numerado para alternância ágil.
- 🔢 **Menu Interativo e Indexado:** Chega de digitar nomes longos de cabeça. O script lista seus projetos do Pages e scripts de Workers existentes com numeração (`[1]`, `[2]`, `[3]...`), permitindo seleção rápida com apenas um número ou tecla `ENTER`.
- 🪟 **Sem Lixo & Encoding UTF-8 Nativo:** Padronizado em `chcp 65001` (sem bugs visuais/Mojibake no Windows) e com rotina rigorosa de limpeza de arquivos temporários e caches residuais (`.wrangler`).

---

### 🏗️ Arquitetura de Integração e Fluxo de Dados

```text
+-------------------------------------------------------------------------+
|                        FLUXO LOCAL "SEM DEPENDÊNCIA GIT"                |
|                                                                         |
|  [ Frontend / Pasta / ZIP ]  OU  [ Worker Script (.js / .ts / .txt) ]   |
+------------------------------------+------------------------------------+
                                     |
                                     v (Arrastar e Soltar no Terminal)
+-------------------------------------------------------------------------+
|                      PIPELINE LOCAL (deploy_cf.bat)                     |
|                                                                         |
|  1. Limpeza de Caches Residuais (.wrangler e temporários)              |
|  2. Seletor de Contas Cloudflare (Conexão Segura via Wrangler Auth)     |
|  3. Extração Dinâmica de Metadados via Node.js                         |
|  4. Indexação Numérica de Projetos (Pages) ou Scripts (Workers)         |
|  5. [Workers] Snapshot & Blindagem de Bindings (KV, D1, Secrets)       |
+------------------------------------+------------------------------------+
                                     |
                    +----------------+----------------+
                    |                                 |
                    v (Fluxo 1: Pages)                v (Fluxo 2: Workers)
+------------------------------------+   +------------------------------------+
|     CLOUDFLARE PAGES (EDGE CDN)    |   |     CLOUDFLARE WORKERS (RUNTIME)   |
|                                    |   |                                    |
|   Upload Direto de Assets Estáticos|   |   Deploy Multipart via REST API    |
|   com Publicação Imediata (.pages) |   |   mantendo Recursos e Variáveis    |
+------------------------------------+   +------------------------------------+
```

---

### 📂 Mapeamento de Arquivos do Repositório

```text
├── deploy_cf.bat        # Executável CLI interativo unificado (dois cliques para rodar)
├── .gitignore           # Ignora caches temporários e resíduos locais
├── LICENSE              # Licença de uso público permissiva (MIT)
└── README.md            # Documentação técnica e guia de utilização
```

---

### ⚙️ Como Usar no Dia a Dia

#### Pré-requisitos:
* **Windows** 10 / 11.
* **Node.js** instalado (que inclui `npx`).
* Estar autenticado no Wrangler (caso não esteja, a CLI solicitará login via navegador automaticamente na primeira execução).

---

#### 🚀 Passo a Passo:

1. Dê **dois cliques** no arquivo `deploy_cf.bat`.
2. Escolha o serviço que deseja atualizar:
   - Digite `1` para **Cloudflare Pages**.
   - Digite `2` para **Cloudflare Worker**.
3. **Informe o arquivo ou pasta:**
   - Para **Pages**: Arraste a pasta do site/build ou um arquivo `.zip` e tecle `ENTER`.
   - Para **Worker**: Arraste o arquivo `.js`, `.ts` ou `.txt` do seu script e tecle `ENTER`.
4. **Escolha a conta da Cloudflare** digitando o número correspondente na lista exibida.
5. **Selecione o Projeto / Worker:**
   - Digite o número correspondente ao projeto exibido no menu (ou tecle `ENTER` para o primeiro da lista).
6. **Pronto!** O deploy será compilado/sincronizado e o status de sucesso será exibido em tela.

---

### 🔒 Segurança e Práticas de Engenharia Aplicadas

* **Zero Exposição de Credenciais:** Nenhum token, senha ou chave de API fica hardcoded no script. As requisições utilizam o token dinâmico da sessão autenticada do Wrangler.
* **Tratamento de Strings e Caminhos do Windows:** O script remove aspas adicionadas pelo explorador de arquivos e trata espaços em branco em nomes de pastas e arquivos.
* **Isolamento de Estado:** A cada execução, arquivos e diretórios temporários criados em `%TEMP%` são sumariamente destruídos após a conclusão do deploy.
* **Compatibilidade de Secrets:** O payload multipart do Worker é sanitizado para não colidir com a política de chaves restritas/criptografadas da Cloudflare API (código de erro 10021).

---
---

# 🇺🇸 English

A lightweight CLI automation utility built with **Batch Script** and **Node.js** designed for developers, students, and engineers who want to deploy and update applications on **Cloudflare Pages** and **Cloudflare Workers** instantly, interactively, and **completely free from Git dependencies**.

This project embraces a pragmatic approach: eliminating the overhead of complex CI/CD pipelines, long terminal commands, or the risk of accidentally wiping out cloud resources when prototyping, testing, or pushing quick updates to production.

---

### ✨ Key Features

- 🌐 **Unified Multi-Service:** Seamlessly switch between frontend (**Pages**) and backend (**Workers**) deployments from an interactive menu.
- 🛡️ **Automated Worker Bindings Preservation:** Inspects script bindings in real-time before uploading code via Cloudflare REST API and **safely preserves** all existing resources (**KV Namespaces, D1 Databases, R2 Buckets, Queues, Service Bindings, Environment Variables, and Secrets**).
- 📦 **Versatile Drag-and-Drop Support:**
  - **Pages:** Drag any build folder (`dist`, `build`, `public`) or `.ZIP` archive (auto-extracted in memory).
  - **Workers:** Drag `.js`, `.ts`, or even plain `.txt` script files (auto-converted to `.js`).
- 👥 **Dynamic Multi-Account Switcher:** Discovers all accounts linked to your Cloudflare session and presents a numbered selection menu.
- 🔢 **Numbered Interactive Menus:** No more memorizing project names. The script fetches and indexes your existing Pages projects and Workers with numeric choices (`[1]`, `[2]`, `[3]...`), allowing fast deployment by typing a number or hitting `ENTER`.
- 🪟 **Clean Environment & Native UTF-8:** Standardized on `chcp 65001` (preventing Windows mojibake) with automatic cleanup of temporary files and `.wrangler` session caches.

---

### 🏗️ Architecture & Data Flow

```text
+-------------------------------------------------------------------------+
|                         LOCAL "NO-GIT" WORKFLOW                         |
|                                                                         |
|   [ Static Folder / .ZIP ]   OR   [ Worker Script (.js / .ts / .txt) ]  |
+------------------------------------+------------------------------------+
                                     |
                                     v (Drag & Drop into Terminal)
+-------------------------------------------------------------------------+
|                      LOCAL PIPELINE (deploy_cf.bat)                     |
|                                                                         |
|  1. Residual Cache Cleanup (.wrangler and temp files)                   |
|  2. Account Selection (Authenticated via Wrangler OAuth)                |
|  3. Metadata Extraction & Indexing via Node.js                          |
|  4. Numbered Project / Worker Selection Menu                            |
|  5. [Workers] Snapshot & Preservation of Bindings (KV, D1, Secrets)     |
+------------------------------------+------------------------------------+
                                     |
                    +----------------+----------------+
                    |                                 |
                    v (Flow 1: Pages)                 v (Flow 2: Workers)
+------------------------------------+   +------------------------------------+
|     CLOUDFLARE PAGES (EDGE CDN)    |   |     CLOUDFLARE WORKERS (RUNTIME)   |
|                                    |   |                                    |
|   Direct Static Asset Upload       |   |   Multipart REST API Script Deploy |
|   Immediate Edge Global Deploy     |   |   Retaining all Resources & Secrets|
+------------------------------------+   +------------------------------------+
```

---

### 📂 Repository File Structure

```text
├── deploy_cf.bat        # Main CLI executable (double-click to run)
├── .gitignore           # Ignores temp files and local caches
├── LICENSE              # Permissive MIT License
└── README.md            # Technical documentation and user guide
```

---

### ⚙️ Quick Start Guide

#### Prerequisites:
* **Windows** 10 / 11.
* **Node.js** installed (includes `npx`).
* Authenticated with Wrangler (if not logged in, Wrangler will open the browser for a one-click login on first run).

---

#### 🚀 How to Use:

1. **Double-click** on `deploy_cf.bat`.
2. Choose the service to update:
   - Type `1` for **Cloudflare Pages**.
   - Type `2` for **Cloudflare Worker**.
3. **Provide files:**
   - For **Pages**: Drag and drop your project folder or `.zip` file and press `ENTER`.
   - For **Worker**: Drag and drop your `.js`, `.ts`, or `.txt` file and press `ENTER`.
4. **Select your Cloudflare Account** from the numbered list.
5. **Select the Project / Worker:**
   - Type the number of the project from the list (or press `ENTER` to select default `[1]`).
6. **Done!** The deployment is uploaded, synchronized, and the live status is shown immediately.

---

### 🔒 Security & Engineering Best Practices

* **Zero Hardcoded Secrets:** No API keys, credentials, or account IDs are stored in the script. Authentication relies dynamically on Wrangler's secure session token.
* **Path & String Sanitization:** Cleans quotes and handles paths with spaces automatically.
* **Hermetic Execution:** Temporary unzipped folders and cache files created in `%TEMP%` are deleted immediately upon completion.
* **Cloudflare API Error 10021 Mitigation:** Filters write-only secret bindings from multipart payloads, preventing API validation errors while preserving secrets on the Worker runtime.

---

### 📄 License

This project is licensed under the [MIT License](LICENSE) — free for personal, educational, and commercial use.
```

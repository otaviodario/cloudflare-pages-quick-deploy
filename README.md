```markdown
# Cloudflare Pages Interactive Deployer

Utilitário de automação CLI desenvolvido em Batch Script e Node.js voltado para desenvolvedores, estudantes e entusiastas que desejam publicar aplicações no **Cloudflare Pages de forma rápida, direta e sem depender do Git**. O projeto foi concebido sob a filosofia do *"deploy raiz"*: focado em eliminar barreiras de entrada, atritos com esteiras complexas de CI/CD e sobrecargas de versionamento quando o objetivo é apenas prototipar, estudar ou colocar um site no ar imediatamente.

A ferramenta estabelece uma ponte dinâmica entre os arquivos locais do desenvolvedor e a infraestrutura de Edge da Cloudflare. Por padrão, ela monitora uma pasta de trabalho local (`C:\Users\User\Desktop\page`), oferecendo suporte nativo para arrastar e soltar (*drag-and-drop*) qualquer outro diretório na janela do terminal, integrando seleção interativa de múltiplas contas e listagem numerada dos projetos existentes.

---

### 📌 Desafios Resolvidos

* **Atrito com Git para Testes e Aprendizado:** Para quem está aprendendo desenvolvimento web, criando protótipos ou subindo páginas simples, ter que inicializar repositórios Git, gerenciar branches e configurar GitHub Actions representa uma barreira de complexidade desnecessária.
* **O "Modo Raiz" com Produtividade Moderna:** Permite publicar arquivos estáticos instantaneamente (HTML/CSS/JS ou builds de React/Vue/Vite) sem abrir mão da infraestrutura global da Cloudflare e sem digitar comandos longos.
* **Ambiguidade em Múltiplas Contas:** A CLI padrão do Wrangler costuma travar na última conta utilizada via cache local (`.wrangler`). O script isola as sessões e força a seleção dinâmica da conta correta a cada execução.
* **Falta de Menu de Projetos no Wrangler:** Em vez de exigir que o usuário digite o nome exato do projeto de cabeça, o script consulta a API em tempo real e monta um menu numerado (`[1]`, `[2]`, `[3]...`), bastando teclar um número ou pressionar `ENTER`.
* **Correção de Caracteres no Windows (Mojibake):** Padronização nativa em UTF-8 (`chcp 65001`), evitando falhas visuais de texto e renderizando ícones e status de forma limpa no prompt de comando.

---

### 🎯 Público-Alvo e Casos de Uso

* **Iniciantes e Estudantes:** Pratique HTML, CSS e JavaScript e coloque seu site online em segundos com URL pública segura (`.pages.dev`), sem precisar aprender Git no primeiro dia.
* **Testes Rápidos e Prototipagem:** Suba versões de demonstração para validação com clientes em tempo recorde.
* **Devs Pragmáticos ("Modo Raiz"):** Quem já domina o ecossistema, mas prefere a agilidade de arrastar uma pasta de build para o terminal e ver o deploy concluído sem poluir o histórico do Git com commits de teste.

---

### 🏗️ Arquitetura de Integração e Fluxo de Dados

```text
+-------------------------------------------------------------------------+
|                          FLUXO LOCAL "SEM GIT"                          |
|                                                                         |
|  [ Pasta Local / Build ] ---> ( Arrastar e Soltar ou ENTER Padrão )     |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                  PIPELINE LOCAL (deploy_cf.bat)                         |
|                                                                         |
|  1. Limpeza de Cache Residual (.wrangler)                               |
|  2. Seletor de Contas Cloudflare (Conexão Segura em Terminal)           |
|  3. Extração Dinâmica de Metadados via Node.js                          |
|  4. Indexação Numérica dos Projetos Existentes                          |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                       CLOUDFLARE PAGES (EDGE CDN)                       |
|                                                                         |
|  [ Upload dos Arquivos ]  ---> [ Publicação Imediata na CDN Global ]    |
+-------------------------------------------------------------------------+
```

1. **Captura Descomplicada de Arquivos:** Aceita a pasta padrão ou o caminho de qualquer pasta arrastada para dentro do terminal, removendo automaticamente aspas e espaços.
2. **Isolamento de Credenciais:** Limpa sessões residuais antes e depois de cada operação, garantindo que contas pessoais e de clientes nunca se misturem.
3. **Mecanismo de Listagem:** Aciona o backend do Wrangler e processa o retorno via Node.js para indexar os sites disponíveis na conta escolhida.
4. **Deploy Direto ao Edge:** Sincroniza apenas os arquivos modificados diretamente com os servidores da Cloudflare, devolvendo o link do site pronto para acesso.

---

### 📂 Mapeamento de Componentes e Responsabilidades

```text
├── deploy_cf.bat        # Script executável principal (dois cliques para rodar)
├── .gitignore           # Ignora dependências e arquivos temporários locais
├── LICENSE              # Licença de uso público (MIT)
└── README.md            # Documentação orientada à facilidade de uso
```

1. **`deploy_cf.bat`:**
   * Script unificado que automatiza 100% da interação sem exigir instalação prévia global de pacotes (utiliza `npx`).
   * Valida a integridade das pastas locais informadas.
   * Coordena o diálogo com o Cloudflare Wrangler e a formatação das opções em tela.

---

### ⚙️ Principais Workflows do Ecossistema

#### Fluxograma Visual de Decisão

```text
          [ Dois Cliques no Script ]
                     │
                     ▼
         [ Informar Pasta Local ]
         ├─► (ENTER) -> Usa pasta padrão no Desktop
         └─► (Arrastar) -> Usa qualquer pasta do computador
                     │
                     ▼
       [ Escolher Conta Cloudflare ]
                     │
                     ▼
     [ Menu Numerado de Projetos ]
         ├─► (ENTER) -> Seleciona o 1º da lista
         └─► (Digitar Número) -> Seleciona projeto correspondente
                     │
                     ▼
    [ Deploy Concluído na Nuvem ]
```

#### Como Usar no Dia a Dia:
1. Dê dois cliques em `deploy_cf.bat`.
2. Aperte **ENTER** para usar a pasta padrão ou simplesmente **arraste para dentro da janela** a pasta que você quer publicar e aperte **ENTER**.
3. Escolha a sua conta Cloudflare com as setinhas do teclado.
4. O terminal mostrará todos os seus projetos numerados (`[1]`, `[2]`, `[3]...`). Digite o número correspondente ou aperte **ENTER** para o primeiro.
5. Pronto! O link com o site publicado aparece na hora.

---

### 🔒 Segurança e Práticas de Engenharia Aplicadas

* **Zero Exposição de Chaves:** Nenhum token, senha ou ID de conta fica gravado no código. A autenticação é delegada de ponta a ponta ao fluxo oficial e seguro da Cloudflare.
* **Ambiente Sempre Limpo:** Ao final de cada execução, qualquer cache local ou diretório temporário gerado no processo é sumariamente excluído, não deixando lixo na Área de Trabalho.
* **Tratamento de Entradas do Usuário:** O script é blindado contra caminhos inválidos, aspas duplas adicionadas pelo sistema operacional e erros acidentais de digitação nos números dos projetos.
```

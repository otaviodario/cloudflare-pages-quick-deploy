```markdown
# Cloudflare Pages Interactive Deployer

Utilitário de automação CLI desenvolvido em Batch Script e Node.js para simplificar o ciclo de entrega contínua e deploy manual de aplicações estáticas no Cloudflare Pages. O script estabelece uma ponte dinâmica entre o desenvolvedor e a API da Cloudflare, introduzindo seleção interativa em tempo real para múltiplos perfis de conta e menus numerados de indexação de projetos existentes.

A solução elimina a necessidade de memorizar comandos complexos de terminal, IDs de contas ou nomes exatos de projetos. Por padrão, o ambiente aponta para uma pasta pré-configurada (`C:\Users\User\Desktop\page`), oferecendo suporte nativo para arrastar e soltar (*drag-and-drop*) qualquer outro diretório diretamente na janela do terminal, garantindo deploys rápidos, isolados e livres de contaminação de cache.

---

### 📌 Desafios Resolvidos

* **Ambiguidade de Múltiplas Contas:** A CLI oficial da Cloudflare (`wrangler`) memoriza a última conta utilizada em pastas locais (`.wrangler`), resultando frequentemente em deploys enviados inadvertidamente para a conta de cliente ou organização incorreta.
* **Ausência de Menus Interativos na CLI Oficial:** No fluxo padrão do Wrangler Pages, se o nome do projeto não for informado como argumento de linha de comando, o usuário é obrigado a digitar a string exata de cabeça, sem listagem seletiva por índice numérico.
* **Atrito em Operações Manuais:** A necessidade de navegar por diretórios, abrir o painel web da Cloudflare para conferir nomes de domínios ou copiar caminhos extensos no explorador de arquivos tornava o processo de deploy lento e propenso a erros de digitação.
* **Corrupção de Caracteres no Windows (Mojibake):** Tratamento de codificações legadas do CMD (CP850/CP1252), forçando execução padronizada em UTF-8 com renderização perfeita de emojis, acentuação e feedbacks visuais.

---

### 🏗️ Arquitetura de Integração e Fluxo de Dados

```text
+-------------------------------------------------------------------------+
|                          AMBIENTE DO USUÁRIO                            |
|                                                                         |
|  [ Pasta do Projeto ]  ---> ( Arrastar / Colar ou ENTER Padrão )        |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                  PIPELINE LOCAL (deploy-pages.bat)                      |
|                                                                         |
|  1. Limpeza de Sessão (.wrangler)                                       |
|  2. Conexão TTY Interativa (Wrangler Authentication)                   |
|  3. Extração e Sanitização de Metadados via Node.js Engine             |
|  4. Indexação e Montagem do Menu Numerado [1..N]                        |
+------------------------------------+------------------------------------+
                                     |
                                     v
+-------------------------------------------------------------------------+
|                       CLOUDFLARE PAGES API / EDGE                       |
|                                                                         |
|  [ Autenticação de Conta ] ---> [ Deploy de Arquivos ] ---> [ Live URL ]|
+-------------------------------------------------------------------------+
```

1. **Camada de Entrada (Terminal CLI):** Captura o diretório-alvo do deploy, sanitiza aspas residuais inseridas por operações de arraste no Windows e define a codificação global UTF-8 (`chcp 65001`).
2. **Camada de Isolamento de Sessão:** Remove recursivamente resquícios de arquivos de configuração locais antes de cada execução, forçando o Wrangler a apresentar o seletor nativo de contas da Cloudflare.
3. **Mecanismo de Consulta e Parsing:** Invoca o Wrangler em formato JSON intermediário e processa o payload via runtime do Node.js, isolando a propriedade do projeto e normalizando diferentes assinaturas de resposta da API.
4. **Camada de Execução (Deploy):** Dispara a sincronização de deltas dos arquivos para o Edge da Cloudflare vinculado estritamente ao projeto escolhido pelo índice e finaliza com higienização do ambiente.

---

### 📂 Mapeamento de Componentes e Responsabilidades

```text
├── deploy-pages.bat     # Script orquestrador principal para Windows
├── .gitignore           # Exclusão de arquivos temporários e dependências locais
└── README.md            # Documentação técnica e guia operacional do projeto
```

1. **`deploy-pages.bat`:**
   * Configura o terminal para a página de código UTF-8 (`65001`).
   * Valida a existência do diretório padrão ou recebe um caminho dinâmico via terminal.
   * Dispara a autenticação interativa e o seletor de contas do Cloudflare.
   * Converte a resposta estruturada dos projetos em variáveis indexadas (`!PROJ_1!`, `!PROJ_2!`).
   * Executa o comando `wrangler pages deploy` e limpa diretórios temporários `.wrangler`.

---

### ⚙️ Principais Workflows do Ecossistema

#### Fluxograma Lógico de Decisão e Deploy

```text
          [ Início do Script ]
                   │
                   ▼
      [ Sanitizar Cache .wrangler ]
                   │
                   ▼
     [ Solicitar Pasta do Projeto ]
                   │
                   ├─► (ENTER) -> Usa C:\Users\User\Desktop\page
                   └─► (Arrastar Pasta) -> Usa Novo Caminho Informado
                   │
                   ▼
   [ Executar Seletor de Contas Cloudflare ]
                   │
                   ▼
   [ Node.js extrai JSON da Conta Ativa ]
                   │
                   ▼
   [ Apresentar Menu Numerado de Projetos ]
                   │
                   ├─► (ENTER) -> Seleciona Opção [1] (Default)
                   └─► (Digitar N) -> Seleciona Opção [N]
                   │
                   ▼
    [ Executar Deploy no Cloudflare Pages ]
                   │
                   ▼
       [ Limpar Cache .wrangler ]
                   │
                   ▼
               [ Fim ]
```

#### Passo a Passo da Operação:
1. **Definição da Origem:** O usuário inicia o script. Ao pressionar `ENTER`, assume a pasta de trabalho padrão (`Desktop\page`). Se desejar publicar outro site, basta arrastar qualquer pasta para dentro da janela e dar `ENTER`.
2. **Seleção de Contexto (Conta):** O script abre o menu interativo com as credenciais salvas no Cloudflare. O usuário navega via setas (`↑` e `↓`) e confirma a conta desejada.
3. **Escolha por Índice:** O sistema carrega dinamicamente os projetos existentes naquela conta específica e monta a listagem (`[1] painelfinanceiro`, `[2] outro-site`, etc.). Basta digitar o número correspondente.
4. **Finalização Automática:** O deploy é concluído, o endereço `pages.dev` gerado é exibido no console e os rastros de autenticação local são removidos com segurança.

---

### 🔒 Segurança e Práticas de Engenharia Aplicadas

* **Isolamento e Prevenção de Poluição de Diretório:** O script limpa programaticamente as pastas `.wrangler` geradas na raiz de execução e no diretório de assets, impedindo que credenciais locais de sessão fiquem expostas ou salvas na Área de Trabalho.
* **Sanitização de Caminhos e Entradas:** O tratamento de expansão de variáveis atrasada (`EnableDelayedExpansion`) e remoção automática de aspas garante estabilidade mesmo ao processar pastas com caracteres especiais ou espaços no caminho.
* **Comunicação Segura Delegada:** Nenhuma chave de API ou token secreto fica gravado no código-fonte. O script delega todo o ciclo de autorização para o mecanismo oficial do OAuth do Cloudflare Wrangler.
```

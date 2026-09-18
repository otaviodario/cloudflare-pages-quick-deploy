@echo off
chcp 65001 >nul
title Deploy Cloudflare Pages
setlocal EnableDelayedExpansion

:: 1. Limpa qualquer conta em cache para sempre abrir o seletor de contas
if exist "%~dp0.wrangler" rd /s /q "%~dp0.wrangler"

echo ======================================================
echo           DEPLOY NO CLOUDFLARE PAGES
echo ======================================================
echo.

:: 2. PASTA DO PROJETO
set "PASTA_PADRAO=C:\Users\User\Desktop\page"
echo [1/3] PASTA DOS ARQUIVOS:
echo Pressione ENTER para usar a padrao: !PASTA_PADRAO!
echo Ou arraste/cole o caminho de outra pasta:
set /p "PASTA=> "

if defined PASTA set "PASTA=!PASTA:"=!"
if "%PASTA%"=="" set "PASTA=!PASTA_PADRAO!"

if not exist "%PASTA%" (
    echo.
    echo ❌ Erro: A pasta informada nao existe: "%PASTA%"
    pause
    exit /b
)
echo -^> Pasta selecionada: "%PASTA%"
echo.

:: 3. CONECTA AO CLOUDFLARE E SELECIONA A CONTA
echo ======================================================
echo [2/3] CONECTANDO AO CLOUDFLARE...
echo ======================================================
echo Escolha a conta abaixo usando as setinhas (↑ / ↓) e tecle ENTER:
echo.

call npx.cmd --yes wrangler pages project list

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ❌ Erro ao conectar com o Cloudflare.
    pause
    exit /b
)

:: 4. INDEXAÇÃO NUMERADA DOS PROJETOS
echo.
echo ======================================================
echo [3/3] CARREGANDO MENU DE PROJETOS...
echo ======================================================

set total_proj=0
set "TEMP_PROJS=%TEMP%\cf_projects_list.txt"
if exist "%TEMP_PROJS%" del "%TEMP_PROJS%"

:: Extrai os nomes dos projetos cobrindo String, Array e Objeto sem caracteres conflitantes
node -e "const {execSync}=require('child_process'); try { const raw = execSync('npx.cmd --yes wrangler pages project list --json', {encoding:'utf8', stdio:['ignore','pipe','ignore']}); const j = raw.substring(raw.indexOf('['), raw.lastIndexOf(']')+1); JSON.parse(j).forEach(p => { const n = (typeof p == 'string') ? p : (Array.isArray(p) ? p[0] : (p['Project Name'] || p.name || p.Name || Object.values(p)[0])); console.log(n); }); } catch(e) {}" > "%TEMP_PROJS%"

:: Exibe as opções numeradas
for /f "usebackq delims=" %%P in ("%TEMP_PROJS%") do (
    set /a total_proj+=1
    set "PROJ_!total_proj!=%%P"
    echo   [!total_proj!] %%P
)
if exist "%TEMP_PROJS%" del "%TEMP_PROJS%"

if %total_proj% EQU 0 (
    echo.
    set /p "PROJETO=Digite o nome do projeto manualmente: "
) else (
    echo.
    :perguntar_numero
    set /p "NUM_PROJ=Digite o numero do projeto [ENTER para 1 - !PROJ_1!]: "
    if "!NUM_PROJ!"=="" set "NUM_PROJ=1"

    set "PROJETO="
    for %%I in (!NUM_PROJ!) do set "PROJETO=!PROJ_%%I!"

    if "!PROJETO!"=="" (
        echo ❌ Numero invalido. Digite um numero entre 1 e !total_proj!.
        goto perguntar_numero
    )
)

echo.
echo -^> Projeto escolhido: !PROJETO!

:: 5. EXECUÇÃO DO DEPLOY
echo.
echo ======================================================
echo 🚀 Enviando "%PASTA%" para o projeto "!PROJETO!"...
echo ======================================================
echo.

call npx.cmd --yes wrangler pages deploy "%PASTA%" --project-name="!PROJETO!"

:: Limpeza do cache para sempre perguntar a conta na próxima vez
if exist "%~dp0.wrangler" rd /s /q "%~dp0.wrangler"
if exist "%PASTA%\.wrangler" rd /s /q "%PASTA%\.wrangler"

echo.
if %ERRORLEVEL% EQU 0 (
    echo ✅ Deploy concluído com sucesso em '!PROJETO!'!
) else (
    echo ❌ Ocorreu um erro durante o deploy.
)

echo.
pause
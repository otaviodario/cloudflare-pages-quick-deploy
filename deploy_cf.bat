@echo off
chcp 65001 >nul
title Cloudflare Deployer - Universal (Pages & Workers)
setlocal EnableDelayedExpansion

:: 1. Initial cleanup of caches and temporary files
if exist "%~dp0.wrangler" rd /s /q "%~dp0.wrangler"
if exist "%TEMP%\cf_deploy_unzipped" rd /s /q "%TEMP%\cf_deploy_unzipped"
if exist "%TEMP%\worker_deploy_temp.js" del /f /q "%TEMP%\worker_deploy_temp.js"
if exist "%TEMP%\cf_accounts_list.txt" del /f /q "%TEMP%\cf_accounts_list.txt"
if exist "%TEMP%\cf_workers_list.txt" del /f /q "%TEMP%\cf_workers_list.txt"
if exist "%TEMP%\cf_deploy_ok.txt" del /f /q "%TEMP%\cf_deploy_ok.txt"

:menu_type
cls
echo ======================================================
echo           Cloudflare Universal Deployer
echo ======================================================
echo.
echo [1/3] What do you want to update?
echo   [1] Cloudflare Pages (Frontend)
echo   [2] Cloudflare Worker (Backend)
echo.
set "TYPE="
set /p "TYPE=Choose an option (1 or 2): "

if "!TYPE!"=="1" goto flow_pages
if "!TYPE!"=="2" goto flow_worker

echo Invalid option! Please enter 1 or 2.
timeout /t 2 >nul
goto menu_type

:: ======================================================
:: FLOW 1: PAGES (STATIC SITE / FRONTEND)
:: ======================================================
:flow_pages
echo.
echo ======================================================
echo [2/3] Site Files (PAGES)
echo ======================================================
echo 👉 Drag and drop the site FOLDER or a .ZIP file here:
set "INPUT="
set /p "INPUT=> "

if not defined INPUT (
    echo ❌ No path provided.
    goto flow_pages
)

set "INPUT=!INPUT:"=!"

if not exist "!INPUT!" (
    echo ❌ Error: The provided path does not exist!
    goto flow_pages
)

if exist "!INPUT!\*" (
    set "TARGET_DEPLOY=!INPUT!"
    goto execute_pages
)

for %%F in ("!INPUT!") do set "EXT=%%~xF"

if /i "!EXT!"==".zip" (
    echo.
    echo 📦 .ZIP file detected! Extracting temporarily...
    set "TARGET_DEPLOY=%TEMP%\cf_deploy_unzipped"
    if exist "!TARGET_DEPLOY!" rd /s /q "!TARGET_DEPLOY!"
    powershell -NoProfile -Command "Expand-Archive -LiteralPath '!INPUT!' -DestinationPath '!TARGET_DEPLOY!' -Force"
    goto execute_pages
)

echo.
echo ❌ ERROR: For Pages, you cannot drag a single file (!EXT!).
echo    👉 Drag the entire FOLDER or a compressed .ZIP file.
goto flow_pages

:execute_pages
echo.
echo ======================================================
echo [3/3] Connecting to Cloudflare...
echo ======================================================
echo Use the arrow keys (↑ / ↓) to select an account below and press ENTER:
echo.

call npx.cmd --yes wrangler pages project list
if !ERRORLEVEL! NEQ 0 (
    echo ❌ Error connecting to Cloudflare.
    goto end
)

echo.
echo ======================================================
echo SELECT PROJECT BY NUMBER:
echo ======================================================

set total_proj=0
set "TEMP_PROJS=%TEMP%\cf_projects_list.txt"
if exist "!TEMP_PROJS!" del "!TEMP_PROJS!"

node -e "const {execSync}=require('child_process'); try { const raw=execSync('npx.cmd --yes wrangler pages project list --json', {encoding:'utf8', stdio:['ignore','pipe','ignore']}); const j=raw.substring(raw.indexOf('['), raw.lastIndexOf(']')+1); JSON.parse(j).forEach(p => { const n = (typeof p == 'string') ? p : (Array.isArray(p) ? p[0] : (p['Project Name'] || p.name || p.Name || Object.values(p)[0])); console.log(n); }); } catch(e) {}" > "!TEMP_PROJS!"

for /f "usebackq delims=" %%P in ("!TEMP_PROJS!") do (
    set /a total_proj+=1
    set "PROJ_!total_proj!=%%P"
    echo   [!total_proj!] %%P
)
if exist "!TEMP_PROJS!" del "!TEMP_PROJS!"

if !total_proj! EQU 0 (
    echo.
    set /p "TARGET_FINAL=Enter project name manually: "
) else (
    echo.
    :ask_number_pages
    set "NUM_PROJ="
    set /p "NUM_PROJ=Enter project number [ENTER for 1 - !PROJ_1!]: "
    if not defined NUM_PROJ set "NUM_PROJ=1"

    set "TARGET_FINAL="
    for %%I in (!NUM_PROJ!) do (
        if defined PROJ_%%I set "TARGET_FINAL=!PROJ_%%I!"
    )
    if not defined TARGET_FINAL set "TARGET_FINAL=!NUM_PROJ!"
)

echo.
echo ======================================================
echo 🚀 Deploying to Pages project "!TARGET_FINAL!"...
echo ======================================================
echo.
call npx.cmd --yes wrangler pages deploy "!TARGET_DEPLOY!" --project-name="!TARGET_FINAL!"
if !ERRORLEVEL! EQU 0 (
    echo.
    echo ✅ Deploy to "!TARGET_FINAL!" completed successfully!
) else (
    echo.
    echo ❌ An error occurred during deployment.
)
goto end

:: ======================================================
:: FLOW 2: WORKER (WITH FULL BINDING PROTECTION)
:: ======================================================
:flow_worker
echo.
echo ======================================================
echo [2/3] Worker Script File
echo ======================================================
echo 👉 Drag and drop the Worker script file (.js / .ts / .txt) here:
set "INPUT="
set /p "INPUT=> "

if not defined INPUT (
    echo ❌ No path provided.
    goto flow_worker
)

set "INPUT=!INPUT:"=!"

if not exist "!INPUT!" (
    echo ❌ Error: The provided path does not exist: "!INPUT!"
    goto flow_worker
)

for %%F in ("!INPUT!") do (
    set "EXT=%%~xF"
    set "DEFAULT_WORKER_NAME=%%~nF"
)

if /i "!EXT!"==".txt" (
    echo.
    echo 📄 .TXT file detected! Converting to .js temporarily...
    set "TARGET_DEPLOY=%TEMP%\worker_deploy_temp.js"
    copy /y "!INPUT!" "!TARGET_DEPLOY!" >nul
) else (
    set "TARGET_DEPLOY=!INPUT!"
)

echo.
echo ======================================================
echo [3/3] Loading your Cloudflare accounts...
echo ======================================================

set total_acc=0
set "TEMP_ACCOUNTS=%TEMP%\cf_accounts_list.txt"
if exist "!TEMP_ACCOUNTS!" del "!TEMP_ACCOUNTS!"

node --input-type=module -e "import{execSync}from'child_process';try{const raw=execSync('npx.cmd --yes wrangler auth token --json',{encoding:'utf8',stdio:['ignore','pipe','ignore']});const token=JSON.parse(raw.slice(raw.indexOf('{'),raw.lastIndexOf('}')+1)).token;const r=await fetch('https://api.cloudflare.com/client/v4/accounts',{headers:{Authorization:'Bearer '+token}});const d=await r.json();if(d.result){d.result.forEach(a=>console.log(a.id+'|'+a.name));}}catch(e){}" > "!TEMP_ACCOUNTS!" 2>nul

for /f "usebackq tokens=1,2 delims=|" %%A in ("!TEMP_ACCOUNTS!") do (
    set /a total_acc+=1
    set "ACC_ID_!total_acc!=%%A"
    set "ACC_NAME_!total_acc!=%%B"
    echo   [!total_acc!] %%B
)
if exist "!TEMP_ACCOUNTS!" del "!TEMP_ACCOUNTS!"

if !total_acc! EQU 0 (
    echo ❌ No accounts found.
    pause
    goto end
)

:ask_account_worker
echo.
set "NUM_ACC="
set /p "NUM_ACC=Select account by number [ENTER for 1 - !ACC_NAME_1!]: "
if not defined NUM_ACC set "NUM_ACC=1"

set "ACCOUNT_ID="
set "ACCOUNT_NAME="
for %%I in (!NUM_ACC!) do (
    if defined ACC_ID_%%I (
        set "ACCOUNT_ID=!ACC_ID_%%I!"
        set "ACCOUNT_NAME=!ACC_NAME_%%I!"
    )
)

if not defined ACCOUNT_ID (
    echo ❌ Invalid option! Please enter a number between 1 and !total_acc!.
    goto ask_account_worker
)

echo.
echo ======================================================
echo Investigating Workers in account '!ACCOUNT_NAME!'...
echo ======================================================

set total_workers=0
set "TEMP_WORKERS=%TEMP%\cf_workers_list.txt"
if exist "!TEMP_WORKERS!" del "!TEMP_WORKERS!"

node --input-type=module -e "import{execSync}from'child_process';try{const raw=execSync('npx.cmd --yes wrangler auth token --json',{encoding:'utf8',stdio:['ignore','pipe','ignore']});const token=JSON.parse(raw.slice(raw.indexOf('{'),raw.lastIndexOf('}')+1)).token;const r=await fetch('https://api.cloudflare.com/client/v4/accounts/' + process.argv[1] + '/workers/scripts',{headers:{Authorization:'Bearer '+token}});const d=await r.json();if(d.result){d.result.forEach(w=>console.log(w.id));}}catch(e){}" "!ACCOUNT_ID!" > "!TEMP_WORKERS!" 2>nul

for /f "usebackq delims=" %%W in ("!TEMP_WORKERS!") do (
    set /a total_workers+=1
    set "WORKER_!total_workers!=%%W"
    echo   [!total_workers!] %%W
)
if exist "!TEMP_WORKERS!" del "!TEMP_WORKERS!"

echo   [0] Enter name manually
echo.

:ask_number_worker
set "CHOICE="
set /p "CHOICE=Enter Worker number (e.g., 5 for !WORKER_5!): "

if not defined CHOICE set "CHOICE=1"

set "TARGET_FINAL="
for %%I in (!CHOICE!) do (
    if defined WORKER_%%I set "TARGET_FINAL=!WORKER_%%I!"
)

if not defined TARGET_FINAL (
    if "!CHOICE!"=="0" (
        set /p "TARGET_FINAL=Enter exact Worker name: "
    ) else (
        set "TARGET_FINAL=!CHOICE!"
    )
)

if not defined TARGET_FINAL (
    echo ❌ Invalid option.
    goto ask_number_worker
)

echo.
echo -> Worker selected: !TARGET_FINAL! (Account: !ACCOUNT_NAME!)
echo.
echo ======================================================
echo 🔒 Preserving your Bindings (KV / D1 / Resources)...
echo ======================================================
echo.

set "CF_ACC_ID=!ACCOUNT_ID!"
set "CF_WORKER_NAME=!TARGET_FINAL!"
set "CF_FILE_PATH=!TARGET_DEPLOY!"
set "CF_OK_PATH=%TEMP%\cf_deploy_ok.txt"

:: Temporarily disable Windows expansion to protect Node.js code
setlocal DisableDelayedExpansion

node --input-type=module -e "import fs from 'fs'; import { execSync } from 'child_process'; (async () => { try { const rawToken = execSync('npx.cmd --yes wrangler auth token --json', { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'] }); const token = JSON.parse(rawToken.slice(rawToken.indexOf('{'), rawToken.lastIndexOf('}') + 1)).token; const accId = process.env.CF_ACC_ID; const workerName = process.env.CF_WORKER_NAME; const filePath = process.env.CF_FILE_PATH; const okFilePath = process.env.CF_OK_PATH; const bRes = await fetch('https://api.cloudflare.com/client/v4/accounts/' + accId + '/workers/scripts/' + workerName + '/bindings', { headers: { Authorization: 'Bearer ' + token } }); const bData = await bRes.json(); const existingBindings = (bData.result || []).filter(b => b.type !== 'secret_text' && !(b.type === 'plain_text' && !b.text)); const bindingNames = existingBindings.map(b => b.name).join(', ') || 'None (Resources)'; console.log('🔒 Bindings preserved: ' + bindingNames); const scriptCode = fs.readFileSync(filePath, 'utf8'); const form = new FormData(); form.append('metadata', JSON.stringify({ main_module: 'worker.js', bindings: existingBindings, compatibility_date: '2024-01-01' })); form.append('worker.js', new Blob([scriptCode], { type: 'application/javascript+module' }), 'worker.js'); const putRes = await fetch('https://api.cloudflare.com/client/v4/accounts/' + accId + '/workers/scripts/' + workerName, { method: 'PUT', headers: { Authorization: 'Bearer ' + token }, body: form }); console.log('HTTP Status: ' + putRes.status); const textResp = await putRes.text(); console.log('Cloudflare Response: ' + textResp); try { const putData = JSON.parse(textResp); if (putData.success) { console.log('Code updated successfully on Cloudflare'); fs.writeFileSync(okFilePath, 'OK', 'utf8'); process.exit(0); } } catch(err){} process.exit(1); } catch (e) { console.log('Execution error: ' + e.message); process.exit(1); } })();"

endlocal

echo.
if exist "%TEMP%\cf_deploy_ok.txt" (
    echo ✅ Deploy to "!TARGET_FINAL!" completed successfully!
    del "%TEMP%\cf_deploy_ok.txt"
) else (
    echo ❌ An error occurred during deployment.
)
goto end

:: ======================================================
:: FINALIZATION AND CLEANUP
:: ======================================================
:end
set "CLOUDFLARE_ACCOUNT_ID="
set "CF_ACC_ID="
set "CF_WORKER_NAME="
set "CF_FILE_PATH="
set "CF_OK_PATH="
if exist "%~dp0.wrangler" rd /s /q "%~dp0.wrangler"
if exist "%TEMP%\cf_deploy_unzipped" rd /s /q "%TEMP%\cf_deploy_unzipped"
if exist "%TEMP%\worker_deploy_temp.js" del /f /q "%TEMP%\worker_deploy_temp.js"
if exist "%TEMP%\cf_workers_list.txt" del /f /q "%TEMP%\cf_workers_list.txt"
if exist "%TEMP%\cf_accounts_list.txt" del /f /q "%TEMP%\cf_accounts_list.txt"
if exist "%TEMP%\cf_projects_list.txt" del /f /q "%TEMP%\cf_projects_list.txt"
if exist "%TEMP%\cf_deploy_ok.txt" del /f /q "%TEMP%\cf_deploy_ok.txt"

echo.
pause

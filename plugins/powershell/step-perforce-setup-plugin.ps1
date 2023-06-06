$STEPPATH = "$Env:USERPROFILE\.step"

if (-not (Test-Path -Path $STEPPATH)) {
    Write-Error "$STEPPATH was not found" -ErrorAction Stop
}

# Calvin S figlet font
# http://www.patorjk.com/software/taag/#p=display&f=Calvin%20S&t=Perforce%0ASmallstep%0ASetup
Write-Host @"
╔═╗┌─┐┬─┐┌─┐┌─┐┬─┐┌─┐┌─┐   
╠═╝├┤ ├┬┘├┤ │ │├┬┘│  ├┤    
╩  └─┘┴└─└  └─┘┴└─└─┘└─┘   
╔═╗┌┬┐┌─┐┬  ┬  ┌─┐┌┬┐┌─┐┌─┐
╚═╗│││├─┤│  │  └─┐ │ ├┤ ├─┘
╚═╝┴ ┴┴ ┴┴─┘┴─┘└─┘ ┴ └─┘┴  
╔═╗┌─┐┌┬┐┬ ┬┌─┐            
╚═╗├┤  │ │ │├─┘            
╚═╝└─┘ ┴ └─┘┴                      

"@

Write-Host -ForegroundColor Green "This tool will ensure your machine is ready to ssh into our systems that utilize SSH Certificates for authentication. During this process your browser will be opened twice to facilitate the SSO process."
Write-Host

$pf_username = Read-Host -Prompt "What is your Perforce username?"
Write-Host

$PERFORCE_USERNAME = $pf_username
$SSH_KEY_TYPE = "ecdsa"
$SSH_KEY_GEN_OPTIONS = "-b 521"

Write-Host -ForegroundColor Green "Generating a ssh key for use when connecting to persistent systems such as servers..."
Write-Host

ssh-keygen -t $SSH_KEY_TYPE $SSH_KEY_GEN_OPTIONS -C "$PERFORCE_USERNAME via Perforce Smallstep Persistent" -f $Env:USERPROFILE.ssh/id_${SSH_KEY_TYPE}_perforce_smallstep_persistent
Write-Host

Write-Host -ForegroundColor Green "Generating a ssh key for use when connecting to ephemeral systems such as those handed out by ABS..."
Write-Host

ssh-keygen -t $SSH_KEY_TYPE $SSH_KEY_GEN_OPTIONS -C "$PERFORCE_USERNAME via Perforce Smallstep ABS" -f $Env:USERPROFILE.ssh/id_${SSH_KEY_TYPE}_perforce_smallstep_abs
Write-Host

Write-Host -ForegroundColor Green "Bootstrapping the " -NoNewline
Write-Host -ForegroundColor Yellow "perforce-persistent" -NoNewline
Write-Host -ForegroundColor Green " step context. This context is used when connecting to persistent systems."
step ca bootstrap --context perforce-persistent --team perforce
Write-Host

Write-Host -ForegroundColor Green "Bootstrapping the " -NoNewline
Write-Host -ForegroundColor Yellow "perforce-abs" -NoNewline
Write-Host -ForegroundColor Green " step context. This context is used when connecting to ephemeral systems."
step ca bootstrap --context perforce-abs --ca-url https://abs.perforce.ca.smallstep.com --fingerprint d63f510b17f85181a6c68b43ca35cefd447743c0e5dc1495379b8b40378a3dbc
Write-Host

Write-Host -ForegroundColor Green "Switching to the perforce-persistent context and signing the id_${SSH_KEY_TYPE}_perforce_smallstep_persistent.pub certificate."
step context select perforce-persistent
step ssh certificate --sign --provisioner azuread $PERFORCE_USERNAME@perforce.com $Env:USERPROFILE.ssh/id_${SSH_KEY_TYPE}_perforce_smallstep_persistent.pub 
step ssh config --set User=$PERFORCE_USERNAME --set IdentityFile=$Env:USERPROFILE.ssh/id_${SSH_KEY_TYPE}_perforce_smallstep_persistent --set IdentitiesOnly=yes 
Write-Host

Write-Host -ForegroundColor Green "Switching to the perforce-abs context and signing the id_${SSH_KEY_TYPE}_perforce_smallstep_abs.pub certificate."
step context select perforce-abs
step ssh certificate --sign --provisioner=abs-azuread $PERFORCE_USERNAME@perforce.com $Env:USERPROFILE.ssh/id_${SSH_KEY_TYPE}_perforce_smallstep_abs.pub 
step ssh config --set User=root --set IdentityFile=$Env:USERPROFILE.ssh/id_${SSH_KEY_TYPE}_perforce_smallstep_abs --set IdentitiesOnly=yes
Write-Host

Write-Host -ForegroundColor Green "Below are the configuration files created by this tool."
Write-Host

Write-Host -ForegroundColor Green "Here is what is in '$Env:USERPROFILE/.step/ssh/includes': "
Get-Content $Env:USERPROFILE/.step/ssh/includes
Write-Host

Write-Host -ForegroundColor Green "Here is what is in '$Env:USERPROFILE/.step/authorities/perforce-abs/ssh/config': "
Get-Content $Env:USERPROFILE/.step/authorities/perforce-abs/ssh/config
Write-Host

Write-Host -ForegroundColor Green "Here is what is in '$Env:USERPROFILE/.step/authorities/perforce-persistent/ssh/config': "
Get-Content $Env:USERPROFILE/.step/authorities/perforce-persistent/ssh/config
Write-Host

Write-Host
Write-Host "Please edit your '" -NoNewline; `
Write-Host "$Env:USERPROFILE\.ssh\config" -NoNewline -ForegroundColor Yellow; `
Write-Host "' and ensure that you only have one entry for '" -NoNewline; `
Write-Host "Host *" -NoNewline -ForegroundColor Yellow; `
Write-Host "'. If you have more than one, combine their contents into a single entry."
Write-Host
Write-Host "Please also remove any block with the heading '" -NoNewline; `
Write-Host "Host *.vmpooler-*.puppet.net" -NoNewline -ForegroundColor Yellow; `
Write-Host "' as it is now handled by configruation manged via the step command."
Write-Host

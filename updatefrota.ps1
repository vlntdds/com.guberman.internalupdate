<# ////////////////////////////////////
//Desinstala os Aplicativos Guberman//
///////////////////////////////////// #>

$pc = Read-Host 'Insira o NOME do servidor desejado (EX: SRVWIN17)'

Invoke-Command -ComputerName $pc -Credential GUB\Administrador -ScriptBlock {

    $comAdmin = New-Object -com ("COMAdmin.COMAdminCatalog.1")
    try { $comAdmin.ShutdownApplication("Guberman")} catch { }
    $net = new-object -ComObject WScript.Network
    try { $net.MapNetworkDrive("q:", "\\192.168.0.201\d\frotadst.600", $false, "GUB\Administrador", "!adm2013#") } catch { }

    $path = Read-Host 'Insira o nome da pasta de instala��o (EX: FrotaWeb_SAAS)'
    $path = "q:\" + $path
    if(!(Test-Path -Path $path )) { throw "Diret�rio de instala��o inv�lido. Verifique"}

    $uninstallCOM32 = gci "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | foreach { gp $_.PSPath } | ? { $_ -match "Componentes do Frota Web*" } | select UninstallString 
    $uninstallCOM64 = gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | foreach { gp $_.PSPath } | ? { $_ -match "Componentes do Frota Web*" } | select UninstallString 
    $uninstallSV32 = gci "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | foreach { gp $_.PSPath } | ? { $_ -match "Componentes do Sistema Frota*" } | select UninstallString 
    $uninstallSV64 = gci "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall" -ErrorAction SilentlyContinue | foreach { gp $_.PSPath } | ? { $_ -match "Componentes do Sistema Frota*" } | select UninstallString 

    if ($uninstallCOM64) {
        $uninstall64 = $uninstallCOM64.UninstallString -Replace "MsiExec.exe","" -Replace "/I","" -Replace "/X",""
        $uninstall64 = $uninstall64.Trim()
        "Desinstalando os Componentes do Frota Web (COM+) - Etapa 1 de 2..."
        start-process "msiexec.exe" -arg "/X $uninstall64 /qn" -Wait}
    if ($uninstallCOM32) {
        $uninstall32 = $uninstallCOM32.UninstallString -Replace "MsiExec.exe","" -Replace "/I","" -Replace "/X",""
        $uninstall32 = $uninstall32.Trim()
        "Desinstalando os Componentes do Frota Web (COM+) - Etapa 1 de 2..."
        start-process "msiexec.exe" -arg "/X $uninstall32 /qn" -Wait
    }
    if ($uninstallSV64) {
        $uninstall64 = $uninstallSV64.UninstallString -Replace "MsiExec.exe","" -Replace "/I","" -Replace "/X",""
        $uninstall64 = $uninstall64.Trim()
        "Desinstalando os Componentes do Frota Web (COM+) - Etapa 2 de 2..."
        start-process "msiexec.exe" -arg "/X $uninstall64 /qn" -Wait}
    if ($uninstallSV32) {
        $uninstall32 = $uninstallSV32.UninstallString -Replace "MsiExec.exe","" -Replace "/I","" -Replace "/X",""
        $uninstall32 = $uninstall32.Trim()
        "Desinstalando os Componentes do Frota Web (COM+) - Etapa 2 de 2..."
        start-process "msiexec.exe" -arg "/X $uninstall32 /qn" -Wait
    }

    <# ////////////////////
    //Salva o Frota.udl//
    //////////////////// #>

    copy c:\windows\olesrv\frota.udl c:\windows\frota.udl
    del c:\windows\olesrv\*.*
    mv c:\windows\frota.udl c:\windows\olesrv\frota.udl

    <# //////////////////////////////////////////////////////////////
    //Apaga ~ Cria o Aplicativo Guberman no Servi�o de Componentes//
    ////////////////////////////////////////////////////////////// #>

    $applications = $comAdmin.GetCollection("Applications") 
    $applications.Populate() 
    $index = 0
    $GubermanCOM = �Guberman�

    $appExistCheckApp = $applications | Where-Object {$_.Name -eq $GubermanCOM}

    if($appExistCheckApp)
    {
        $appExistCheckAppName = $appExistCheckApp.Value("Name")
        foreach ($application in $applications)
        {
            $nome = $application.Name
            if ($nome -Match "Guberman")
            {
                "-----------------------------------------------------------"
                "Iniciando Remo��o dos Componentes no Sistema..."
                �Aplicativo COM+ Guberman J� Existente, removendo...�
                $applications.Remove($index) | Out-Null
                $applications.SaveChanges() | Out-Null
                "Aplicativo removido do Servi�o de Componentes com Sucesso!"
                "-----------------------------------------------------------`n"
            }
        $index++
        }
    }

    $gubCOM = $applications.Add()
    $gubCOM.Value("Name") = $GubermanCOM
    $gubCOM.Value("ApplicationAccessChecksEnabled") = 0 
    $gubCOM.Value("Identity") = �GUB\Administrador�
    $gubCOM.Value("Password") = �!adm2013#�
    $gubCOM.Value("Authentication") = 2
    $gubCOM.Value("ImpersonationLevel") = 2

    $saveChangesResult = $applications.SaveChanges()
    if ($saveChangesResult -Match "1") { "Novo componente Guberman criado com Sucesso!" }

    <#///////////////////////////
    //Extrai Componentes / ASP//
    //////////////////////////#>

    "Desinstala��o do sistema conclu�da com sucesso!`n`n"
    if((Test-Path -Path c:\Install )) {Remove-Item c:\Install -Force -Recurse | Out-Null }
    if(!(Test-Path -Path c:\Install )) { New-Item C:\Install -type directory | Out-Null } 
    Copy-Item $path\*.exe c:\Install\
    Copy-Item $path\*.sql c:\Install\
    Copy-Item $path\*.rar c:\Install\
    Copy-Item $path\*.txt c:\Install\

    "Arquivos copiados com sucesso... iniciando instala��o`n"

    $path = "C:\Install"
    $files = Get-ChildItem $path
     ForEach ($file in $files) { 
        if ($file.fullName -match "Serv*")
        {
            "$file encontrado! Iniciando instala��o..."
            $executa = $path + "\" + $file
            Start-Process $executa -ArgumentList "-s /s /V/qn" -wait -ErrorAction SilentlyContinue
            "Componentes COM+ (Servidor) Extra�dos com sucesso!`n"
            Remove-Item $executa -ErrorAction SilentlyContinue
            $client = $executa.replace("Serv", "")
            $dic = $executa.replace("Serv", "Dic")
        } 
    }
    
    if((Test-Path -Path c:\Guberman )) {
        "-------------------------------------------------"
        "Pasta Guberman j� existente, efetuando backup"
        $bckpath = "c:\Guberman - " + (Get-Date -format "dd-MMM-yyyy")
        if((Test-Path -Path $bckpath)) { Remove-Item $bckpath -Force -Recurse -ErrorAction SilentlyContinue | Out-Null }
        $mvar = $bckpath.replace("c:\", "")
        Rename-Item -path "C:\Guberman" -newName $mvar
        "Backup conclu�do, proseguindo com a instala��o..."
        New-Item C:\Guberman -type directory | Out-Null
        "-------------------------------------------------`n"
    } else { New-Item C:\Guberman -type directory | Out-Null }

    $path = "C:\Install"
    $files = Get-ChildItem $path
        
    $clientname = $client.replace("C:\Install\", "").replace(".exe", "")
    $clientpath = $client.replace(".exe", "")
    $args = "/C /T:" + $clientpath
    $copypath = "$clientpath" + "\"
    "$clientname encontrado!"
    Start-Process -filepath $client -argumentlist $args -wait
    Copy-Item  -Path c:\windows\oleinstall\* -Destination $copypath
    $exec = $clientpath + "\acmsetup.exe"
    $args = "/t " + $clientpath + "\setup.stf /QNT /G c:\"+$clientname+".txt"
    Start-Process -filepath $exec -argumentlist $args -wait
    Rename-Item -path "C:\frotaweb\SFROTA.ini" -newName frota.ini
    "$clientname instalado em C:\Guberman\!"

    "Adicionando permiss�es na pasta Guberman...`n"
    try {
        $sharepath = "C:\Guberman"
        $Acl = Get-ACL $SharePath
        $AccessRule= New-Object System.Security.AccessControl.FileSystemAccessRule("Todos","fullcontrol","ContainerInherit,Objectinherit","none","Allow")
        $Acl.AddAccessRule($AccessRule)
        Set-Acl $SharePath $Acl
        "Permiss�es configuradas com Sucesso!"
        "Compartilhando pasta na rede...`n"
        } catch { "Erro ao configurar permiss�es, fa�a manualmente esse processo`n" 
    }
    Remove-Item $executa -ea SilentlyContinue
    if (!(get-wmiObject Win32_Share -filter "name='Guberman'")) { 
        $shares = [WMICLASS]"WIN32_Share"
        if ($shares.Create("c:\guberman", "Guberman", 0).ReturnValue -ne 0) {
            throw "Erro ao compartilhar a pasta na rede, fa�a manualmente esse processo`n" 
        } else { 
            $sharepath = "\\localhost\guberman"
            $Acl = Get-ACL $SharePath
            $AccessRule=New-Object System.Security.AccessControl.FileSystemAccessRule("Todos","FullControl","ContainerInherit,ObjectInherit","None","Allow")
            $ACL.SetAccessRule($AccessRule)
            "Pasta compartilhada na rede com sucesso!`n" 
        }
    }


    <#///////////////////////////
    //Instala Componentes COM+//
    //////////////////////////#>

    "Registrando Componentes no COM+`n"

    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\absrelat.dll", "c:\windows\olesrv\absrelat.tlb", "")
    "AbsRelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\abstela.dll", "c:\windows\olesrv\abstela.tlb", "")
    "Abstela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\acesso.dll", "c:\windows\olesrv\acesso.tlb", "")
    "Acesso Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\artela.dll", "c:\windows\olesrv\artela.tlb", "")
    "Artela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\autela.dll", "c:\windows\olesrv\autela.tlb", "")
    "Autela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\bi.dll", "c:\windows\olesrv\bi.tlb", "")
    "BI Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\bprelat.dll", "c:\windows\olesrv\bprelat.tlb", "")
    "Bprelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\bptela.dll", "c:\windows\olesrv\bptela.tlb", "")
    "Bptela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\cltela.dll", "c:\windows\olesrv\cltela.tlb", "")
    "Cltela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\cmtela.dll", "c:\windows\olesrv\cmtela.tlb", "")
    "Cmtela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\cmtela.dll", "c:\windows\olesrv\cmtela.tlb", "")
    "Cmtela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\consultas.dll", "c:\windows\olesrv\consultas.tlb", "")
    "Consultas Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\cotela.dll", "c:\windows\olesrv\cotela.tlb", "")
    "Cotela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\cptela.dll", "c:\windows\olesrv\cptela.tlb", "")
    "Cptela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\errrelat.dll", "c:\windows\olesrv\errrelat.tlb", "")
    "Errrelat Instalado com Sucesso" } catch { } 
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\esrelat.dll", "c:\windows\olesrv\esrelat.tlb", "")
    "Esrelat Instalado com Sucesso" } catch { } 
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\estela.dll", "c:\windows\olesrv\estela.tlb", "")
    "Estela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\eurelat.dll", "c:\windows\olesrv\eurelat.tlb", "")
    "Eurelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\eutela.dll", "c:\windows\olesrv\eutela.tlb", "")
    "Eutela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\frotaweb.dll", "c:\windows\olesrv\frotaweb.tlb", "")
    "Frotaweb Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\firerelat.dll", "c:\windows\olesrv\firerelat.tlb", "")
    "Firerelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\fitela.dll", "c:\windows\olesrv\fitela.tlb", "")
    "fitela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\frotasaas.dll", "c:\windows\olesrv\frotasaas.tlb", "")
    "FrotaSAS Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\frrelat.dll", "c:\windows\olesrv\frrelat.tlb", "")
    "Frrelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\frtela.dll", "c:\windows\olesrv\frtela.tlb", "")
    "Frtela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\gatela.dll", "c:\windows\olesrv\gatela.tlb", "")
    "Gatela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\lirelat.dll", "c:\windows\olesrv\lirelat.tlb", "")
    "Lirelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\litela.dll", "c:\windows\olesrv\litela.tlb", "")
    "Litela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\lorelat.dll", "c:\windows\olesrv\lorelat.tlb", "")
    "Lorelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\lorelat.dll", "c:\windows\olesrv\lorelat.tlb", "")
    "Lorelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\lotela.dll", "c:\windows\olesrv\lotela.tlb", "")
    "Lotela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\matela.dll", "c:\windows\olesrv\matela.tlb", "")
    "Matela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\marelat.dll", "c:\windows\olesrv\marelat.tlb", "")
    "Marelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\nftela.dll", "c:\windows\olesrv\nftela.tlb", "")
    "Nftela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\ocrelat.dll", "c:\windows\olesrv\ocrelat.tlb", "")
    "Ocrelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\octela.dll", "c:\windows\olesrv\octela.tlb", "")
    "Octela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\osrelat.dll", "c:\windows\olesrv\osrelat.tlb", "")
    "Osrelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\ostela.dll", "c:\windows\olesrv\ostela.tlb", "")
    "Ostela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\pcrelat.dll", "c:\windows\olesrv\pcrelat.tlb", "")
    "Pcrelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\pctela.dll", "c:\windows\olesrv\pctela.tlb", "")
    "Pctela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\pnrelat.dll", "c:\windows\olesrv\pnrelat.tlb", "")
    "Pnrelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\pntela.dll", "c:\windows\olesrv\pntela.tlb", "")
    "Pntela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\prrelat.dll", "c:\windows\olesrv\prrelat.tlb", "")
    "Prrelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\prtela.dll", "c:\windows\olesrv\prtela.tlb", "")
    "Prtela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\rhrelat.dll", "c:\windows\olesrv\rhrelat.tlb", "")
    "Rhrelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\rhtela.dll", "c:\windows\olesrv\rhtela.tlb", "")
    "Rhtela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\rotinas3c.dll", "c:\windows\olesrv\rotinas3c.tlb", "")
    "Rotinas3c Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\rm.dll", "c:\windows\olesrv\rm.tlb", "")
    "RM Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\rttela.dll", "c:\windows\olesrv\rttela.tlb", "")
    "Rttela Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\satela.dll", "c:\windows\olesrv\satela.tlb", "")
    "Satela Instalado com Sucesso" } catch { }
    try{
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\tfrelat.dll", "c:\windows\olesrv\tfrelat.tlb", "")
    "Tfrelat Instalado com Sucesso" } catch { }
    try {
    $comAdmin.InstallComponent("Guberman", "c:\windows\olesrv\tftela.dll", "c:\windows\olesrv\tftela.tlb", "")
    "Tftela Instalado com Sucesso" } catch { }

    <#clear#>

    <#"-------------------"
    "Registrando WebTela"#>
    try { Start-Process C:\Windows\Olesrv\webtela.exe -ArgumentList "-regserver" -wait } catch { }
    <#"Webtela registrado!"
    "-------------------"#>


    $title="Instala��o Conclu�da"
    $message="Deseja executar o dicion�rio de dados?"
    $choiceYes = New-Object System.Management.Automation.Host.ChoiceDescription "&Sim", "Sim."
    $choiceNo = New-Object System.Management.Automation.Host.ChoiceDescription "&N�o", "N�o."
    $options = [System.Management.Automation.Host.ChoiceDescription[]]($choiceYes, $choiceNo)
    $result = $host.ui.PromptForChoice($title, $message, $options, 1)
    switch ($result)
    {
        0 { Try { Start-Process $dic -wait } Catch { } }
        1 { #<clear#> }
    }
}
}

"`nInstala��o conclu�da. Efetue as altera��es necess�rias no Frota.UDL"
Read-host "Pressione qualquer tecla para sair..."


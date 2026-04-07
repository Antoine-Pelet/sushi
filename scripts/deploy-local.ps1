param(
    [string]$TomcatPath,
    [string]$ContextName = "sushi",
    [string]$ServletApiJar,
    [int]$PortOffset = 0,
    [switch]$BuildOnly,
    [switch]$LaunchTomcat,
    [switch]$ResetData
)

$ErrorActionPreference = "Stop"

function Require-Command {
    param([string]$Name)
    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Commande introuvable: $Name"
    }
}

function Normalize-ContextName {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return "sushi"
    }

    $normalized = $Value.Trim().Trim("/")
    if ([string]::IsNullOrWhiteSpace($normalized)) {
        return "ROOT"
    }

    return $normalized
}

function Test-PlaceholderPath {
    param([string]$Value)
    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $false
    }

    $normalized = $Value.Replace("/", "\").ToLowerInvariant()
    return $normalized.Contains("c:\chemin\vers\") -or $normalized.Contains("\chemin\vers\")
}

function Get-ServletApiFlavor {
    param([string]$JarPath)

    if ([string]::IsNullOrWhiteSpace($JarPath) -or -not (Test-Path $JarPath)) {
        return $null
    }

    $entries = & jar tf $JarPath
    if ($entries -match '^jakarta/servlet/http/HttpServlet\.class$') {
        return "jakarta"
    }
    if ($entries -match '^javax/servlet/http/HttpServlet\.class$') {
        return "javax"
    }
    return "unknown"
}

function Get-TomcatCandidateInfo {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path $Path)) {
        return $null
    }

    $resolvedPath = (Resolve-Path $Path).Path
    $servletApiJar = Join-Path $resolvedPath "lib\servlet-api.jar"
    $confDir = Join-Path $resolvedPath "conf"
    $startupScript = Join-Path $resolvedPath "bin\startup.bat"
    $flavor = Get-ServletApiFlavor $servletApiJar

    [pscustomobject]@{
        Path = $resolvedPath
        ServletApiJar = $servletApiJar
        ServletFlavor = $flavor
        HasConf = (Test-Path $confDir)
        ConfDir = $confDir
        StartupScript = $startupScript
        HasStartup = (Test-Path $startupScript)
    }
}

function Test-TcpPortInUse {
    param([int]$Port)

    try {
        $listeners = [System.Net.NetworkInformation.IPGlobalProperties]::GetIPGlobalProperties().GetActiveTcpListeners()
        return ($listeners | Where-Object { $_.Port -eq $Port } | Measure-Object).Count -gt 0
    } catch {
        $matches = netstat -ano | Select-String ":$Port"
        return $null -ne $matches
    }
}

function Find-AvailablePortOffset {
    param([int]$StartOffset)

    for ($offset = $StartOffset; $offset -le ($StartOffset + 20); $offset++) {
        $shutdownPort = 8005 + $offset
        $httpPort = 8080 + $offset
        $httpsPort = 8443 + $offset

        if (-not (Test-TcpPortInUse $shutdownPort) -and -not (Test-TcpPortInUse $httpPort) -and -not (Test-TcpPortInUse $httpsPort)) {
            return $offset
        }
    }

    throw "Impossible de trouver des ports libres pour Tomcat 10.1."
}

function Prepare-CatalinaBase {
    param(
        [string]$TomcatHome,
        [string]$CatalinaBase,
        [int]$ShutdownPort,
        [int]$HttpPort,
        [int]$HttpsPort
    )

    if (Test-Path $CatalinaBase) {
        Remove-Item -LiteralPath $CatalinaBase -Recurse -Force
    }

    New-Item -ItemType Directory -Force -Path $CatalinaBase | Out-Null
    foreach ($name in @("conf", "logs", "temp", "webapps", "work")) {
        New-Item -ItemType Directory -Force -Path (Join-Path $CatalinaBase $name) | Out-Null
    }

    Copy-Item -Path (Join-Path $TomcatHome "conf\*") -Destination (Join-Path $CatalinaBase "conf") -Recurse -Force

    $serverXmlPath = Join-Path $CatalinaBase "conf\server.xml"
    $serverXml = Get-Content $serverXmlPath -Raw
    $serverXml = $serverXml -replace '<Server port="8005"', "<Server port=""$ShutdownPort"""
    $serverXml = $serverXml -replace '<Connector port="8080"', "<Connector port=""$HttpPort"""
    $serverXml = $serverXml -replace '<Connector port="8443"', "<Connector port=""$HttpsPort"""
    Set-Content -LiteralPath $serverXmlPath -Value $serverXml -Encoding UTF8
}

function Find-TomcatCandidate {
    $candidates = New-Object System.Collections.Generic.List[string]
    $rejected = New-Object System.Collections.Generic.List[string]

    if ($env:CATALINA_BASE) { $candidates.Add($env:CATALINA_BASE) }
    if ($env:CATALINA_HOME) { $candidates.Add($env:CATALINA_HOME) }

    $roots = @(
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        "$env:ProgramData\chocolatey\lib\Tomcat\tools",
        "$env:USERPROFILE\Downloads",
        "$env:USERPROFILE\Desktop"
    ) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) -and (Test-Path $_) }

    foreach ($root in $roots) {
        $matches = Get-ChildItem -Path $root -Directory -Filter "apache-tomcat-10.1*" -ErrorAction SilentlyContinue | Select-Object -ExpandProperty FullName
        foreach ($match in $matches) {
            $candidates.Add($match)
        }

        $namedMatch = Join-Path $root "Apache Software Foundation\Tomcat 10.1"
        if (Test-Path $namedMatch) {
            $candidates.Add($namedMatch)
        }
    }

    foreach ($candidate in ($candidates | Select-Object -Unique)) {
        $info = Get-TomcatCandidateInfo $candidate
        if ($null -eq $info) {
            continue
        }

        if ($info.ServletFlavor -eq "jakarta" -and $info.HasConf -and $info.HasStartup) {
            return [pscustomobject]@{
                Match = $info
                Rejected = $rejected
            }
        }

        $reason = if ($info.ServletFlavor -eq "javax") {
            "Servlet API javax detectee (Tomcat 9 ou plus ancien)"
        } elseif (-not $info.HasConf) {
            "dossier conf absent"
        } elseif (-not $info.HasStartup) {
            "script startup.bat absent"
        } else {
            "Servlet API non compatible"
        }
        $rejected.Add("$($info.Path) - $reason")
    }

    return [pscustomobject]@{
        Match = $null
        Rejected = $rejected
    }
}

Require-Command "javac"
Require-Command "jar"

$projectRoot = Split-Path -Parent $PSScriptRoot
$context = Normalize-ContextName $ContextName
$webappSource = Join-Path $projectRoot "src\main\webapp"
$javaSourceRoot = Join-Path $projectRoot "src\main\java"
$buildRoot = Join-Path $projectRoot "build\local"
$stagingDir = Join-Path $buildRoot $context
$classesDir = Join-Path $stagingDir "WEB-INF\classes"
$warPath = Join-Path $buildRoot "$context.war"
$catalinaBaseDir = $null
$resolvedTomcatPath = $null
$deployDir = $null
$httpPort = 8080 + $PortOffset
$shutdownPort = 8005 + $PortOffset
$httpsPort = 8443 + $PortOffset

$selectedTomcat = $null

if (-not [string]::IsNullOrWhiteSpace($TomcatPath)) {
    if (Test-PlaceholderPath $TomcatPath) {
        throw "Le chemin -TomcatPath utilise encore l'exemple du README. Remplacez C:\chemin\vers\apache-tomcat-10.1.x par le vrai dossier Tomcat 10.1 installe sur votre machine."
    }

    $selectedTomcat = Get-TomcatCandidateInfo $TomcatPath
    if ($null -eq $selectedTomcat) {
        throw "Tomcat introuvable: $TomcatPath"
    }

    if ($selectedTomcat.ServletFlavor -ne "jakarta") {
        throw "Le Tomcat fourni n'est pas compatible Jakarta Servlet. Trouve: $($selectedTomcat.Path). Cette application exige Tomcat 10.1+."
    }
}

if ([string]::IsNullOrWhiteSpace($ServletApiJar)) {
    if ($null -eq $selectedTomcat) {
        $search = Find-TomcatCandidate
        $selectedTomcat = $search.Match

        if ($null -eq $selectedTomcat) {
            if ($search.Rejected.Count -gt 0) {
                throw "Aucun Tomcat 10.1 compatible trouve automatiquement. Candidats rejetes: $($search.Rejected -join ' ; '). Precisez -TomcatPath avec votre vrai dossier Tomcat 10.1."
            }
            throw "Tomcat 10.1 introuvable automatiquement. Precisez -TomcatPath avec le vrai dossier d'installation, par exemple C:\apache-tomcat-10.1.39, ou utilisez -ServletApiJar."
        }
    }

    $TomcatPath = $selectedTomcat.Path
    $ServletApiJar = $selectedTomcat.ServletApiJar
}

if (-not (Test-Path $ServletApiJar)) {
    throw "Jar Servlet introuvable: $ServletApiJar. Verifiez que -TomcatPath pointe bien vers le dossier racine de Tomcat 10.1."
}

if (-not (Test-Path $webappSource)) {
    throw "Dossier webapp introuvable: $webappSource"
}

if (-not (Test-Path $javaSourceRoot)) {
    throw "Dossier source Java introuvable: $javaSourceRoot"
}

$resolvedServletApiJar = (Resolve-Path $ServletApiJar).Path

if (Test-Path $stagingDir) {
    Remove-Item -LiteralPath $stagingDir -Recurse -Force
}

New-Item -ItemType Directory -Force -Path $classesDir | Out-Null
Copy-Item -Path (Join-Path $webappSource "*") -Destination $stagingDir -Recurse -Force

$sources = Get-ChildItem -Path $javaSourceRoot -Recurse -Filter "*.java" | ForEach-Object { $_.FullName }
if (-not $sources -or $sources.Count -eq 0) {
    throw "Aucune source Java trouvee dans $javaSourceRoot"
}

& javac -encoding UTF-8 -cp $resolvedServletApiJar -d $classesDir $sources

if (Test-Path $warPath) {
    Remove-Item -LiteralPath $warPath -Force
}

& jar --create --file $warPath -C $stagingDir .

if (-not $BuildOnly) {
    if ($null -eq $selectedTomcat) {
        $selectedTomcat = Get-TomcatCandidateInfo $TomcatPath
    }

    if ($null -eq $selectedTomcat) {
        throw "Le deploiement exige -TomcatPath vers Tomcat 10.1."
    }

    if ($selectedTomcat.ServletFlavor -ne "jakarta") {
        throw "Le Tomcat selectionne n'est pas compatible Jakarta Servlet. Trouve: $($selectedTomcat.Path)."
    }

    $resolvedTomcatPath = $selectedTomcat.Path
    $startupScript = $selectedTomcat.StartupScript

    if (-not $PSBoundParameters.ContainsKey("PortOffset")) {
        $autoOffset = Find-AvailablePortOffset 0
        if ($autoOffset -ne $PortOffset) {
            $PortOffset = $autoOffset
            $httpPort = 8080 + $PortOffset
            $shutdownPort = 8005 + $PortOffset
            $httpsPort = 8443 + $PortOffset
            Write-Host "Ports par defaut occupes, utilisation automatique du decalage $PortOffset (HTTP $httpPort)." -ForegroundColor Yellow
        }
    }

    $catalinaBaseDir = Join-Path $buildRoot ("tomcat-base-" + $context + "-" + $httpPort)

    Prepare-CatalinaBase -TomcatHome $resolvedTomcatPath -CatalinaBase $catalinaBaseDir -ShutdownPort $shutdownPort -HttpPort $httpPort -HttpsPort $httpsPort

    $webappsDir = Join-Path $catalinaBaseDir "webapps"

    if (-not (Test-Path $webappsDir)) {
        throw "Dossier webapps introuvable dans $catalinaBaseDir"
    }

    $deployDir = Join-Path $webappsDir $context
    $backupStorePath = Join-Path $buildRoot "_store-backup.xml"

    if ((-not $ResetData) -and (Test-Path (Join-Path $deployDir "WEB-INF\data\store.xml"))) {
        Copy-Item -LiteralPath (Join-Path $deployDir "WEB-INF\data\store.xml") -Destination $backupStorePath -Force
    }

    if (Test-Path $deployDir) {
        Remove-Item -LiteralPath $deployDir -Recurse -Force
    }

    Copy-Item -LiteralPath $stagingDir -Destination $deployDir -Recurse -Force

    if ((-not $ResetData) -and (Test-Path $backupStorePath)) {
        Copy-Item -LiteralPath $backupStorePath -Destination (Join-Path $deployDir "WEB-INF\data\store.xml") -Force
        Remove-Item -LiteralPath $backupStorePath -Force
    }

    if ($LaunchTomcat) {
        if (-not (Test-Path $startupScript)) {
            throw "Script de demarrage introuvable: $startupScript"
        }
        $env:CATALINA_HOME = $resolvedTomcatPath
        $env:CATALINA_BASE = $catalinaBaseDir
        & $startupScript
    }
}

$deployedUrl = if ($context -eq "ROOT") { "http://localhost:$httpPort/app" } else { "http://localhost:$httpPort/$context/app" }

Write-Host ""
Write-Host "Build OK"
Write-Host "Exploded app : $stagingDir"
Write-Host "WAR          : $warPath"
if (-not $BuildOnly) {
    Write-Host "Tomcat home  : $resolvedTomcatPath"
    Write-Host "Tomcat base  : $catalinaBaseDir"
    Write-Host "HTTP port    : $httpPort"
    Write-Host "Deploy       : $deployDir"
}
Write-Host "URL          : $deployedUrl"
Write-Host ""
Write-Host "Comptes de test : demo/demo et admin/admin"



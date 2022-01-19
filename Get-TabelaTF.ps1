<#
    .SYNOPSIS
    Faz a descarga e extrai a Tabela Coeficientes FGTS em Atraso - TF
    no diretório "Tabelas" localizado no diretório do script.

    .DESCRIPTION
    Faz a descarga e extrai a Tabela Coeficientes FGTS em Atraso - TF
    no diretório "Tabelas" localizado no diretório do script.
    Para isso, utiliza o emulador de MsDos de Takeda Toshiya, disponível em <http://takeda-toshiya.my.coocan.jp/msdos/>.
    Para obter o executável desse instalador, é necessário ter o 7zip instalado.
    O 7zip está disponível em <https://www.7-zip.org/>.

    .PARAMETER Ano
    O ano da tabela. Caso não seja informado, será assumido como o ano atual.

    .PARAMETER Mes
    O mês da tabela. Caso não seja informado, será assumido como o mês atual.

    .INPUTS
    Nenhum.

    .OUTPUTS
    Uma pasta com as tabelas no diretório "Tabelas".

    .EXAMPLE
    .\Get-TabelaTF.ps1

    .EXAMPLE
    .\Get-TabelaTF.ps1 -Mes 1

    .EXAMPLE
    .\Get-TabelaTF.ps1 -Ano 2020 -Mes 12

    .EXAMPLE
    $DataMesAtual = Get-Date -Day 1 -Month (Get-Date).Month -Year (Get-Date).Year
    0..11 | 
    ForEach-Object { 
        $DataMesAnterior = $DataMesAtual.AddMonths(-$_) 
        Invoke-Expression (".\Get-TabelaTF.ps1 -Ano " + $DataMesAnterior.Year + " -Mes " + $DataMesAnterior.Month)
    }

    .LINK
    https://github.com/abner-sa/tabelas-sefip-fgts-tf-win64

    .NOTES
        Version: 1.0
        Author: Abner Gomes de Sá
        Creation Date: 2022-01-19
        Copyrigth: Apache-2.0 License 
#>

Param(
    [Parameter(Mandatory=$false)]
    [ValidateRange(0, [int]::MaxValue)]
    [int]
    $Ano = [int](Get-Date -UFormat "%Y"),
    [Parameter(Mandatory=$false)]
    [ValidateRange(1, 12)]
    [int]
    $Mes = [int](Get-Date -UFormat "%m")
)

function Test-Uri
{
    Param(
        [Parameter(Mandatory=$true)]
        [System.Uri]
        $Uri
    )

    $Head = Invoke-Webrequest $Uri -DisableKeepAlive -UseBasicParsing -Method Head -SkipHttpErrorCheck
    return $Head.StatusCode -eq 200
}

function Get-Tabela
{
    Param(
        [Parameter(Mandatory=$true)]
        [String]
        $Arquivo,
        [Parameter(Mandatory=$true)]
        [String]
        $DestinoPath
    )

    $UriCaixa = "https://www.caixa.gov.br/Downloads/FGTS-SEFIP-GRF-Tabela-Coeficientes-FGTS-em-Atraso-TF"

    $UriArquivo = "$UriCaixa/$Arquivo"

    if ( Test-Uri $UriArquivo ) {
        $ArquivoPath = Join-Path $DestinoPath $Arquivo
        Invoke-WebRequest -Uri $UriArquivo -OutFile $ArquivoPath
        return $ArquivoPath
    }

    return $null
}

# Verifica se o emulador do MsDos está disponível.

$MsdosPath = Join-Path $PSScriptRoot 'msdos.exe'

if (-not ( Test-Path $MsdosPath -PathType Leaf ) )
{
    $7zPath = "$env:ProgramFiles\7-Zip\7z.exe"
    
    if (-not ( Test-Path $7zPath -PathType Leaf ) ) {
        Write-Error "Instale o 7zip! Disponivel em <https://www.7-zip.org/>."
    }

    $Uri = 'http://takeda-toshiya.my.coocan.jp/msdos/msdos.7z'
    $Msdos7zFile = Join-Path $PSScriptRoot 'msdos.7z'
    
    try
    {
        Invoke-WebRequest -Uri $Uri -OutFile $Msdos7zFile
    }
    catch [Microsoft.PowerShell.Commands.HttpResponseException]
    {
        $Msg=@"
Não foi possível encontrar o emulador do DOS de Takeda Toshiya,. 
Verifique se o projeto continua ativo no endereço http://takeda-toshiya.my.coocan.jp/msdos/.
Caso não esteja, sinto muito.
"@
        Write-Error $Msg
        Exit 1
    }

    Invoke-Expression "& '$7zPath' x '$Msdos7zFile' msdos/binary/i86_x64/msdos.exe -o'$PSScriptRoot'"
    Remove-Item $Msdos7zFile

    $MsdosXPath = Join-Path $PSScriptRoot 'msdos/binary/i86_x64/msdos.exe'
    Move-Item -Path $MsdosXPath -Destination $MsdosPath

    Remove-Item (Join-Path $PSScriptRoot 'msdos') -Recurse -Force
}

# Faz a descarga da tabela e extrai, caso seja um arquivo ZIP.

$Tabela = 'TF{0}{1:d2}' -f $Ano, $Mes

$TabelaDirPath = Join-Path $PSScriptRoot 'Tabelas' $Tabela

New-Item $TabelaDirPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null

$Possibilidades = @(
    ($Tabela + '.zip'),
    ($Tabela + '.exe'),
    ('TF_{0}{1:d2}.zip' -f $Ano, $Mes), # Como em TF_202108.ZIP
    ('TF_{0}{1:d2}.exe' -f $Ano, $Mes)
)

$ArquivoPath = $null
foreach ( $Possibilidade in $Possibilidades )
{
    $PossibilidadePath = Get-Tabela -Arquivo $Possibilidade -DestinoPath $TabelaDirPath
    if ( $null -ne $PossibilidadePath ) {
        $ArquivoPath = $PossibilidadePath
    }
}

Write-Host $ArquivoPath

if ( $null -ne $ArquivoPath )
{
    if ( (Get-Item $ArquivoPath).Extension.ToLower() -eq '.zip' ) {
        Expand-Archive -Path $ArquivoPath -DestinationPath $TabelaDirPath -Force
    }
}
else
{
    Write-Error "Tabela $Tabela não econtrada!"
    Remove-Item $TabelaDirPath -ErrorAction SilentlyContinue
    Exit 1
}

# Executa o arquivo 16-bits, case tenha sido criado.

Set-Location $TabelaDirPath

Get-ChildItem . -Filter *.exe -ErrorAction SilentlyContinue |
    ForEach-Object {Invoke-Expression "& '$MsdosPath' $_"}

Write-Host "Tabela descarregada com sucesso!"
Get-ChildItem

Set-Location -
# tabelas-sefip-fgts-tf-win64

Todo mês escuto muitas queixas dos contadores sobre não conseguir pegar as tabelas de coeficiente do SEFIP para recolhimento do FGTS em atraso. O motivo é que essas tabelas, muita das vezes, se encontram em arquivos 16-bits (do antigo `MS-DOS`) e o Windows 10 64-bits não dá mais suporte a esse formato. Então é necessário utilizar um emulador de MsDos para executar o arquivo.

O emulador de Takeda Toshiya, disponível em <http://takeda-toshiya.my.coocan.jp/msdos/>, foi a melhor opção que encontrei. Basta extrair o `msdos/binary/i86_x64/msdos.exe`, utilizando o 7zip, e executar `msdos.exe TF202201.exe` para pegar a tabela de janeiro de 2022, por exemplo.

Para simplifcar fiz um pequeno script em `PowerShell` para descarregar e extrair as tabelas chamado `GetTabelaTF.ps1`, bastando informar o mês e/ou o ano da tabela. Por comodidade, o script cria o diretório "Tabelas" onde ele estiver e cria um subdiretório para cada mês, também descarrega o emulador, caso não esteja no mesmo diretório. Lembrando que para extrair o emulador é necessário instalar o `7zip`, disponível em <https://www.7-zip.org/>. Entretanto, coloquei aqui uma cópia da versão de 2021-12-30, o arquivo `msdos.exe`.

Por exemplo, `.\GetTabelaTF.ps1 -Ano 2020 -Mes 12` vai decarregar a tabela de dezembro de 2020 na pasta `.\Tabelas\TF202012`.

Caso não seja informado o ano ou mês, os valores padrão são o ano e mês da data do atual. Com base na data 19 de janeiro de 2022, se executar o script sem parametros, `.\GetTabelaTF.ps1`, será feita a descarga da tabela de janeiro de 2022 no diretório `.\Tabelas\TF202201`.

Saber um pouco de `PowerShell` pode simplificar, e muito, sua vida. Por exemplo, para descarregar os últimos 12, basta copiar e colar o seguinte comando:

```PowerShell
$DataMesAtual = Get-Date -Day 1 -Month (Get-Date).Month -Year (Get-Date).Year
0..11 |
ForEach-Object {
    $DataMesAnterior = $DataMesAtual.AddMonths(-$_)
    Invoke-Expression (".\Get-TabelaTF.ps1 -Ano " + $DataMesAnterior.Year + " -Mes " + $DataMesAnterior.Month)
}
```

As tabelas entre 2021-01 e 2022-01, obtidas em 2022-01-19, estão em "Tabelas".

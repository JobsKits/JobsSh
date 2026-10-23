#requires -Version 5.1
# JobsSh Windows 隔离回归；Docker、安装器和用户配置均使用假函数。
[CmdletBinding()]
param([switch]$SkipEntrypoints)
Set-StrictMode -Version 2.0
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('JobsShTest-'+[guid]::NewGuid().ToString('N'))
if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){$fixture=Join-Path '/private/tmp' (Split-Path -Leaf $fixture)}
[void][IO.Directory]::CreateDirectory($fixture)
$script:count=0
# 记录可审阅的断言结果。
function Assert-Equal($Actual,$Expected,[string]$Label){if($Actual -cne $Expected){throw "$Label；实际=$Actual；预期=$Expected"};$script:count++}
# 校验失败分支不会继续真实操作。
function Assert-Throws([scriptblock]$Body,[string]$Label){$failed=$false;try{& $Body}catch{$failed=$true};if(!$failed){throw "$Label：应当失败"};$script:count++}
try{
    & {
        . (Join-Path $root 'JobsTools.ps1')
        $script:answer=''
        function Read-JobsText([string]$Prompt,[string]$Default=''){return $script:answer}
        foreach($answer in @('','yes','Yes',' YES','YES ')){$script:answer=$answer;Assert-Throws {Confirm-JobsChange '夹具'} '危险操作精确 YES'}
        $script:answer='YES';Confirm-JobsChange '夹具';Assert-Equal $true $true '精确 YES 放行'
        $file=Join-Path $fixture '中文 [original].txt';Write-JobsUtf8 $file 'original' $true
        Assert-Equal (Read-JobsUtf8 $file).Bom $true 'UTF8 BOM 保留'
        if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){
            $target=Join-Path $fixture 'real';[void][IO.Directory]::CreateDirectory($target)
            [IO.File]::WriteAllText((Join-Path $target 'old.txt'),'keep')
            $link=Join-Path $fixture 'link';New-Item -ItemType SymbolicLink -Path $link -Target $target|Out-Null
            $script:answer=Join-Path $link 'old.txt';Assert-Throws {Get-JobsPath '夹具'} '拒绝链接祖先的既有文件'
            $script:answer=Join-Path $link 'new.txt';Assert-Throws {Get-JobsPath '夹具' -AllowNew} '拒绝链接祖先的新目标'
        }
        function Require-JobsDocker{return 'fixture-docker'}
        function Get-JobsMySQLInfo([string]$Docker){return [pscustomobject]@{State=[pscustomobject]@{Running=$true};Mounts=@()}}
        $script:calls=New-Object 'Collections.Generic.List[string]'
        function Invoke-JobsNative([string]$Executable,[string[]]$Arguments){$script:calls.Add(($Arguments -join ' '));if($Arguments[0] -eq 'rename'){throw 'fixture rename failed'}}
        function Confirm-JobsChange([string]$Message){throw 'fixture cancelled'}
        Assert-Throws {Invoke-JobsMySQLReset} '重建取消'
        Assert-Equal $script:calls.Count 0 '取消后不停止或创建容器'
        function Confirm-JobsChange([string]$Message){}
        Assert-Throws {Invoke-JobsMySQLReset} '重建改名失败'
        Assert-Equal ($script:calls -contains 'start jobs-sh-mysql') $true '改名失败恢复原运行状态'
        Assert-Equal (@($script:calls|Where-Object{$_ -match '^(run|rm|volume) '}).Count) 0 '改名失败不创建或删除数据'
        $script:calls.Clear()
        function Invoke-JobsNative([string]$Executable,[string[]]$Arguments){$script:calls.Add(($Arguments -join ' '))}
        function New-JobsMySQL([string]$Docker,[string]$Volume,[switch]$EmptyPassword){throw 'fixture creation failed'}
        function Get-JobsContainer([string]$Docker,[string]$Name,[string]$Owner){return $null}
        Assert-Throws {Invoke-JobsMySQLReset} '新容器创建失败'
        Assert-Equal (@($script:calls|Where-Object{$_ -match '^rename jobs-sh-mysql-backup-.* jobs-sh-mysql$'}).Count) 1 '创建失败恢复原容器名'
        Assert-Equal ($script:calls -contains 'start jobs-sh-mysql') $true '创建失败恢复原运行状态'
        Assert-Equal (@($script:calls|Where-Object{$_ -match '^volume '}).Count) 0 '回滚保留所有数据卷'
        $script:calls.Clear()
        function Get-JobsMySQLInfo([string]$Docker){return [pscustomobject]@{State=[pscustomobject]@{Running=$false};Mounts=@()}}
        Assert-Throws {Invoke-JobsMySQLReset} '停止状态创建失败'
        Assert-Equal ($script:calls -contains 'start jobs-sh-mysql') $false '原停止容器回滚后保持停止'
    }
    if(!$SkipEntrypoints){
        $hostPath=(Get-Process -Id $PID).Path
        foreach($entry in Get-ChildItem -LiteralPath $root -File -Filter '【WindowsOS】*.ps1'){
            & $hostPath -NoLogo -NoProfile -File $entry.FullName -Check|Out-Null
            Assert-Equal $LASTEXITCODE 0 ('只读入口 '+$entry.Name)
        }
    }
    Write-Host "PASS：$script:count 项断言；没有执行 Docker 或系统写入。"
}finally{Remove-Item -LiteralPath $fixture -Recurse -Force}

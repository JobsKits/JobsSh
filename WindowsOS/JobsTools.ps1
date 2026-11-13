# Jobs Windows 工具公共函数；仅供各入口加载，不自动执行业务。

# Jobs enter-choice emphasis is display-only; input and business decisions stay with callers.
# BEGIN JOBS_TERMINAL_STYLE_V1 - session-only colors; no profile or registry changes.
function New-JobsTerminalStyleState {
    if ($PSVersionTable.PSVersion.Major -lt 5) { return @{ JobsTerminalPlainFallback = $true; Before = @{} } }
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT -or $Host.Name -ne 'ConsoleHost') { return $null }
    if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected -or [Console]::IsErrorRedirected) { return $null }
    if ((Test-Path Env:NO_COLOR) -or $env:TERM -ieq 'dumb' -or $env:PLAIN_OUTPUT -eq '1') { return $null }
    foreach ($key in [Environment]::GetEnvironmentVariables().Keys) {
        if ([string]$key -match '^(?i:SOURCE_?TREE)') { return $null }
    }
    if (-not ('Jobs.TerminalStyleV1.Native' -as [type])) {
        try {
        Add-Type -ErrorAction Stop -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
namespace Jobs.TerminalStyleV1 {
    public static class Native {
        [StructLayout(LayoutKind.Explicit, Size=20, CharSet=CharSet.Unicode)]
        public struct InputRecord {
            [FieldOffset(0)] public ushort Kind;
            [FieldOffset(4)] public int Down;
            [FieldOffset(8)] public ushort Repeat;
            [FieldOffset(10)] public ushort Key;
            [FieldOffset(12)] public ushort Scan;
            [FieldOffset(14)] public char Character;
            [FieldOffset(16)] public uint Modifiers;
        }
        [DllImport("kernel32.dll")] static extern IntPtr GetStdHandle(int n);
        [DllImport("kernel32.dll")] static extern IntPtr GetConsoleWindow();
        [DllImport("kernel32.dll")] static extern bool GetConsoleMode(IntPtr h, out uint mode);
        [DllImport("kernel32.dll")] static extern bool SetConsoleMode(IntPtr h, uint mode);
        [DllImport("kernel32.dll")] static extern uint WaitForSingleObject(IntPtr h, uint milliseconds);
        [DllImport("kernel32.dll")] static extern bool GetNumberOfConsoleInputEvents(IntPtr h, out uint count);
        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, ExactSpelling=true)] static extern bool ReadConsoleInputW(IntPtr h, [Out] InputRecord[] records, uint count, out uint read);
        [DllImport("kernel32.dll", CharSet=CharSet.Unicode, ExactSpelling=true)] static extern bool WriteConsoleInputW(IntPtr h, InputRecord[] records, uint count, out uint written);
        const string OwnerName = "JOBS_TERMINAL_STYLE_WINDOWS_OWNER";
        static readonly string[] Keys = { "10", "11", "4;0", "4;1", "4;2", "4;3", "4;4", "4;5", "4;6", "4;7", "4;8", "4;9", "4;10", "4;11", "4;12", "4;13", "4;14", "4;15" };
        static readonly string[] Hex = { "000000", "ff5f56", "5fd787", "ffd75f", "5fafff", "d787ff", "5fd7ff", "eeeeee", "9e9e9e", "ff8787", "87ffaf", "ffff87", "87bfff", "ffafff", "afffff", "ffffff" };
        static readonly Regex Reply = new Regex("\\x1b\\](?<key>10|11|4;[0-9]{1,2});(?<rgb>rgb:[0-9a-f]{1,4}/[0-9a-f]{1,4}/[0-9a-f]{1,4})(?:\\x07|\\x1b\\\\)", RegexOptions.IgnoreCase);
        public sealed class State {
            public IntPtr Input, Output;
            public uint OutputMode;
            public ConsoleColor Foreground, Background;
            public Dictionary<string,string> Original, Applied;
            public string Owner, PreviousOwner, Recovery;
            public bool Active, ModeChanged, Fallback;
            public Dictionary<string,string> EnvironmentBefore = new Dictionary<string,string>();
        }
        static string Escape(string key, string value) { return "\x1b]" + key + ";" + value + "\x07"; }
        static string Rgb(string hex) { return "rgb:" + hex.Substring(0,2) + "/" + hex.Substring(2,2) + "/" + hex.Substring(4,2); }
        static string Normal(string rgb) {
            string[] parts = rgb.Substring(4).Split('/');
            for (int n=0; n<3; n++) {
                int maximum = (1 << (4 * parts[n].Length)) - 1;
                int value = Convert.ToInt32(parts[n],16);
                parts[n] = ((value * 65535L + maximum/2) / maximum).ToString("x4");
            }
            return String.Join("/",parts);
        }
        // Preserve unrelated key/window records instead of consuming user input during color queries.
        static Dictionary<string,string> Query(State state) {
            uint pending;
            if (!GetNumberOfConsoleInputEvents(state.Input,out pending) || pending != 0) { return null; }
            StringBuilder commands = new StringBuilder();
            foreach (string key in Keys) { commands.Append(Escape(key,"?")); }
            Console.Write(commands.ToString());
            List<InputRecord> records = new List<InputRecord>();
            List<int> characterIndices = new List<int>();
            StringBuilder text = new StringBuilder();
            Dictionary<string,string> result = new Dictionary<string,string>();
            Stopwatch timer = Stopwatch.StartNew();
            try {
                while (timer.ElapsedMilliseconds < 600) {
                    if (result.Count == Keys.Length && GetNumberOfConsoleInputEvents(state.Input,out pending) && pending == 0) { break; }
                    if (WaitForSingleObject(state.Input,20) != 0) { continue; }
                    InputRecord[] item = new InputRecord[1]; uint read;
                    if (!ReadConsoleInputW(state.Input,item,1,out read) || read != 1) { break; }
                    int index = -1;
                    if (item[0].Kind == 1 && item[0].Character != '\0') {
                        if (item[0].Down != 0) { index = text.Length; text.Append(item[0].Character); }
                        else if (text.Length != 0 && text[text.Length-1] == item[0].Character) { index = text.Length-1; }
                    }
                    records.Add(item[0]); characterIndices.Add(index);
                    foreach (Match match in Reply.Matches(text.ToString())) {
                        string key = match.Groups["key"].Value;
                        if (Array.IndexOf(Keys,key) >= 0) { result[key] = match.Groups["rgb"].Value; }
                    }
                }
            } finally {
                bool[] used = new bool[text.Length];
                foreach (Match match in Reply.Matches(text.ToString())) {
                    for (int n=match.Index; n<match.Index+match.Length; n++) { used[n] = true; }
                }
                List<InputRecord> replay = new List<InputRecord>();
                for (int n=0; n<records.Count; n++) {
                    int index = characterIndices[n];
                    if (index < 0 || !used[index]) { replay.Add(records[n]); }
                }
                if (replay.Count != 0) {
                    uint written;
                    if (!WriteConsoleInputW(state.Input,replay.ToArray(),(uint)replay.Count,out written) || written != replay.Count) {
                        Console.Error.WriteLine("[Jobs] Could not replay terminal input; color protection is unavailable.");
                        result.Clear();
                    }
                }
            }
            return result.Count == Keys.Length ? result : null;
        }
        static void Plain(State state) {
            foreach (string key in new string[] { "NO_COLOR", "PLAIN_OUTPUT", "FORCE_COLOR", "CLICOLOR", "ANSI_COLORS_DISABLED" }) {
                state.EnvironmentBefore[key] = Environment.GetEnvironmentVariable(key);
                Environment.SetEnvironmentVariable(key, key == "FORCE_COLOR" || key == "CLICOLOR" ? "0" : "1");
            }
            state.Fallback = true;
        }
        public static void Enter(State state) {
            try {
                state.Input = GetStdHandle(-10); state.Output = GetStdHandle(-11);
                uint inputMode;
                if (!GetConsoleMode(state.Input,out inputMode) || !GetConsoleMode(state.Output,out state.OutputMode)) { Plain(state); return; }
                IntPtr window = GetConsoleWindow();
                if (window == IntPtr.Zero) { Plain(state); return; }
                string identity = window.ToInt64().ToString("x");
                state.PreviousOwner = Environment.GetEnvironmentVariable(OwnerName);
                if (!String.IsNullOrEmpty(state.PreviousOwner)) {
                    string[] owner = state.PreviousOwner.Split(':');
                    int pid; long started;
                    if (owner.Length == 3 && owner[0] == identity && Int32.TryParse(owner[1],out pid) && Int64.TryParse(owner[2],out started)) {
                        try { if (Process.GetProcessById(pid).StartTime.ToUniversalTime().Ticks == started) { return; } } catch {}
                    }
                }
                state.Foreground = Console.ForegroundColor; state.Background = Console.BackgroundColor;
                if ((state.OutputMode & 4) == 0) {
                    if (!SetConsoleMode(state.Output,state.OutputMode | 4)) { Plain(state); return; }
                    state.ModeChanged = true;
                }
                state.Original = Query(state);
                if (state.Original == null) { Restore(state); Plain(state); return; }
                state.Applied = new Dictionary<string,string>();
                state.Applied["10"] = "rgb:ff/ff/ff"; state.Applied["11"] = "rgb:00/00/00";
                for (int n=0; n<16; n++) { state.Applied["4;"+n] = Rgb(Hex[n]); }
                StringBuilder restore = new StringBuilder();
                foreach (string key in Keys) { restore.Append(Escape(key,state.Original[key])); }
                string encoded = Convert.ToBase64String(Encoding.UTF8.GetBytes(restore.ToString()));
                state.Recovery = Path.Combine(Path.GetTempPath(),"JobsTerminalStyle-"+Process.GetCurrentProcess().Id+"-"+Guid.NewGuid().ToString("N")+".ps1");
                string manual = "# Restore only the session colors saved by this Jobs script.\r\n"+
                    "if ([Console]::IsOutputRedirected) { throw 'Run in the original console.' }\r\n"+
                    "Add-Type -Namespace Jobs -Name RecoveryConsole -MemberDefinition '[System.Runtime.InteropServices.DllImport(\"kernel32.dll\")] public static extern System.IntPtr GetStdHandle(int n); [System.Runtime.InteropServices.DllImport(\"kernel32.dll\")] public static extern bool GetConsoleMode(System.IntPtr h, out uint m); [System.Runtime.InteropServices.DllImport(\"kernel32.dll\")] public static extern bool SetConsoleMode(System.IntPtr h, uint m);'\r\n"+
                    "$h = [Jobs.RecoveryConsole]::GetStdHandle(-11); [uint32]$m = 0\r\n"+
                    "if (-not [Jobs.RecoveryConsole]::GetConsoleMode($h, [ref]$m)) { throw 'Run in the original console.' }\r\n"+
                    "try {\r\nif (-not [Jobs.RecoveryConsole]::SetConsoleMode($h, ($m -bor 4))) { throw 'Cannot enable terminal recovery.' }\r\n"+
                    "[Console]::Write([Text.Encoding]::UTF8.GetString([Convert]::FromBase64String('"+encoded+"')))\r\n"+
                    "[Console]::ForegroundColor = [ConsoleColor]"+((int)state.Foreground)+"\r\n"+
                    "[Console]::BackgroundColor = [ConsoleColor]"+((int)state.Background)+"\r\n"+
                    "[Console]::Write([string][char]27 + '[39;49m')\r\n"+
                    "} finally { [void][Jobs.RecoveryConsole]::SetConsoleMode($h, $m) }\r\n";
                File.WriteAllText(state.Recovery,manual,new UTF8Encoding(false));
                state.Owner = identity+":"+Process.GetCurrentProcess().Id+":"+Process.GetCurrentProcess().StartTime.ToUniversalTime().Ticks;
                Environment.SetEnvironmentVariable(OwnerName,state.Owner);
                state.Active = true;
                foreach (string key in Keys) { Console.Write(Escape(key,state.Applied[key])); }
                Console.ForegroundColor = ConsoleColor.White; Console.BackgroundColor = ConsoleColor.Black;
                Dictionary<string,string> check = Query(state);
                foreach (string key in Keys) {
                    if (check == null || Normal(check[key]) != Normal(state.Applied[key])) { Restore(state); Plain(state); return; }
                }
            } catch (Exception error) {
                Restore(state); Plain(state);
                Console.Error.WriteLine("[Jobs] Terminal style unavailable: " + error.Message);
            }
        }
        public static void Restore(State state) {
            if (state == null) { return; }
            try {
                if (state.Active) {
                    Dictionary<string,string> current = Query(state);
                    bool complete = current != null;
                    if (current != null) {
                        bool restoreForeground = Console.ForegroundColor == ConsoleColor.White && Normal(current["10"]) == Normal(state.Applied["10"]) && Normal(current["4;15"]) == Normal(state.Applied["4;15"]);
                        bool restoreBackground = Console.BackgroundColor == ConsoleColor.Black && Normal(current["11"]) == Normal(state.Applied["11"]) && Normal(current["4;0"]) == Normal(state.Applied["4;0"]);
                        foreach (string key in Keys) {
                            if (Normal(current[key]) == Normal(state.Applied[key])) { Console.Write(Escape(key,state.Original[key])); }
                            else if (Normal(current[key]) != Normal(state.Original[key])) {
                                complete = false; Console.Error.WriteLine("[Jobs] Kept a concurrent color change: " + key);
                            }
                        }
                        if (restoreForeground) { Console.ForegroundColor = state.Foreground; Console.Write("\x1b[39m"); }
                        if (restoreBackground) { Console.BackgroundColor = state.Background; Console.Write("\x1b[49m"); }
                    }
                    if (complete) {
                        Dictionary<string,string> check = Query(state);
                        foreach (string key in Keys) { if (check == null || Normal(check[key]) != Normal(state.Original[key])) { complete = false; } }
                    }
                    if (complete) { File.Delete(state.Recovery); }
                    else { Console.Error.WriteLine("[Jobs] Color restore needs review. Manual recovery: powershell -NoProfile -File \""+state.Recovery+"\""); }
                }
            } catch (Exception error) {
                Console.Error.WriteLine("[Jobs] Color restore failed: "+error.Message+"; recovery: "+state.Recovery);
            } finally {
                if (state.Owner != null && Environment.GetEnvironmentVariable(OwnerName) == state.Owner) { Environment.SetEnvironmentVariable(OwnerName,state.PreviousOwner); }
                state.Active = false;
                uint currentMode;
                if (state.ModeChanged && GetConsoleMode(state.Output,out currentMode) && currentMode == (state.OutputMode | 4)) { SetConsoleMode(state.Output,state.OutputMode); }
                state.ModeChanged = false;
                if (state.Fallback) {
                    foreach (KeyValuePair<string,string> pair in state.EnvironmentBefore) {
                        string applied = pair.Key == "FORCE_COLOR" || pair.Key == "CLICOLOR" ? "0" : "1";
                        if (Environment.GetEnvironmentVariable(pair.Key) == applied) { Environment.SetEnvironmentVariable(pair.Key,pair.Value); }
                    }
                    state.Fallback = false;
                }
            }
        }
    }
}
'@
        } catch {
            [Console]::Error.WriteLine('[Jobs] Terminal style setup failed; using plain output: ' + $_.Exception.Message)
            return @{ JobsTerminalPlainFallback = $true; Before = @{} }
        }
    }
    return New-Object Jobs.TerminalStyleV1.Native+State
}
# Guard setup is optional; failure keeps business behavior and the user's original terminal settings.
function Start-JobsTerminalStyle {
    param($State)
    if ($State -is [Collections.IDictionary] -and $State.Contains('JobsTerminalPlainFallback')) {
        foreach ($key in @('NO_COLOR', 'PLAIN_OUTPUT', 'FORCE_COLOR', 'CLICOLOR', 'ANSI_COLORS_DISABLED')) {
            $State.Before[$key] = [Environment]::GetEnvironmentVariable($key)
            [Environment]::SetEnvironmentVariable($key, $(if (@('FORCE_COLOR', 'CLICOLOR') -contains $key) { '0' } else { '1' }))
        }
        return
    }
    if ($null -ne $State) { [Jobs.TerminalStyleV1.Native]::Enter($State) }
}
# A finally block also runs for script exit and Ctrl+C; direct .NET calls avoid stopped pipelines.
function Stop-JobsTerminalStyle {
    param($State)
    if ($State -is [Collections.IDictionary] -and $State.Contains('JobsTerminalPlainFallback')) {
        foreach ($key in $State.Before.Keys) {
            $applied = if (@('FORCE_COLOR', 'CLICOLOR') -contains $key) { '0' } else { '1' }
            if ([Environment]::GetEnvironmentVariable($key) -ceq $applied) { [Environment]::SetEnvironmentVariable($key, $State.Before[$key]) }
        }
        return
    }
    if ($null -ne $State) { [Jobs.TerminalStyleV1.Native]::Restore($State) }
}
# END JOBS_TERMINAL_STYLE_V1

$__jobsTerminalStyleState = $null
try {
    if ($MyInvocation.InvocationName -ne '.') {
        $__jobsTerminalStyleState = New-JobsTerminalStyleState
        Start-JobsTerminalStyle $__jobsTerminalStyleState
    }
# BEGIN JOBS_TERMINAL_STYLE_ORIGINAL_BODY
function Test-JobsEnterChoiceColor {
    if ((Test-Path Env:NO_COLOR) -or $env:TERM -ieq 'dumb' -or $env:PLAIN_OUTPUT -eq '1') { return $false }
    $consoleType = [Console]
    if ($null -eq $consoleType.GetProperty('IsInputRedirected') -or $null -eq $consoleType.GetProperty('IsOutputRedirected')) { return $false }
    return ($Host.Name -ceq 'ConsoleHost' -and -not [Console]::IsInputRedirected -and -not [Console]::IsOutputRedirected)
}
# Older hosts keep native colors without sending unsupported bold escape sequences.
function Test-JobsEnterChoiceBold {
    $property = $Host.UI.PSObject.Properties['SupportsVirtualTerminal']
    return ($null -ne $property -and [bool]$property.Value)
}
# Separate ordinary question text from Enter and arbitrary-input options without changing words.
function Get-JobsEnterChoiceParts {
    param([string]$Text)
    $red = '(?:(?:\u8f93\u5165)?(?:\u4efb\u610f(?:\u975e\u7a7a)?(?:\u5b57\u7b26|\u5185\u5bb9|\u6587\u5b57|\u8f93\u5165)?|\u975e\u7a7a(?:\u8f93\u5165|\u5b57\u7b26|\u5185\u5bb9)?|(?:\u5176\u5b83|\u5176\u4ed6)(?:\u975e\u7a7a)?(?:\u8f93\u5165|\u5185\u5bb9|\u5b57\u7b26)?))|(?:any\s+(?:(?:other|non[- ]empty)\s+)?(?:input|text|characters?)|non[- ]empty\s+input)'
    $green = '(?:(?:\u76f4\u63a5|\u53ea\u9700|\u4ec5(?:\u9700)?|\u6309(?:\u4e0b)?|\u7a7a)?\s*\u56de\u8f66|(?:press\s+)?\bEnter\b(?!\s+(?:YES|REPAIR|CLEAN|CONTINUE)\b))'
    $pattern = '(?is)(?<red>(?:' + $red + ')[^;\uFF1B\r\n]*?(?=[;\uFF1B\r\n]|\z))|(?<green>(?:' + $green + ')[^;\uFF1B\r\n]*?(?=(?:' + $red + ')|[;\uFF1B\r\n]|\z))'
    $offset = 0
    foreach ($match in [regex]::Matches($Text, $pattern)) {
        if ($match.Index -gt $offset) { [pscustomobject]@{ Text = $Text.Substring($offset, $match.Index - $offset); Color = '' } }
        $prefix = [regex]::Split($Text.Substring(0, $match.Index), '[;\uFF1B\r\n]')[-1]
        $typed = $prefix -match '(?i)(?:\u8f93\u5165|\u952e\u5165|type|enter)\s*(?:\u5927\u5199\s*)?(?:YES|REPAIR|CLEAN|CONTINUE)\b|\u7cbe\u786e\u8f93\u5165|\u8f93\u5165[^;\uFF1B\r\n]*[\u540e\u518d]\s*$'
        $color = if ($match.Groups['red'].Success) { 'Red' } elseif ($typed) { '' } else { 'Green' }
        [pscustomobject]@{ Text = $match.Value; Color = $color }
        $offset = $match.Index + $match.Length
    }
    if ($offset -lt $Text.Length) { [pscustomobject]@{ Text = $Text.Substring($offset); Color = '' } }
}
# Native host text remains plain in information streams and logs; bold control is console-only.
function Write-JobsEnterChoiceText {
    [CmdletBinding()]
    param([Parameter(Position=0)][AllowNull()][object]$Object, [switch]$NoNewline, [ConsoleColor]$ForegroundColor, [ConsoleColor]$BackgroundColor, [object]$Separator = ' ')
    $text = if ($Object -is [array]) { $Object -join [string]$Separator } else { [string]$Object }
    if (-not (Test-JobsEnterChoiceColor)) {
        Write-Host $Object -NoNewline:$NoNewline -Separator $Separator
        return
    }
    $normal = @{}
    if ($PSBoundParameters.ContainsKey('ForegroundColor')) { $normal.ForegroundColor = $ForegroundColor }
    if ($PSBoundParameters.ContainsKey('BackgroundColor')) { $normal.BackgroundColor = $BackgroundColor }
    foreach ($part in @(Get-JobsEnterChoiceParts $text)) {
        if (-not $part.Color) { Write-Host $part.Text -NoNewline @normal; continue }
        $bold = Test-JobsEnterChoiceBold
        if ($bold) { [Console]::Write(([string][char]27) + '[1m') }
        try { Write-Host $part.Text -ForegroundColor $part.Color -NoNewline }
        finally { if ($bold) { [Console]::Write(([string][char]27) + '[0m') } }
    }
    if (-not $NoNewline) { Write-Host }
}
# Delegate the original reader, including secure input and EOF behavior, after prompt display.
function Read-JobsEnterChoiceHost {
    [CmdletBinding()]
    param([Parameter(Position=0)][string]$Prompt, [switch]$AsSecureString, [switch]$MaskInput)
    if ($AsSecureString -or $MaskInput -or -not (Test-JobsEnterChoiceColor) -or @((Get-JobsEnterChoiceParts $Prompt) | Where-Object { $_.Color }).Count -eq 0) {
        return (Read-Host @PSBoundParameters)
    }
    Write-JobsEnterChoiceText ($Prompt + ': ') -NoNewline
    return (Read-Host)
}

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$script:JobsLog = $null
function Read-JobsText([string]$Prompt, [string]$Default = '') {
    if ([Console]::IsInputRedirected) { throw '需要交互终端；输入重定向或 EOF 时停止。只读检查请传 -Check。' }
    $answer = Read-JobsEnterChoiceHost $Prompt
    if ($null -eq $answer) { throw '输入已结束。' }
    if ($answer -eq '' -and $Default -ne '') { return $Default }
    return $answer
}
function Confirm-JobsChange([string]$Message) {
    if ((Read-JobsText "$Message；精确输入 YES 执行，其它输入取消") -cne 'YES') { throw '用户取消，未执行该变更。' }
}
function Write-JobsLog([string]$Message) {
    Write-Host $Message
    if ($script:JobsLog) { Add-Content -LiteralPath $script:JobsLog -Value $Message -Encoding UTF8 }
}
function Invoke-JobsNative([string]$Executable, [string[]]$Arguments) {
    $previous = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try { & $Executable @Arguments 2>&1 | ForEach-Object { Write-JobsLog ([string]$_) }; $code = $LASTEXITCODE }
    finally { $ErrorActionPreference = $previous }
    if ($code -ne 0) { throw "$Executable 执行失败，退出码 $code" }
}
function Require-JobsCommand([string]$Name) {
    $command = Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (!$command) { throw "缺少 $Name。请安装后重开终端，或先运行对应安装入口。" }
    return $command.Source
}
function Get-JobsPath([string]$Prompt, [switch]$Directory, [switch]$AllowNew) {
    $raw = (Read-JobsText $Prompt).Trim().Trim('"')
    if ([string]::IsNullOrWhiteSpace($raw)) { throw '路径不能为空。' }
    # 路径内部的 %TEMP% 等可为合法文件名，仅显式环境变量根允许展开。
    if (!(Test-Path -LiteralPath $raw) -and $raw -match '^%([^%\\/]+)%([\\/].*|$)') {
        $variable = $Matches[1]; $suffix = $Matches[2]
        $base = [Environment]::GetEnvironmentVariable($variable, 'Process')
        if ([string]::IsNullOrEmpty($base)) { throw "环境变量未设置：$variable" }
        $raw = $base + $suffix
    }
    $full = [IO.Path]::GetFullPath($raw)
    $ancestor = $full
    while ($ancestor) {
        if (Test-Path -LiteralPath $ancestor) {
            $item = Get-Item -LiteralPath $ancestor -Force
            if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw '目标或上层目录是链接，停止。' }
        }
        $ancestor = [IO.Path]::GetDirectoryName($ancestor)
    }
    if (!$AllowNew -and !(Test-Path -LiteralPath $full)) { throw "路径不存在：$full" }
    if (Test-Path -LiteralPath $full) {
        $item = Get-Item -LiteralPath $full -Force
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { throw '拒绝符号链接或目录联接。' }
        if ($Directory -and !$item.PSIsContainer) { throw '需要目录。' }
        if (!$Directory -and $item.PSIsContainer) { throw '需要普通文件。' }
    }
    return $full
}
function Get-JobsFiles([string]$Root) {
    $skip = @('.git','node_modules','Pods','.dart_tool','build','DerivedData')
    $item = Get-Item -LiteralPath $Root -Force
    if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { return }
    if (!$item.PSIsContainer) { return $item }
    foreach ($child in Get-ChildItem -LiteralPath $Root -Force) {
        if ($child.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
        if ($child.PSIsContainer) { if ($skip -notcontains $child.Name) { Get-JobsFiles $child.FullName } }
        else { $child }
    }
}
function Backup-JobsFile([string]$Path) {
    $backup = $Path + '.jobs-backup-' + [DateTime]::Now.ToString('yyyyMMdd-HHmmss-fff') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,6)
    Copy-Item -LiteralPath $Path -Destination $backup -ErrorAction Stop
    Write-JobsLog "备份：$backup"
    return $backup
}
function Read-JobsUtf8([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes -contains 0) { throw "跳过二进制或 UTF-16 文件：$Path（仅支持严格 UTF-8）" }
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191
    $offset = 0; if ($hasBom) { $offset = 3 }
    $utf8 = New-Object Text.UTF8Encoding($false,$true)
    return @{ Text = $utf8.GetString($bytes,$offset,$bytes.Length-$offset); Bom = $hasBom }
}
function Write-JobsUtf8([string]$Path,[string]$Text,[bool]$Bom = $false) {
    [IO.File]::WriteAllText($Path,$Text,(New-Object Text.UTF8Encoding($Bom)))
}
function Get-JobsState([string]$Name) {
    $root = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'JobsCommandOthers'
    $path = Join-Path $root $Name
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    return $path
}
function Show-JobsSource([string]$Object,[string]$Source,[string]$Destination) {
    $safe = $Source
    $uri = $null
    if ([Uri]::TryCreate($Source,[UriKind]::Absolute,[ref]$uri) -and $uri.Host) {
        $builder = New-Object UriBuilder($uri); $builder.UserName='';$builder.Password='';$builder.Query='';$builder.Fragment='';$safe=$builder.Uri.AbsoluteUri
    }
    Write-JobsLog "来源｜$Object`n来源地址：$safe`n目标位置：$Destination"
}
function Install-JobsWinget([string]$Package) {
    $winget = Require-JobsCommand 'winget.exe'
    Show-JobsSource $Package 'https://github.com/microsoft/winget-pkgs' 'Windows 包管理器；最终安装位置由安装器决定'
    Confirm-JobsChange "安装 / 升级 $Package（来源 winget 社区软件目录，实际 URL 由 winget 解析；请先核对软件许可）"
    $mode = Read-JobsText '输入 upgrade 升级；回车安装' 'install'
    if ($mode -notin @('install','upgrade')) { throw '只接受 install 或 upgrade。' }
    Invoke-JobsNative $winget @($mode,'--id',$Package,'--exact','--source','winget')
}
function Require-JobsDocker {
    $docker = Require-JobsCommand 'docker.exe'
    Invoke-JobsNative $docker @('info','--format','{{.OSType}}')
    $type = & $docker info --format '{{.OSType}}' 2>$null
    if ($LASTEXITCODE -ne 0 -or "$type".Trim() -ne 'linux') { throw '需要已运行的 Docker Desktop Linux containers（WSL 2）；先启动引擎。' }
    return $docker
}
function Get-JobsContainer([string]$Docker,[string]$Name,[string]$Owner) {
    $text = & $Docker container ls -a --filter "name=^/$Name`$" --format '{{json .}}'
    if ($LASTEXITCODE -ne 0) { throw '无法查询容器。' }
    if (!$text) { return $null }
    $details = & $Docker inspect $Name
    if ($LASTEXITCODE -ne 0) { throw '无法检查容器。' }
    $item = @($details | ConvertFrom-Json)[0]
    if ($item.Config.Labels.'jobs.owner' -ne $Owner) { throw "同名容器不属于本工具，保留原状：$Name" }
    return $item
}
function Wait-JobsHttp([string]$Url,[int]$Seconds = 45) {
    $deadline = [DateTime]::UtcNow.AddSeconds($Seconds)
    while ([DateTime]::UtcNow -lt $deadline) {
        try { $r=Invoke-WebRequest -UseBasicParsing -Uri $Url -TimeoutSec 2; if ($r.StatusCode -lt 400) { Write-JobsLog "服务就绪：$Url"; return } } catch { }
        Start-Sleep -Milliseconds 500
    }
    throw "服务未在 $Seconds 秒内就绪：$Url；保留进程与日志供排查。"
}
# Jobs Windows 环境与服务业务函数；由入口显式调用。
function Get-JobsShState([string]$Name) {
    $root=Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'JobsSh'
    $path=Join-Path $root $Name;New-Item -ItemType Directory -Path $path -Force|Out-Null;return $path
}
function Get-JobsMySQLInfo([string]$Docker) {
    $item=Get-JobsContainer $Docker 'jobs-sh-mysql' 'JobsSh.MySQL'
    if(!$item){throw '本入口 MySQL 尚未创建，先运行 MySQL 管理工具。'}
    return $item
}
function Wait-JobsMySQL([string]$Docker) {
    $deadline=[DateTime]::UtcNow.AddSeconds(90)
    while([DateTime]::UtcNow -lt $deadline){
        $null=& $Docker exec jobs-sh-mysql mysqladmin ping --silent 2>$null
        if($LASTEXITCODE -eq 0){Write-JobsLog 'MySQL 已响应 ping；认证需要使用登录操作另验。';return}
        Start-Sleep -Seconds 1
    };throw 'MySQL 在 90 秒内未就绪，请查看容器日志。'
}
function New-JobsMySQL([string]$Docker,[string]$Volume,[switch]$EmptyPassword) {
    $state=Get-JobsShState 'MySQL';$config=Join-Path $state 'my.cnf'
    if(!(Test-Path -LiteralPath $config)){Write-JobsUtf8 $config "[mysqld]`ncharacter-set-server=utf8mb4`n"}
    if($config.Contains(',')){throw 'Docker配置目录不能含逗号。'}
    $image='mysql:8.4';Show-JobsSource 'MySQL 8.4 官方镜像' 'https://hub.docker.com/_/mysql' "$Volume → /var/lib/mysql；127.0.0.1:3306"
    $args=@('run','-d','--name','jobs-sh-mysql','--label','jobs.owner=JobsSh.MySQL','-p','127.0.0.1:3306:3306','--mount',"type=volume,source=$Volume,target=/var/lib/mysql",'--mount',"type=bind,source=$config,target=/etc/mysql/conf.d/jobs.cnf,readonly")
    if($EmptyPassword){$args+=@('-e','MYSQL_ALLOW_EMPTY_PASSWORD=yes');Invoke-JobsNative $Docker ($args+@($image));return}
    $secret=Read-Host '设置新 MySQL root 密码（不会写入日志）' -AsSecureString
    if($secret.Length -lt 8){throw '密码至少 8 字符。'}
    $pointer=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret);$previous=$env:MYSQL_ROOT_PASSWORD
    try{$env:MYSQL_ROOT_PASSWORD=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer);$args+=@('-e','MYSQL_ROOT_PASSWORD');Invoke-JobsNative $Docker ($args+@($image))}
    finally{$env:MYSQL_ROOT_PASSWORD=$previous;[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer);$secret.Dispose()}
}
function Invoke-JobsMySQL {
    $docker=Require-JobsDocker;$item=Get-JobsContainer $docker 'jobs-sh-mysql' 'JobsSh.MySQL';$action=Read-JobsText 'MySQL install / start / stop / status / login / logs' 'status'
    switch($action){
        'install'{if($item){throw '容器已存在，拒绝覆盖。'};Confirm-JobsChange '创建 MySQL 8.4 容器及独立持久数据卷；仅回环3306';New-JobsMySQL $docker ('jobs-sh-mysql-data-'+[Guid]::NewGuid().ToString('N'));Wait-JobsMySQL $docker}
        'start'{$null=Get-JobsMySQLInfo $docker;Confirm-JobsChange '启动本入口 MySQL';Invoke-JobsNative $docker @('start','jobs-sh-mysql');Wait-JobsMySQL $docker}
        'stop'{$null=Get-JobsMySQLInfo $docker;Confirm-JobsChange '停止本入口 MySQL';Invoke-JobsNative $docker @('stop','jobs-sh-mysql')}
        'status'{Invoke-JobsNative $docker @('ps','-a','--filter','name=^/jobs-sh-mysql$')}
        'logs'{$null=Get-JobsMySQLInfo $docker;Invoke-JobsNative $docker @('logs','--tail','100','jobs-sh-mysql')}
        'login'{$null=Get-JobsMySQLInfo $docker;& $docker exec -it jobs-sh-mysql mysql -u root -p;if($LASTEXITCODE -ne 0){throw 'MySQL 登录失败。'}}
        default{throw '未知动作。'}
    }
}
function Invoke-JobsMySQLConfig {
    $docker=Require-JobsDocker;$item=Get-JobsMySQLInfo $docker;$source=Get-JobsPath '选择已编辑的 my.cnf 配置文件';if($source.Contains(',')){throw 'Docker配置挂载路径不能含逗号。'};$state=Get-JobsShState 'MySQL';$target=Join-Path $state 'my.cnf'
    $mount=@($item.Mounts|Where-Object{$_.Destination -eq '/etc/mysql/conf.d/jobs.cnf'})
    if($mount.Count -ne 1 -or ![StringComparer]::OrdinalIgnoreCase.Equals($mount[0].Source,$target)){throw '容器配置挂载与本工具状态不一致，保留原状。'}
    Show-JobsSource 'MySQL 配置' $source $target
    Invoke-JobsNative $docker @('run','--rm','--network','none','--mount',"type=bind,source=$source,target=/etc/mysql/conf.d/jobs.cnf,readonly",$item.Config.Image,'mysqld','--validate-config')
    Confirm-JobsChange '备份应用配置并重启本入口 MySQL；失败恢复配置'
    $backup=Backup-JobsFile $target;$wasRunning=[bool]$item.State.Running
    try{Copy-Item -LiteralPath $source -Destination $target -Force;if($wasRunning){Invoke-JobsNative $docker @('restart','jobs-sh-mysql');Wait-JobsMySQL $docker}}
    catch{Copy-Item -LiteralPath $backup -Destination $target -Force;if($wasRunning){Invoke-JobsNative $docker @('restart','jobs-sh-mysql')};throw}
    Write-JobsLog "配置已应用，备份：$backup"
}
function Invoke-JobsMySQLReset {
    $docker=Require-JobsDocker;$item=Get-JobsMySQLInfo $docker;$backupName='jobs-sh-mysql-backup-'+[DateTime]::Now.ToString('yyyyMMddHHmmss');$newVolume='jobs-sh-mysql-data-'+[Guid]::NewGuid().ToString('N')
    Confirm-JobsChange '停止旧数据库并保留完整容器/数据卷，创建全新 root 空密码 MySQL；仅绑定回环端口，旧数据不会导入'
    $wasRunning=[bool]$item.State.Running;$stopped=$false;$renamed=$false
    try{
        Invoke-JobsNative $docker @('stop','jobs-sh-mysql');$stopped=$true
        Invoke-JobsNative $docker @('rename','jobs-sh-mysql',$backupName);$renamed=$true
        New-JobsMySQL $docker $newVolume -EmptyPassword;Wait-JobsMySQL $docker;Invoke-JobsNative $docker @('exec','jobs-sh-mysql','mysql','-u','root','--skip-password','-e','SELECT @@datadir, CURRENT_USER();')
    }
    catch{
        if($renamed){
            $new=Get-JobsContainer $docker 'jobs-sh-mysql' 'JobsSh.MySQL'
            if($new){Invoke-JobsNative $docker @('rm','-f','jobs-sh-mysql')}
            Invoke-JobsNative $docker @('rename',$backupName,'jobs-sh-mysql')
        }
        if($wasRunning -and $stopped){Invoke-JobsNative $docker @('start','jobs-sh-mysql')};throw
    }
    Write-JobsLog "已实连验证空密码；旧容器 $backupName 和全部旧卷保留；恢复前先停止并移走新容器，再恢复旧名称。"
}
function Invoke-JobsMySQLRemove {
    $docker=Require-JobsDocker;$item=Get-JobsMySQLInfo $docker;$volumes=@($item.Mounts|Where-Object{$_.Type -eq 'volume' -and $_.Destination -eq '/var/lib/mysql'})
    Confirm-JobsChange '停止并删除本工具 MySQL 容器，默认保留全部数据卷与其它 MySQL'
    Invoke-JobsNative $docker @('stop','jobs-sh-mysql');Invoke-JobsNative $docker @('rm','jobs-sh-mysql')
    foreach($volume in $volumes){
        Write-JobsLog "保留数据卷：$($volume.Name)"
        if((Read-JobsText '不可恢复删除这个数据卷？精确输入其完整卷名才继续') -ceq $volume.Name){
            if($volume.Name -notmatch '^jobs-sh-mysql-data-[a-f0-9]{32}$'){throw '卷名不属于本工具，拒绝删除。'}
            Confirm-JobsChange "永久删除数据卷 $($volume.Name)";Invoke-JobsNative $docker @('volume','rm',$volume.Name)
        }
    }
}
function Invoke-JobsGoProject {
    if((Read-JobsText '输入 install 安装 / 升级 Go；回车创建工程') -ceq 'install'){Install-JobsWinget 'GoLang.Go';Write-JobsLog '安装后重开终端，再创建工程。';return}
    $go=Require-JobsCommand 'go.exe';Invoke-JobsNative $go @('version');$parent=Get-JobsPath '选择工程父目录' -Directory;$name=Read-JobsText '工程目录名'
    if($name -notmatch '^[A-Za-z0-9_-]+$'){throw '工程名仅支持字母数字下划线短横线。'}
    $module=Read-JobsText 'Go module（例如 example.com/myapp）';if($module -notmatch '^[A-Za-z0-9][A-Za-z0-9._/-]+$' -or $module.Contains('..')){throw '无效 module。'}
    $target=Join-Path $parent $name;if(Test-Path -LiteralPath $target){throw '工程目录已存在，拒绝覆盖。'}
    Confirm-JobsChange "创建 Gin 工程 $target";New-Item -ItemType Directory -Path $target|Out-Null
    $code=@'
package main

import "github.com/gin-gonic/gin"

func main() {
    router := gin.Default()
    router.GET("/ping", func(c *gin.Context) {
        c.JSON(200, gin.H{"message": "pong"})
    })
    if err := router.Run("127.0.0.1:8080"); err != nil {
        panic(err)
    }
}
'@
    Write-JobsUtf8 (Join-Path $target 'main.go') $code
    Push-Location -LiteralPath $target
    try{
        Invoke-JobsNative $go @('mod','init',$module)
        if((Read-JobsText '下载 Gin 依赖并校验？YES 执行，其它保留源码') -ceq 'YES'){
            Show-JobsSource 'Gin module' 'https://github.com/gin-gonic/gin' $target;Invoke-JobsNative $go @('mod','tidy');Invoke-JobsNative $go @('test','./...')
            if((Read-JobsText '前台运行？YES 执行；Ctrl+C 停止') -ceq 'YES'){Invoke-JobsNative $go @('run','.')}
        }
    }finally{Pop-Location}
    Write-JobsLog "工程：$target"
}
function Invoke-JobsHEIC {
    if((Read-JobsText '输入 install 安装 / 升级 ImageMagick；回车转换图片') -ceq 'install'){Install-JobsWinget 'ImageMagick.ImageMagick';Write-JobsLog '安装后重开终端，再转换图片。';return}
    $magick=Require-JobsCommand 'magick.exe';$root=Get-JobsPath '选择 HEIC 输入目录（仅第一层）' -Directory;$output=Join-Path $root 'JPEG';$files=@(Get-ChildItem -LiteralPath $root -File|Where-Object{$_.Extension -ieq '.heic'})
    if($files.Count -eq 0){Write-JobsLog '没有 HEIC 文件。';return}
    Confirm-JobsChange "将 $($files.Count) 张 HEIC 转为 $output 下 JPEG；已有目标跳过";New-Item -ItemType Directory -Path $output -Force|Out-Null;$failed=0
    foreach($file in $files){$target=Join-Path $output ($file.BaseName+'.jpg');if(Test-Path -LiteralPath $target){Write-JobsLog "已存在，跳过：$target";continue};$stage=Join-Path $output ([Guid]::NewGuid().ToString('N')+'.jpg')
        try{Invoke-JobsNative $magick @($file.FullName,'-auto-orient','-quality','92',$stage);Move-Item -LiteralPath $stage -Destination $target;Write-JobsLog "已转换：$target"}catch{$failed++;Write-JobsLog "失败：$($file.FullName)"}finally{if(Test-Path -LiteralPath $stage){Remove-Item -LiteralPath $stage}}
    };if($failed){throw "$failed 张转换失败。"}
}
function Invoke-JobsJava {
    $action=Read-JobsText 'Java check / install / configure / restore' 'check';$state=Get-JobsShState 'Java';$backup=Join-Path $state 'environment.json'
    switch($action){
        'install'{Install-JobsWinget 'EclipseAdoptium.Temurin.21.JDK';Write-JobsLog '安装完成后重开终端运行 check / configure。'}
        'check'{$java=Require-JobsCommand 'java.exe';$javac=Require-JobsCommand 'javac.exe';Invoke-JobsNative $java @('-version');Invoke-JobsNative $javac @('-version');Write-JobsLog "JAVA_HOME：$env:JAVA_HOME"}
        'configure'{
            $root=Get-JobsPath '选择 JDK 根目录（含 bin/java.exe 与 bin/javac.exe）' -Directory
            foreach($tool in @('java.exe','javac.exe')){if(!(Test-Path -LiteralPath (Join-Path $root "bin\$tool"))){throw "JDK 缺少 $tool"}}
            Invoke-JobsNative (Join-Path $root 'bin\java.exe') @('-version');Confirm-JobsChange "设置当前用户 JAVA_HOME 为 $root；备份用户变量，不修改系统变量"
            if(Test-Path -LiteralPath $backup){throw "已有未恢复备份：$backup；先 restore 或人工归档。"}
            $oldHome=[Environment]::GetEnvironmentVariable('JAVA_HOME','User');$oldPath=[Environment]::GetEnvironmentVariable('Path','User');$newPath=(Join-Path $root 'bin')+';'+$oldPath
            @{OldHome=$oldHome;OldPath=$oldPath;NewHome=$root;NewPath=$newPath}|ConvertTo-Json|Set-Content -LiteralPath $backup -Encoding UTF8
            [Environment]::SetEnvironmentVariable('JAVA_HOME',$root,'User');[Environment]::SetEnvironmentVariable('Path',$newPath,'User');$env:JAVA_HOME=$root;$env:Path=(Join-Path $root 'bin')+';'+$env:Path;Write-JobsLog "备份：$backup；新终端生效。"
        }
        'restore'{
            $r=Get-Content -LiteralPath $backup -Raw|ConvertFrom-Json
            if([Environment]::GetEnvironmentVariable('JAVA_HOME','User') -cne $r.NewHome -or [Environment]::GetEnvironmentVariable('Path','User') -cne $r.NewPath){throw '环境已被后续修改，拒绝覆盖，请按备份人工合并。'}
            Confirm-JobsChange '恢复本工具修改前用户 JAVA_HOME 与 Path';[Environment]::SetEnvironmentVariable('JAVA_HOME',$r.OldHome,'User');[Environment]::SetEnvironmentVariable('Path',$r.OldPath,'User');Remove-Item -LiteralPath $backup
        }
        default{throw '未知动作。'}
    }
}
function Invoke-JobsWebContainer([string]$Kind) {
    $docker=Require-JobsDocker
    if($Kind -eq 'PhpApache'){$name='jobs-sh-php-apache';$image='php:8.4-apache';$containerRoot='/var/www/html';$port=8082;$containerPort=80;$source='https://hub.docker.com/_/php'}else{$name='jobs-sh-tomcat';$image='tomcat:10.1-jdk21-temurin';$containerRoot='/usr/local/tomcat/webapps';$port=8083;$containerPort=8080;$source='https://hub.docker.com/_/tomcat'}
    $owner='JobsSh.'+$Kind;$item=Get-JobsContainer $docker $name $owner;$action=Read-JobsText '输入 install / start / stop / status / logs / remove' 'status'
    switch($action){
        'install'{
            if($item){throw '容器已存在，拒绝覆盖。'};$site=Get-JobsPath $(if($Kind -eq 'PhpApache'){'选择 PHP 网站目录'}else{'选择包含 ROOT/ 或应用.war 的 webapps 目录'}) -Directory
            Confirm-JobsChange "创建 $Kind 容器，只读挂载 $site；仅回环端口 $port"
            Show-JobsSource $Kind $source "$name；$site → $containerRoot"
            if($Kind -eq 'PhpApache'){
                if($site.Contains(',')){throw 'Docker bind 目录不能含逗号；请选择其它路径。'}
                Invoke-JobsNative $docker @('run','-d','--name',$name,'--label',"jobs.owner=$owner",'-p',"127.0.0.1:${port}:$containerPort",'--mount',"type=bind,source=$site,target=$containerRoot,readonly",$image)
            }else{
                $volume='jobs-sh-tomcat-webapps-'+[Guid]::NewGuid().ToString('N')
                Invoke-JobsNative $docker @('create','--name',$name,'--label',"jobs.owner=$owner",'-p',"127.0.0.1:${port}:$containerPort",'--mount',"type=volume,source=$volume,target=$containerRoot",$image)
                Invoke-JobsNative $docker @('cp',($site+[IO.Path]::DirectorySeparatorChar+'.'),("${name}:$containerRoot"))
                Invoke-JobsNative $docker @('start',$name)
                Write-JobsLog "Tomcat部署副本保存在数据卷 $volume；支持WAR解包，保留主机源文件。"
            }
            if($Kind -eq 'PhpApache'){Invoke-JobsNative $docker @('exec',$name,'apache2ctl','-t')}else{Invoke-JobsNative $docker @('exec',$name,'catalina.sh','version')}
            Wait-JobsHttp "http://127.0.0.1:$port/" 45
        }
        'start'{if(!$item){throw '先 install。'};Confirm-JobsChange "启动 $name";Invoke-JobsNative $docker @('start',$name);Wait-JobsHttp "http://127.0.0.1:$port/" 45}
        'stop'{if(!$item){throw '容器未创建。'};Confirm-JobsChange "停止 $name";Invoke-JobsNative $docker @('stop',$name)}
        'status'{Invoke-JobsNative $docker @('ps','-a','--filter',"name=^/$name`$")}
        'logs'{if(!$item){throw '容器未创建。'};Invoke-JobsNative $docker @('logs','--tail','100',$name)}
        'remove'{if(!$item){throw '容器未创建。'};Confirm-JobsChange "删除 $name 容器，保留网站源目录";Invoke-JobsNative $docker @('stop',$name);Invoke-JobsNative $docker @('rm',$name)}
        default{throw '未知动作。'}
    }
}
function Invoke-JobsVideo {
    $python=Require-JobsCommand 'python.exe';$action=Read-JobsText '输入 download 下载；install 安装 / 升级 you-get' 'download'
    if($action -eq 'install'){Show-JobsSource 'you-get' 'https://pypi.org/project/you-get/' '当前用户 Python site-packages';Confirm-JobsChange 'pip --user 安装或升级 you-get';Invoke-JobsNative $python @('-m','pip','install','--user','--upgrade','you-get');return}
    if($action -ne 'download'){throw '未知动作。'}
    $url=Read-JobsText '输入有权下载的 HTTP / HTTPS 视频页面 URL';$uri=$null
    if(![Uri]::TryCreate($url,[UriKind]::Absolute,[ref]$uri)-or $uri.Scheme -notin @('http','https')){throw '只接受 HTTP / HTTPS URL。'}
    $output=Get-JobsPath '选择输出目录' -Directory;Show-JobsSource '视频' $url $output;Confirm-JobsChange '下载媒体至指定目录（可能联网；仅处理你有权下载的内容）'
    Invoke-JobsNative $python @('-m','you_get','--output-dir',$output,'--',$url)
}
function Invoke-JobsGem {
    $gem=Require-JobsCommand 'gem.cmd';Invoke-JobsNative $gem @('--version');Invoke-JobsNative $gem @('sources','--list');$action=Read-JobsText 'Gem status / source / update / cleanup' 'status'
    switch($action){
        'status'{Invoke-JobsNative $gem @('environment')}
        'source'{
            $choice=Read-JobsText '输入 official 官方源；china Ruby China' 'official';if($choice -eq 'official'){$url='https://rubygems.org/'}elseif($choice -eq 'china'){$url='https://gems.ruby-china.com/'}else{throw '无效软件源。'}
            $config=Join-Path $env:USERPROFILE '.gemrc';Confirm-JobsChange "备份用户 Gem 配置并将软件源设置为 $url";if(Test-Path -LiteralPath $config){$null=Backup-JobsFile $config}
            $old=@(& $gem sources --list|Where-Object{$_ -match '^https?://'})
            foreach($source in $old){Invoke-JobsNative $gem @('sources','--remove',$source)};Show-JobsSource 'Gem source' $url $config;Invoke-JobsNative $gem @('sources','--add',$url)
        }
        'update'{Confirm-JobsChange '升级当前 Ruby 环境的 RubyGems 与全部 Gem（原生扩展需要 RubyInstaller DevKit）';Invoke-JobsNative $gem @('update','--system');Invoke-JobsNative $gem @('update')}
        'cleanup'{Confirm-JobsChange '清理当前 Ruby 环境旧版 Gem';Invoke-JobsNative $gem @('cleanup')}
        default{throw '未知动作。'}
    }
}
function Invoke-JobsRuby {
    $winget=Require-JobsCommand 'winget.exe';Invoke-JobsNative $winget @('search','RubyInstaller','--source','winget')
    $id=Read-JobsText '从上表复制精确 RubyInstaller 包 ID（版本由你选择）';if($id -notmatch '^RubyInstallerTeam\.Ruby(?:WithDevKit)?\.[0-9.]+$'){throw '仅接受 RubyInstallerTeam 的明确版本 ID。'}
    Install-JobsWinget $id;Write-JobsLog '安装完成后重开终端验证 ruby -v、gem -v；未知第三方 Ruby 管理器不覆盖。'
}
function Invoke-JobsAppendProtected {
    $path=Get-JobsPath '输入唯一目标文本文件（受保护路径需自行用管理员终端启动）';$doc=Read-JobsUtf8 $path;$hash=(Get-FileHash -LiteralPath $path).Hash;$line=Read-JobsText '输入追加一行（内容不写日志）'
    if([string]::IsNullOrWhiteSpace($line)){throw '内容不能为空。'}
    Confirm-JobsChange "备份后向 $path 追加一行（保留 UTF-8 BOM 与原文）";$backup=Backup-JobsFile $path
    if((Get-FileHash -LiteralPath $path).Hash -ne $hash){throw '文件有并发修改，停止。'}
    $separator='';if($doc.Text -and !$doc.Text.EndsWith("`n")){$separator="`r`n"};Write-JobsUtf8 $path ($doc.Text+$separator+$line+"`r`n") $doc.Bom
    Write-JobsLog "已写入；恢复备份：$backup"
}
function Invoke-JobsExtensions {
    $key='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced';$current=Get-ItemProperty -LiteralPath $key -Name HideFileExt
    Write-JobsLog "当前 HideFileExt：$($current.HideFileExt)；Windows 按当前用户全局控制扩展名显示，没有 Finder 的逐文件开关。"
    $mode=Read-JobsText '输入 hide 隐藏已知扩展名；show 显示；其它取消';if($mode -notin @('hide','show')){return}
    Confirm-JobsChange "设置当前用户资源管理器扩展名显示 $mode（范围为全部文件夹；保留真实文件名）"
    $state=Get-JobsShState 'Explorer';@{HideFileExt=$current.HideFileExt}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $state ('extensions-'+[DateTime]::Now.ToString('yyyyMMddHHmmss')+'.json')) -Encoding UTF8
    $value=1;if($mode -eq 'show'){$value=0};Set-ItemProperty -LiteralPath $key -Name HideFileExt -Value $value
    Write-JobsLog '设置已写入；关闭并重新打开资源管理器窗口后查看。恢复时运行本入口选择原状态。'
}
function Invoke-JobsDockerSetup {
    $action=Read-JobsText 'Docker check / install / open' 'check'
    switch($action){
        'install'{Install-JobsWinget 'Docker.DockerDesktop';Write-JobsLog '完成后按 Docker Desktop 引导启用 WSL 2 / 虚拟化并确认许可，重启要求由安装器决定。'}
        'open'{$desktop=Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe';if(!(Test-Path -LiteralPath $desktop)){throw '尚未安装 Docker Desktop。'};Confirm-JobsChange '打开 Docker Desktop';Start-Process -FilePath $desktop;Write-JobsLog '等待 Desktop 显示引擎就绪后再运行 check。'}
        'check'{$docker=Require-JobsCommand 'docker.exe';Invoke-JobsNative $docker @('--version');Invoke-JobsNative $docker @('version');Invoke-JobsNative $docker @('info');Write-JobsLog 'CLI 与引擎均已响应。'}
        default{throw '未知动作。'}
    }
}
function Invoke-JobsShTool([string]$Tool,[switch]$Check) {
    $script:JobsLog=$null
    $summary=@{'MySQL'='安装/管理专属 MySQL8.4 Docker容器；只回环3306，数据卷持久保留。';'MySQLConfig'='隔离验证并备份应用 MySQL配置，按原服务状态重启；失败恢复。';'MySQLReset'='保留旧容器与数据，另建全新空密码 MySQL，仅供本机测试并实连验证。';'MySQLRemove'='卸载本工具MySQL容器，默认保留数据；独立二次确认才删除明确数据卷。';'GoProject'='可选安装Go，创建新的Gin工程；依赖下载、测试、运行分别确认。';'HEIC2Jpg'='可选安装ImageMagick，将第一层HEIC转到JPEG目录，保留原图和既有目标。';'Java'='检查/安装Java；备份后配置或精确恢复当前用户JAVA_HOME和Path。';'PhpApache'='安装/管理PHP与Apache官方容器；只读挂载网站目录，回环8082。';'Tomcat'='安装/管理Tomcat官方容器；复制部署文件到持久卷，回环8083，保留源文件。';'VideoDownload'='安装you-get或下载本人有权使用的网页视频至所选目录，显示脱敏来源。';'Gem'='检查RubyGems，选择备份修改软件源、升级或清理旧Gem。';'Ruby'='从winget目录选择明确RubyInstaller版本并安装/升级，不覆盖未知管理器。';'AppendProtected'='备份后向选定普通UTF-8文件追加一行，权限不足停止，不自动提权。';'FileExtensions'='经明确确认设置当前用户全部Explorer窗口扩展名显示，保留真实文件名。';'Docker'='检查CLI与引擎、可选安装/升级并打开Docker Desktop，不自动修改WSL/系统功能。'}
    Write-Host ("Jobs Windows｜$Tool`n用途与影响："+$summary[$Tool]+"`n确认后显示实际日志位置；Ctrl+C 取消，危险变更精确 YES。")
    if($Check){
        $dependencies=@{MySQL=@('docker.exe');MySQLConfig=@('docker.exe');MySQLReset=@('docker.exe');MySQLRemove=@('docker.exe');GoProject=@('go.exe');HEIC2Jpg=@('magick.exe');Java=@('java.exe','javac.exe');PhpApache=@('docker.exe');Tomcat=@('docker.exe');VideoDownload=@('python.exe');Gem=@('ruby.exe','gem.cmd');Ruby=@('winget.exe');Docker=@('docker.exe')}
        Write-Host '只读检查：入口与模块加载成功；只查询命令是否存在，不启动或写业务文件。'
        if($dependencies.ContainsKey($Tool)){foreach($name in $dependencies[$Tool]){$found=Get-Command $name -ErrorAction SilentlyContinue;Write-Host ($name+': '+$(if($found){'已发现'}else{'未发现'}))}}
        return
    }
    if([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT){throw '本入口仅支持 Windows；当前平台只能使用 -Check。'}
    if((Read-JobsText '按回车继续；任意字符取消') -ne ''){return}
    $script:JobsLog=Join-Path ([IO.Path]::GetTempPath()) ("JobsSh-"+$Tool+'-'+[Guid]::NewGuid().ToString('N')+'.log');Write-JobsLog "日志：$script:JobsLog"
    switch($Tool){
        'MySQL'{Invoke-JobsMySQL};'MySQLConfig'{Invoke-JobsMySQLConfig};'MySQLReset'{Invoke-JobsMySQLReset};'MySQLRemove'{Invoke-JobsMySQLRemove};'GoProject'{Invoke-JobsGoProject};'HEIC2Jpg'{Invoke-JobsHEIC};'Java'{Invoke-JobsJava};'PhpApache'{Invoke-JobsWebContainer 'PhpApache'};'Tomcat'{Invoke-JobsWebContainer 'Tomcat'};'VideoDownload'{Invoke-JobsVideo};'Gem'{Invoke-JobsGem};'Ruby'{Invoke-JobsRuby};'AppendProtected'{Invoke-JobsAppendProtected};'FileExtensions'{Invoke-JobsExtensions};'Docker'{Invoke-JobsDockerSetup};default{throw "未知工具：$Tool"}
    }
}

# END JOBS_TERMINAL_STYLE_ORIGINAL_BODY
} finally {
    Stop-JobsTerminalStyle $__jobsTerminalStyleState
}

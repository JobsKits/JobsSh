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
# 将选择器诊断交给当前业务日志，先剥离控制码并脱敏展示地址。
function Write-JobsFzfStatus {
    [CmdletBinding()]
    param([string]$Text)
    $plain = $Text -replace '\x1b\][^\x07]*(?:\x07|\x1b\\)', '' -replace '\x1b\[[0-?]*[ -/]*[@-~]', ''
    $plain = $plain -replace '(?i)([a-z][a-z0-9+.-]*://)[^\s/@]+@', '$1***@' -replace '(?i)(https?://[^\s?#]+)[?#][^\s]*', '$1?[已省略]'
    foreach ($name in @('Write-JobsHarmonyMessage', 'Write-JobsPackagerMessage', 'Write-JobsLog', 'Write-JobsUrlText')) {
        $writer = Get-Command $name -CommandType Function -ErrorAction SilentlyContinue
        if ($writer) { & $writer $plain; return }
    }
    Write-Host $plain
}
# 复用现有 Windows argv 引号规则，不通过命令字符串求值。
function ConvertTo-JobsFzfArgument {
    param([AllowNull()][AllowEmptyString()][string]$Value)
    if ($null -eq $Value) { $Value = '' }
    if ($Value.IndexOf([char]0) -ge 0) { throw '参数不能包含空字符。' }
    $quoted = New-Object Text.StringBuilder
    [void]$quoted.Append('"')
    $slashes = 0
    foreach ($character in $Value.ToCharArray()) {
        if ($character -eq [char]92) { $slashes++; continue }
        if ($character -eq [char]34) {
            [void]$quoted.Append([char]92, (2 * $slashes + 1))
            [void]$quoted.Append([char]34)
        } else {
            if ($slashes -gt 0) { [void]$quoted.Append([char]92, $slashes) }
            [void]$quoted.Append($character)
        }
        $slashes = 0
    }
    if ($slashes -gt 0) { [void]$quoted.Append([char]92, (2 * $slashes)) }
    [void]$quoted.Append('"')
    return $quoted.ToString()
}
# 仅清理本次启动的 fzf；探针有单次上限，交互沿原终端运行，不改父进程环境。
function Invoke-JobsFzfProcess {
    param([string]$Executable, [string[]]$NativeArguments, [string[]]$InputLines = @(), [switch]$Probe)
    $start = New-Object Diagnostics.ProcessStartInfo
    $start.FileName = $Executable
    $start.Arguments = (@($NativeArguments | ForEach-Object { ConvertTo-JobsFzfArgument $_ }) -join ' ')
    $start.UseShellExecute = $false
    $start.CreateNoWindow = $false
    $start.RedirectStandardInput = $true
    $start.RedirectStandardOutput = $true
    $start.RedirectStandardError = [bool]$Probe
    $start.StandardOutputEncoding = New-Object Text.UTF8Encoding($false)
    if ($Probe) { $start.StandardErrorEncoding = New-Object Text.UTF8Encoding($false) }
    foreach ($key in @('FZF_DEFAULT_OPTS', 'FZF_DEFAULT_OPTS_FILE', 'FZF_DEFAULT_COMMAND')) { [void]$start.EnvironmentVariables.Remove($key) }
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $start
    try {
        [void]$process.Start()
        $outputTask = $process.StandardOutput.ReadToEndAsync()
        $errorTask = if ($Probe) { $process.StandardError.ReadToEndAsync() } else { $null }
        $inputWriter = New-Object IO.StreamWriter($process.StandardInput.BaseStream, (New-Object Text.UTF8Encoding($false)))
        $inputWriter.NewLine = "`n"
        try { foreach ($line in $InputLines) { $inputWriter.WriteLine($line) } } finally { $inputWriter.Dispose() }
        if ($Probe) {
            if (-not $process.WaitForExit(10000)) {
                $process.Kill(); $process.WaitForExit()
                return [pscustomobject]@{ Code = 124; Lines = @(); Error = 'fzf 健康探针超时（10 秒）。' }
            }
        } else { $process.WaitForExit() }
        $output = $outputTask.GetAwaiter().GetResult()
        $errorText = if ($errorTask) { $errorTask.GetAwaiter().GetResult() } else { '' }
        $lines = @()
        if ($output.Length -gt 0) { $lines = @($output.Replace("`r`n", "`n").TrimEnd([char]10) -split "`n") }
        return [pscustomobject]@{ Code = $process.ExitCode; Lines = $lines; Error = $errorText }
    } finally {
        try { if ($process.Id -gt 0 -and -not $process.HasExited) { $process.Kill(); $process.WaitForExit() } } catch { }
        $process.Dispose()
    }
}
# 检验真实路径、版本及实际单选/复选面板选项；不打开界面或获取依赖。
function Test-JobsFzfPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not [IO.File]::Exists($Path)) { return $false }
    try {
        $version = Invoke-JobsFzfProcess $Path @('--version') -Probe
        if ($version.Code -ne 0) { return $false }
        $marker = '__JOBS_FZF_HEALTH__'
        $probe = Invoke-JobsFzfProcess $Path @('--filter', $marker, '--no-multi', '--sync', '--layout=reverse', '--height=60%', '--border', '--delimiter', "`t", '--with-nth=2..', '--print-query', '--expect=left,space,enter', '--bind=up:up,down:down,tab:down,shift-tab:up,start:pos(1)') @("P`t$marker") -Probe
        return ($probe.Code -eq 0 -and $probe.Lines.Count -gt 0 -and $probe.Lines[-1] -ceq "P`t$marker")
    } catch [Management.Automation.PipelineStoppedException] { throw } catch { return $false }
}
# 发现当前和常见用户级安装位置，不因别名或损坏路径误判已经就绪。
function Find-JobsFzf {
    $candidates = New-Object 'Collections.Generic.List[string]'
    foreach ($name in @('fzf.exe', 'fzf')) {
        $command = Get-Command $name -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($command) { $candidates.Add($command.Source) }
    }
    if ($env:LOCALAPPDATA) {
        $candidates.Add((Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Links/fzf.exe'))
        $packages = Join-Path $env:LOCALAPPDATA 'Microsoft/WinGet/Packages'
        if ([IO.Directory]::Exists($packages)) {
            foreach ($directory in @(Get-ChildItem -LiteralPath $packages -Directory -Filter 'junegunn.fzf*' -ErrorAction SilentlyContinue)) {
                foreach ($file in @(Get-ChildItem -LiteralPath $directory.FullName -File -Recurse -Filter 'fzf.exe' -ErrorAction SilentlyContinue)) { $candidates.Add($file.FullName) }
            }
        }
    }
    if ($env:USERPROFILE) { $candidates.Add((Join-Path $env:USERPROFILE 'scoop/shims/fzf.exe')) }
    if ($env:ChocolateyInstall) { $candidates.Add((Join-Path $env:ChocolateyInstall 'bin/fzf.exe')) }
    foreach ($candidate in @($candidates | Select-Object -Unique)) { if (Test-JobsFzfPath $candidate) { return $candidate } }
    return $null
}
# 只刷新本次进程的工具搜索路径，不改写用户或系统 PATH。
function Update-JobsProcessPath {
    param([string]$ExecutableDirectory)
    $parts = New-Object 'Collections.Generic.List[string]'
    $separator = [IO.Path]::PathSeparator
    foreach ($value in @($ExecutableDirectory, [Environment]::GetEnvironmentVariable('Path', 'User'), [Environment]::GetEnvironmentVariable('Path', 'Machine'), $env:Path)) {
        foreach ($part in @(([string]$value) -split [regex]::Escape([string]$separator))) {
            if (-not [string]::IsNullOrWhiteSpace($part) -and -not $parts.Contains($part)) { $parts.Add($part) }
        }
    }
    $env:Path = $parts -join [string]$separator
}
# 查找当前用户已就绪的原生包管理器；只读调用不注册或安装组件。
function Find-JobsWinget {
    $command = Get-Command 'winget.exe' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    $candidates = @()
    if ($command) { $candidates += $command.Source }
    if ($env:LOCALAPPDATA) { $candidates += Join-Path $env:LOCALAPPDATA 'Microsoft/WindowsApps/winget.exe' }
    foreach ($candidate in @($candidates | Select-Object -Unique)) {
        if (-not [IO.File]::Exists($candidate)) { continue }
        try { $probe = Invoke-JobsFzfProcess $candidate @('--version') -Probe; if ($probe.Code -eq 0) { return $candidate } } catch [Management.Automation.PipelineStoppedException] { throw } catch { }
    }
    return $null
}
# 必需依赖才恢复当前用户 App Installer 注册或打开一次官方安装界面，并在原流程等待就绪。
function Get-JobsRequiredWinget {
    $winget = Find-JobsWinget
    if ($winget) { return $winget }
    if ([Environment]::OSVersion.Platform -ne [PlatformID]::Win32NT) { throw '当前不是 Windows，未调用 App Installer 或安装 Windows 依赖。' }
    Write-JobsFzfStatus '本次需要 Windows 原生 App Installer/winget；仅注册当前用户已有组件，不接受许可或修改系统策略。'
    $registration = Get-Command Add-AppxPackage -ErrorAction SilentlyContinue
    if ($registration -and $registration.Parameters.ContainsKey('RegisterByFamilyName')) {
        try { Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop } catch { Write-JobsFzfStatus ('App Installer 注册未就绪：' + $_.Exception.Message) }
        $winget = Find-JobsWinget
        if ($winget) { Update-JobsProcessPath ([IO.Path]::GetDirectoryName($winget)); return $winget }
    }
    Write-JobsFzfStatus '官方 App Installer：https://apps.microsoft.com/detail/9NBLGGH4NNS1；将打开一次官方页面。请按系统要求完成安装/许可，本入口持续复检并续行，Ctrl+C 停止等待。'
    Start-Process -FilePath 'ms-windows-store://pdp/?ProductId=9NBLGGH4NNS1' -ErrorAction Stop | Out-Null
    while ($true) {
        Update-JobsProcessPath
        $winget = Find-JobsWinget
        if ($winget) { return $winget }
        Write-JobsFzfStatus '等待官方 App Installer 安装和当前用户注册；不会重复打开窗口，Ctrl+C 取消。'
        Start-Sleep -Seconds 3
    }
}
# 调用原生包管理器处理精确包，保留许可交互；原输出仅经脱敏展示，不用作选择结果。
function Invoke-JobsWingetPackage {
    param([string]$Winget, [string]$Package, [ValidateSet('install','upgrade','repair')][string]$Mode = 'install')
    $arguments = @($Mode, '--id', $Package, '--exact', '--source', 'winget', '--interactive')
    if ($Package -ceq 'junegunn.fzf') { $arguments += @('--scope', 'user') }
    $text = New-Object 'Collections.Generic.List[string]'
    $previous = $ErrorActionPreference
    $logFailure = $null
    $PSNativeCommandUseErrorActionPreference = $false
    try {
        $ErrorActionPreference = 'Continue'
        $global:LASTEXITCODE = -1
        & $Winget @arguments 2>&1 | ForEach-Object { $line = [string]$_; $text.Add($line); try { Write-JobsFzfStatus $line -ErrorAction Stop } catch { $logFailure = $_.Exception; throw } }
        $code = $LASTEXITCODE
    } finally { $ErrorActionPreference = $previous }
    if ($logFailure) { throw $logFailure }
    return [pscustomobject]@{ Code = $code; Text = $text -join "`n" }
}
# 选择流程才获取必需 fzf；健康环境直接复用，只读与取消不启动安装。
function Ensure-JobsFzf {
    param([switch]$CheckOnly)
    $fzf = Find-JobsFzf
    if ($fzf) { if (-not $CheckOnly) { Update-JobsProcessPath ([IO.Path]::GetDirectoryName($fzf)) }; return $fzf }
    if ($CheckOnly) { throw 'fzf 路径、版本或所需选项尚未就绪；只读检查未安装或修复。' }
    if ([Console]::IsInputRedirected -or [Console]::IsErrorRedirected) { throw '键盘选择需要真实交互终端；未获取依赖或执行业务。' }
    Write-JobsFzfStatus '本次键盘选择需要健康 fzf；来源 https://github.com/microsoft/winget-pkgs（junegunn.fzf）。仅在缺失或损坏时获取，许可证仍由本人确认，Ctrl+C 可结束。'
    $winget = Get-JobsRequiredWinget
    $mode = 'install'
    $existing = Get-Command 'fzf.exe', 'fzf' -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($existing) { $mode = 'repair' }
    $attempt = 0; $delay = 1
    while ($true) {
        $attempt++
        Write-JobsFzfStatus ("必需 fzf：$mode，第 $attempt 次；网络失败持续重试，不设总次数，Ctrl+C 结束。")
        $result = Invoke-JobsWingetPackage $winget 'junegunn.fzf' $mode
        if ($result.Code -in @(130, 1223, 1602, -1073741510, -2147023673)) { throw (New-Object OperationCanceledException('已取消 fzf 获取。')) }
        if ($result.Code -eq 0) {
            Update-JobsProcessPath
            $fzf = Find-JobsFzf
            if ($fzf) { Update-JobsProcessPath ([IO.Path]::GetDirectoryName($fzf)); Write-JobsFzfStatus ('fzf 已通过当前进程复检：' + $fzf); return $fzf }
            if ($mode -eq 'install') { $mode = 'repair'; Write-JobsFzfStatus '安装返回成功但选项复检失败，在同一流程尝试官方精确修复。'; continue }
            throw 'fzf 安装及官方修复后仍未通过实际选项复检；保留原错误，未进入业务。'
        }
        if ($result.Text -match '(?i)permission|access.denied|no.space|disk.full|hash|checksum|certificate|unauthor|license|agreement|unsupported|not.supported|unknown.command|unrecognized|no.applicable|not.found|权限|拒绝|空间不足|许可|协议|不支持|未知命令|无法找到|无适用') {
            $safeFailure = $result.Text -replace '\x1b\][^\x07]*(?:\x07|\x1b\\)', '' -replace '\x1b\[[0-?]*[ -/]*[@-~]', ''
            $safeFailure = $safeFailure -replace '(?i)([a-z][a-z0-9+.-]*://)[^\s/@]+@', '$1***@' -replace '(?i)(https?://[^\s?#]+)[?#][^\s]*', '$1?[已省略]'
            throw ('必需 fzf 遇到确定的权限、许可、包或版本阻塞，退出码 ' + $result.Code + '；未继续业务。' + [Environment]::NewLine + $safeFailure)
        }
        Write-JobsFzfStatus ("fzf 获取失败，退出码 $($result.Code)；$delay 秒后继续本次流程。")
        Start-Sleep -Seconds $delay
        $delay = [Math]::Min(30, $delay * 2)
    }
}
# 单选与复选使用同一键盘表面；操作行独立解析，空选不回退为高亮对象。
function Select-JobsFzfItems {
    param([string]$Title, [object[]]$Items, [switch]$Multiple, [switch]$Child, [switch]$RequireConfirmation, [hashtable]$State = $null)
    if ($Items.Count -eq 0) { return [pscustomobject]@{ Action = 'empty'; Items = @() } }
    if ($Items.Count -eq 1 -and -not $Multiple -and -not $RequireConfirmation) { return [pscustomobject]@{ Action = 'selected'; Items = @($Items[0]) } }
    if ([Console]::IsInputRedirected -or [Console]::IsOutputRedirected -or [Console]::IsErrorRedirected) { throw '键盘菜单需要完整交互终端；未安装依赖或继续业务。' }
    $environment = [Environment]::GetEnvironmentVariables('Process')
    foreach ($key in $environment.Keys) { if ([string]$key -match '^(?i:SOURCE_?TREE)') { throw 'Sourcetree 动作进程不能等待菜单；请按已声明的终端入口或明确参数执行。' } }
    $fzf = Ensure-JobsFzf
    $selected = New-Object 'Collections.Generic.HashSet[int]'
    $query = ''; $position = 1
    if ($null -ne $State) {
        if ($State.ContainsKey('Query')) { $query = [string]$State.Query }
        if ($State.ContainsKey('Position')) { $position = [Math]::Max(1, [int]$State.Position) }
        if ($State.ContainsKey('Checked')) {
            foreach ($savedIndex in @($State.Checked)) {
                if ([int]$savedIndex -ge 0 -and [int]$savedIndex -lt $Items.Count) { [void]$selected.Add([int]$savedIndex) }
            }
        }
    }
    while ($true) {
        $rows = New-Object 'Collections.Generic.List[string]'
        $rows.Add("C`t× 取消本轮")
        if ($Child) { $rows.Add("B`t← 返回上一层") }
        if ($Multiple) {
            $rows.Add("K`t确认已勾选（$($selected.Count) 项）")
            $rows.Add("A`t全选本轮全部项目")
            $rows.Add("Z`t清空已勾选")
        }
        for ($index = 0; $index -lt $Items.Count; $index++) {
            $display = ([string]$Items[$index]) -replace '[\r\n\t]', ' '
            if ($Multiple) { $display = $(if ($selected.Contains($index)) { '[✓] ' } else { '[ ] ' }) + $display }
            $rows.Add("D$index`t$display")
        }
        $navigation = if ($Child) { '← 返回上一层' } else { '← 取消' }
        $header = if ($Multiple) { "↑/↓ 或 Tab 导航；回车勾选/取消，空格确认；$navigation；操作行回车执行；Esc / Ctrl+C 取消" } else { "↑/↓ 或 Tab 导航；回车确认；$navigation；Esc / Ctrl+C 取消" }
        $position = [Math]::Min($position, $rows.Count)
        $arguments = @('--no-multi', '--sync', '--layout=reverse', '--height=60%', '--border', '--delimiter', "`t", '--with-nth=2..', '--print-query', '--expect=left,space,enter', ('--bind=up:up,down:down,tab:down,shift-tab:up,start:pos(' + $position + ')'), ('--prompt=' + $Title + ' > '), ('--header=' + $header), ('--query=' + $query))
        if ($environment.Contains('NO_COLOR') -or $env:PLAIN_OUTPUT -eq '1' -or $env:TERM -ieq 'dumb') { $arguments += @('--color=bw', '--no-bold') }
        $result = Invoke-JobsFzfProcess $fzf $arguments @($rows)
        $lines = @($result.Lines)
        $query = if ($lines.Count -gt 0) { [string]$lines[0] } else { '' }
        $key = if ($lines.Count -gt 1) { [string]$lines[1] } else { '' }
        if ($null -ne $State) { $State.Query = $query; $State.Checked = @($selected) }
        if ($key -ceq 'left') { return [pscustomobject]@{ Action = $(if ($Child) { 'back' } else { 'cancel' }); Items = @() } }
        if ($result.Code -in @(1, 130)) { return [pscustomobject]@{ Action = 'cancel'; Items = @() } }
        if ($result.Code -ne 0) { throw ('fzf 选择失败，退出码：' + $result.Code) }
        $record = if ($lines.Count -eq 3) { [string]$lines[2] } else { '' }
        if (-not $rows.Contains($record)) { throw '选择结果不属于本轮显示清单，未执行业务。' }
        $position = $rows.IndexOf($record) + 1
        if ($null -ne $State) { $State.Position = $position }
        $tag = ($record -split "`t", 2)[0]
        if ($tag -ceq 'C') { return [pscustomobject]@{ Action = 'cancel'; Items = @() } }
        if ($tag -ceq 'B') { return [pscustomobject]@{ Action = 'back'; Items = @() } }
        if ($Multiple) {
            if ($tag -ceq 'K' -or $key -ceq 'space') {
                $chosen = @()
                for ($index = 0; $index -lt $Items.Count; $index++) { if ($selected.Contains($index)) { $chosen += $Items[$index] } }
                return [pscustomobject]@{ Action = $(if ($chosen.Count) { 'selected' } else { 'empty' }); Items = $chosen }
            }
            if ($tag -ceq 'A') { for ($index = 0; $index -lt $Items.Count; $index++) { [void]$selected.Add($index) }; if ($null -ne $State) { $State.Checked = @($selected) }; continue }
            if ($tag -ceq 'Z') { $selected.Clear(); if ($null -ne $State) { $State.Checked = @() }; continue }
        }
        if ($tag -notmatch '^D([0-9]+)$') { throw '选择器返回无效操作行。' }
        $index = [int]$Matches[1]
        if (-not $Multiple) { return [pscustomobject]@{ Action = 'selected'; Items = @($Items[$index]) } }
        if ($selected.Contains($index)) { [void]$selected.Remove($index) } else { [void]$selected.Add($index) }
        if ($null -ne $State) { $State.Checked = @($selected) }
    }
}



$__jobsTerminalStyleState = $null
try {
    if ($MyInvocation.InvocationName -ne '.') {
        $__jobsTerminalStyleState = New-JobsTerminalStyleState
        Start-JobsTerminalStyle $__jobsTerminalStyleState
    }
# BEGIN JOBS_TERMINAL_STYLE_ORIGINAL_BODY
function Test-JobsEnterChoiceColor {
    param([Collections.IDictionary]$Capabilities = $null)
    if ($null -eq $Capabilities) {
        try {
            $environment = [Environment]::GetEnvironmentVariables('Process')
            $Capabilities = @{ HostName = $Host.Name; InputRedirected = [Console]::IsInputRedirected; OutputRedirected = [Console]::IsOutputRedirected;
                               ErrorRedirected = [Console]::IsErrorRedirected; NoColorPresent = $environment.Contains('NO_COLOR');
                               PlainOutput = $env:PLAIN_OUTPUT; Term = $env:TERM; Windows = ([Environment]::OSVersion.Platform -eq [PlatformID]::Win32NT); VirtualTerminal = $false; SourceTree = ($env:IS_SOURCETREE_RUNTIME -eq '1') }
            if ($null -ne $Host.UI.PSObject.Properties['SupportsVirtualTerminal']) { $Capabilities.VirtualTerminal = $Host.UI.SupportsVirtualTerminal }
            foreach ($key in $environment.Keys) { if ([string]$key -match '^(?i:SOURCE_?TREE)') { $Capabilities.SourceTree = $true; break } }
        } catch { return $false }
    }
    return ($Capabilities.HostName -eq 'ConsoleHost' -and -not $Capabilities.InputRedirected -and -not $Capabilities.OutputRedirected -and
            -not $Capabilities.ErrorRedirected -and -not $Capabilities.NoColorPresent -and $Capabilities.PlainOutput -ne '1' -and
            $Capabilities.Term -ine 'dumb' -and (-not [string]::IsNullOrEmpty($Capabilities.Term) -or ($Capabilities.Contains('Windows') -and $Capabilities.Windows)) -and -not $Capabilities.SourceTree -and $Capabilities.VirtualTerminal)
}
# Older hosts keep native colors without sending unsupported bold escape sequences.
function Test-JobsEnterChoiceBold {
    $property = $Host.UI.PSObject.Properties['SupportsVirtualTerminal']
    return ($null -ne $property -and [bool]$property.Value)
}
# Separate ordinary question text from Enter and arbitrary-input options without changing words.
function Get-JobsEnterChoiceParts {
    param([string]$Text)
    $red = '(?:(?:\u8f93\u5165)?(?:\u4efb\u610f(?:\u975e\u7a7a)?(?:\u5b57\u7b26|\u5185\u5bb9|\u6587\u5b57|\u8f93\u5165)?|\u975e\u7a7a(?:\u8f93\u5165|\u5b57\u7b26|\u5185\u5bb9)?|(?:\u5176\u5b83|\u5176\u4ed6)(?:\u975e\u7a7a)?(?:\u8f93\u5165|\u5185\u5bb9|\u5b57\u7b26)?))|(?:any\s+(?:(?:other|non[- ]empty)\s+)?(?:input|text|characters?)|non[- ]empty\s+input)|(?:type\s+(?:anything|any\s+(?:characters?|text|input)))'
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
# 仅将实际询问的主体标成青色；操作选项与分隔符分别保留自身样式。
function Get-JobsQuestionChoiceParts {
    param([string]$Text)
    $plain = [regex]::Replace($Text, '\x1b\[[0-9;]*m', '')
    $questionBody = $true
    foreach ($part in @(Get-JobsEnterChoiceParts $plain)) {
        $isOption = $part.Color -eq 'Red' -or $part.Color -eq 'Green'
        foreach ($token in [regex]::Matches($part.Text, '[^；;/|，,、？?：:=＝（）()\[\]【】\r\n]+|[；;/|，,、？?：:=＝（）()\[\]【】\r\n]')) {
            $value = $token.Value
            $separator = $value -match '^[；;/|，,、？?：:=＝（）()\[\]【】\r\n]$'
            $color = ''
            if (-not $separator -and -not [string]::IsNullOrWhiteSpace($value)) {
                if ($isOption) { $color = $part.Color }
                elseif ($questionBody) { $color = 'Cyan' }
            }
            [pscustomobject]@{ Text = $value; Color = $color }
        }
        if ($isOption) { $questionBody = $false }
    }
}
# 识别展示地址边界，保留查询、编码与配对括号。
function Get-JobsUrlRanges {
    param([string]$Text)
    $pattern = '[A-Za-z][A-Za-z0-9+.-]*://[^\s<>"''\x1b]+'
    $punctuation = '，。；：！？、（）【】《》「」『』“”‘’'
    $offset = 0
    while ($offset -lt $Text.Length) {
        $match = [regex]::Match($Text.Substring($offset), $pattern)
        if (-not $match.Success) { break }
        $start = $offset + $match.Index
        $url = $match.Value
        foreach ($mark in $punctuation.ToCharArray()) {
            $at = $url.IndexOf($mark)
            if ($at -ge 0) { $url = $url.Substring(0, $at) }
        }
        while ($url.Length) {
            $last = $url.Substring($url.Length - 1, 1)
            $unmatched = $false
            foreach ($pair in @(@('(', ')'), @('[', ']'), @('{', '}'))) {
                if ($last -eq $pair[1] -and ([regex]::Matches($url, [regex]::Escape($pair[1]))).Count -gt ([regex]::Matches($url, [regex]::Escape($pair[0]))).Count) { $unmatched = $true }
            }
            if ('. , ; : ! ?'.Split(' ') -contains $last -or $unmatched) { $url = $url.Substring(0, $url.Length - 1) }
            else { break }
        }
        [pscustomobject]@{ Start = $start; End = $start + $url.Length }
        $offset = $start + $url.Length
    }
}
# 暂时遮蔽URL，避免询问分段误识别地址内的Enter。
function Protect-JobsDisplayUrls {
    param([string]$Text)
    $builder = New-Object Text.StringBuilder
    $tokens = New-Object 'Collections.Generic.List[object]'
    $offset = 0; $number = 0
    foreach ($range in @(Get-JobsUrlRanges $Text)) {
        do { $number++; $token = [string][char]2 + 'U' + $number + [char]3 } while ($Text.Contains($token))
        [void]$builder.Append($Text.Substring($offset, $range.Start - $offset)).Append($token)
        $tokens.Add([pscustomobject]@{ Token = $token; Text = $Text.Substring($range.Start, $range.End - $range.Start) })
        $offset = $range.End
    }
    [void]$builder.Append($Text.Substring($offset))
    [pscustomobject]@{ Text = $builder.ToString(); Tokens = $tokens.ToArray() }
}
# 给可见地址标绿下划线，并恢复原SGR上下文。
function Format-JobsUrlText {
    param([AllowEmptyString()][string]$Text, [switch]$Color)
    $control = '\x1b\][^\x1b\x07]*(?:\x07|\x1b\\)|\x1b\[[0-?]*[ -/]*[@-~]'
    $sgr = '\x1b\[[0-9;:]*m'
    $value = [regex]::Replace($Text, $control, {
        param($match)
        if ($Color -and $match.Value -match ('^' + $sgr + '$')) { return $match.Value }
        return ''
    })
    if (-not $Color) { return $value }
    $styles = @{}; $visible = New-Object Text.StringBuilder; $offset = 0
    foreach ($match in [regex]::Matches($value, $sgr)) {
        [void]$visible.Append($value.Substring($offset, $match.Index - $offset))
        $index = $visible.Length
        if (-not $styles.ContainsKey($index)) { $styles[$index] = '' }
        $styles[$index] += $match.Value
        $offset = $match.Index + $match.Length
    }
    [void]$visible.Append($value.Substring($offset))
    $plain = $visible.ToString(); $starts = @{}; $ends = @{}
    foreach ($range in @(Get-JobsUrlRanges $plain)) { $starts[$range.Start] = $true; $ends[$range.End - 1] = $true }
    $escape = [string][char]27; $active = ''; $inUrl = $false; $output = New-Object Text.StringBuilder
    for ($index = 0; $index -le $plain.Length; $index++) {
        if ($styles.ContainsKey($index)) {
            $tokens = $styles[$index]; [void]$output.Append($tokens)
            foreach ($match in [regex]::Matches($tokens, $sgr)) {
                $token = $match.Value; $code = $token.Substring(2, $token.Length - 3)
                $fields = $code.Split(';'); $reset = $code -eq ''
                for ($item = 0; $item -lt $fields.Count; $item++) {
                    if ($fields[$item] -eq '0') { $reset = $true }
                    if (@('38', '48', '58') -contains $fields[$item] -and $item + 1 -lt $fields.Count) {
                        if ($fields[$item + 1] -eq '2') { $item += 4 }
                        elseif ($fields[$item + 1] -eq '5') { $item += 2 }
                    }
                }
                if ($reset) { $active = '' }
                $active += $token
            }
            if ($inUrl) { [void]$output.Append($escape + '[32;4m') }
        }
        if ($index -eq $plain.Length) { break }
        if ($starts.ContainsKey($index)) { [void]$output.Append($escape + '[32;4m'); $inUrl = $true }
        [void]$output.Append($plain[$index])
        if ($ends.ContainsKey($index)) { [void]$output.Append($escape + '[0m' + $active); $inUrl = $false }
    }
    return $output.ToString()
}
# 按现行询问规则合成展示字符串，保持输入原文。
function Format-JobsDisplayText {
    param([AllowEmptyString()][string]$Text, [switch]$Question, [switch]$Color, [string]$BaseStyle = '')
    if (-not $Color) { return (Format-JobsUrlText $Text) }
    $plain = Format-JobsUrlText $Text
    $protected = Protect-JobsDisplayUrls $plain
    $parts = if ($Question) { @(Get-JobsQuestionChoiceParts $protected.Text) } else { @(Get-JobsEnterChoiceParts $protected.Text) }
    $escape = [string][char]27
    if (-not $Question -and @($parts | Where-Object { $_.Color }).Count -eq 0) {
        $result = Format-JobsUrlText ($BaseStyle + $Text) -Color
    } else {
        $output = New-Object Text.StringBuilder
        foreach ($part in $parts) {
            $code = switch ($part.Color) { 'Red' { 31 } 'Green' { 32 } 'Cyan' { 36 } default { 0 } }
            if ($code) { [void]$output.Append($escape + '[1;' + $code + 'm' + $part.Text + $escape + '[0m' + $BaseStyle) }
            else { [void]$output.Append($BaseStyle + $part.Text) }
        }
        $formatted = $output.ToString()
        foreach ($item in $protected.Tokens) { $formatted = $formatted.Replace($item.Token, $item.Text) }
        $result = Format-JobsUrlText $formatted -Color
    }
    if ($BaseStyle) { $result += $escape + '[0m' }
    return $result
}
# 按调用者明确指定的ConsoleColor计算临时展示色。
function Get-JobsDisplayBaseStyle {
    param([Collections.IDictionary]$Parameters)
    $codes = @{ Black=30; DarkBlue=34; DarkGreen=32; DarkCyan=36; DarkRed=31; DarkMagenta=35; DarkYellow=33; Gray=37; DarkGray=90; Blue=94; Green=92; Cyan=96; Red=91; Magenta=95; Yellow=93; White=97 }
    $style = ''; $escape = [string][char]27
    if ($Parameters.ContainsKey('ForegroundColor')) { $style += $escape + '[' + $codes[[string]$Parameters.ForegroundColor] + 'm' }
    if ($Parameters.ContainsKey('BackgroundColor')) { $style += $escape + '[' + ($codes[[string]$Parameters.BackgroundColor] + 10) + 'm' }
    return $style
}
function Write-JobsEnterChoiceText {
    [CmdletBinding()]
    param([Parameter(Position=0)][AllowNull()][object]$Object, [switch]$NoNewline, [ConsoleColor]$ForegroundColor, [ConsoleColor]$BackgroundColor, [object]$Separator = ' ', [switch]$Question)
    $text = if ($Object -is [array]) { $Object -join [string]$Separator } else { [string]$Object }
    $plain = Format-JobsUrlText $text
    if (-not (Test-JobsEnterChoiceColor)) { Write-Host $plain -NoNewline:$NoNewline; return }
    $baseStyle = Get-JobsDisplayBaseStyle $PSBoundParameters
    $rendered = Format-JobsDisplayText $text -Question:$Question -Color -BaseStyle $baseStyle
    $message = New-Object Management.Automation.HostInformationMessage
    $message.Message = $plain
    $message.NoNewLine = [bool]$NoNewline
    if ($PSBoundParameters.ContainsKey('ForegroundColor')) { $message.ForegroundColor = $ForegroundColor }
    if ($PSBoundParameters.ContainsKey('BackgroundColor')) { $message.BackgroundColor = $BackgroundColor }
    Write-Information -MessageData $message -Tags 'JobsDisplay' -InformationAction SilentlyContinue
    [Console]::Write($rendered)
    if (-not $NoNewline) { [Console]::WriteLine() }
}
# Delegate the original reader, including secure input and EOF behavior, after prompt display.
function Read-JobsEnterChoiceHost {
    [CmdletBinding()]
    param([Parameter(Position=0)][string]$Prompt, [switch]$AsSecureString, [switch]$MaskInput)
    if (-not (Test-JobsEnterChoiceColor)) {
        $plainArguments = @{}
        foreach ($key in $PSBoundParameters.Keys) { $plainArguments[$key] = $PSBoundParameters[$key] }
        if ($plainArguments.ContainsKey('Prompt')) { $plainArguments.Prompt = Format-JobsUrlText $Prompt }
        return (Read-Host @plainArguments)
    }
    Write-JobsEnterChoiceText ($Prompt + ': ') -NoNewline -Question
    $readerArguments = @{}
    foreach ($key in $PSBoundParameters.Keys) {
        if ($key -ne 'Prompt') { $readerArguments[$key] = $PSBoundParameters[$key] }
    }
    return (Read-Host @readerArguments)
}

Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$script:JobsLog = $null
# 自由文本或精确安全口令由原生输入读取，EOF 与重定向立即停止。
function Read-JobsText([string]$Prompt, [string]$Default = '') {
    if ([Console]::IsInputRedirected) { throw '需要交互终端；输入重定向或 EOF 时停止。只读检查请传 -Check。' }
    $answer = Read-JobsEnterChoiceHost $Prompt
    if ($null -eq $answer) { throw '输入已结束。' }
    if ($answer -eq '' -and $Default -ne '') { return $Default }
    return $answer
}
# 独立危险门禁精确匹配 YES，不接受默认值或菜单高亮。
function Confirm-JobsChange([string]$Message) {
    if ((Read-JobsText "$Message；精确输入 YES 执行，其它输入取消") -cne 'YES') { throw '用户取消，未执行该变更。' }
}
# 展示保留样式，日志只保存去色及脱敏后的单次文本。
function Write-JobsLog([string]$Message) {
    $plain=$Message -replace '\x1b\][^\x07]*(?:\x07|\x1b\\)', '' -replace '\x1b\[[0-?]*[ -/]*[@-~]', ''
    $plain=$plain -replace '(?i)([a-z][a-z0-9+.-]*://)[^\s/@]+@', '$1***@' -replace '(?i)(https?://[^\s?#]+)[?#][^\s]*', '$1?[已省略]'
    Write-JobsEnterChoiceText $plain
    if ($script:JobsLog) { Add-Content -LiteralPath $script:JobsLog -Value $plain -Encoding UTF8 -ErrorAction Stop }
}
# 原生命令失败码和日志失败都必须阻断后续业务。
function Invoke-JobsNative([string]$Executable, [string[]]$Arguments) {
    $previous=$ErrorActionPreference; $logFailure=$null; $diagnostic=New-Object 'Collections.Generic.List[string]'; $PSNativeCommandUseErrorActionPreference=$false
    $ErrorActionPreference='Continue'; $global:LASTEXITCODE=-1
    try { & $Executable @Arguments 2>&1 | ForEach-Object { $diagnostic.Add([string]$_); try { Write-JobsLog ([string]$_) -ErrorAction Stop } catch { $logFailure=$_.Exception; throw } }; $code=$LASTEXITCODE }
    finally { $ErrorActionPreference=$previous }
    if ($logFailure) { throw $logFailure }
    if ($code -ne 0) { $failure=New-Object InvalidOperationException("$Executable 执行失败，退出码 $code");$failure.Data['JobsNativeOutput']=$diagnostic -join "`n";$failure.Data['JobsNativeCode']=$code;throw $failure }
}
# 动作表保留真实业务键；操作行由选择器解析，回车默认取消。
function Select-JobsAction {
    param([string]$Title,[Collections.IDictionary]$Actions,[switch]$Child,[hashtable]$State=$null)
    $labels=@($Actions.Values)
    $choice=Select-JobsFzfItems $Title $labels -Child:$Child -State $State -RequireConfirmation
    if($choice.Action -ceq 'back'){
        $errorValue=New-Object OperationCanceledException('返回上层菜单。');$errorValue.Data['JobsPickerAction']='back';throw $errorValue
    }
    if($choice.Action -cne 'selected'){return $null}
    foreach($key in $Actions.Keys){if([string]$Actions[$key] -ceq [string]$choice.Items[0]){return [string]$key}}
    throw '选择结果不属于当前动作表，未执行业务。'
}
# 当前流程只打开一次已安装引擎；原生许可、WSL 或重启要求由用户处理，持续复检可取消。
function Wait-JobsDockerReady {
    param([string]$Docker)
    $desktop=Join-Path $env:ProgramFiles 'Docker\Docker\Docker Desktop.exe'
    if(-not (Test-Path -LiteralPath $desktop)){throw 'Docker Desktop 安装未提供可用启动器，未继续容器操作。'}
    Start-Process -FilePath $desktop -ErrorAction Stop|Out-Null
    while($true){
        $probe=Invoke-JobsFzfProcess $Docker @('info','--format','{{.OSType}}') -Probe
    if($probe.Code -in @(130,1223,1602,-1073741510,-2147023673)){throw (New-Object OperationCanceledException('Docker 引擎检查已取消，未继续等待或容器操作。'))}
        if($probe.Code -eq 0 -and (($probe.Lines -join "`n").Trim()) -ceq 'linux'){Write-JobsLog 'Docker Linux 引擎已在当前流程就绪。';return}
        Write-JobsLog '等待 Docker Desktop Linux 引擎；若要求许可、WSL 或重启请按原生界面处理，Ctrl+C 停止等待。'
        Start-Sleep -Seconds 3
    }
}

# EXE 使用有界探针；原生批处理通过 PowerShell 调用协议执行，保留取消且不拼接命令求值。
function Test-JobsRequiredCommandHealth {
    param([string]$Executable,[string[]]$Probe)
    if([IO.Path]::GetExtension($Executable) -in @('.cmd','.bat')){
        $previous=$ErrorActionPreference;$ErrorActionPreference='Continue';$PSNativeCommandUseErrorActionPreference=$false
        try{$global:LASTEXITCODE=-1;$null=& $Executable @Probe 2>&1;$code=$LASTEXITCODE}
        catch [Management.Automation.PipelineStoppedException]{throw}
        catch{return $false}
        finally{$ErrorActionPreference=$previous}
    }else{$result=Invoke-JobsFzfProcess $Executable $Probe -Probe;$code=$result.Code}
    if($code -in @(130,1223,1602,-1073741510,-2147023673)){throw (New-Object OperationCanceledException('工具健康检查已取消，未获取或修复依赖。'))}
    return $code -eq 0
}

# 只读调用不安装；所选流程明确声明必需包时沿原流程获取、刷新并验证。
function Require-JobsCommand {
    param([string]$Name,[string]$Package='', [string[]]$Probe=@('--version'))
    Update-JobsProcessPath
    $command=Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue|Select-Object -First 1
    if ($command) { if(Test-JobsRequiredCommandHealth $command.Source $Probe){return $command.Source} }
    if (-not $Package) { throw "当前操作需要健康 $Name；只读、停止或卸载操作未自动安装或改变环境。" }
    $mode='install';if($command){$mode='repair'};$null=Install-JobsWinget $Package -Required -Mode $mode
    Update-JobsProcessPath
    $command=Get-Command $Name -CommandType Application -ErrorAction SilentlyContinue|Select-Object -First 1
    if($command){if(Test-JobsRequiredCommandHealth $command.Source $Probe){return $command.Source}}
    throw "$Package 获取后 $Name 仍未通过当前进程健康检查；未继续业务。保留安装器诊断，未要求另开终端绕过。"
}
# 按显式输入解析真实路径，逐层拒绝重解析点以防越界。
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
# 遍历自维护业务文件并跳过依赖、构建产物与链接。
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
# 变更前创建唯一副本并记录可恢复位置。
function Backup-JobsFile([string]$Path) {
    $backup = $Path + '.jobs-backup-' + [DateTime]::Now.ToString('yyyyMMdd-HHmmss-fff') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,6)
    Copy-Item -LiteralPath $Path -Destination $backup -ErrorAction Stop
    Write-JobsLog "备份：$backup"
    return $backup
}
# 严格读取 UTF-8 并保留原始 BOM，拒绝二进制或不兼容编码。
function Read-JobsUtf8([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    if ($bytes -contains 0) { throw "跳过二进制或 UTF-16 文件：$Path（仅支持严格 UTF-8）" }
    $hasBom = $bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191
    $offset = 0; if ($hasBom) { $offset = 3 }
    $utf8 = New-Object Text.UTF8Encoding($false,$true)
    return @{ Text = $utf8.GetString($bytes,$offset,$bytes.Length-$offset); Bom = $hasBom }
}
# 按已检测编码写回业务文本，避免隐式改变 BOM。
function Write-JobsUtf8([string]$Path,[string]$Text,[bool]$Bom = $false) {
    [IO.File]::WriteAllText($Path,$Text,(New-Object Text.UTF8Encoding($Bom)))
}
# 仅显式写流程创建本工具的用户状态目录。
function Get-JobsState([string]$Name) {
    $root = Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'JobsCommandOthers'
    $path = Join-Path $root $Name
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    return $path
}
# 展示获取来源及目标，避免把凭证与查询串写入日志。
function Show-JobsSource([string]$Object,[string]$Source,[string]$Destination) {
    $safe = $Source
    $uri = $null
    if ([Uri]::TryCreate($Source,[UriKind]::Absolute,[ref]$uri) -and $uri.Host) {
        $builder = New-Object UriBuilder($uri); $builder.UserName='';$builder.Password='';$builder.Query='';$builder.Fragment='';$safe=$builder.Uri.AbsoluteUri
    }
    Write-JobsLog "来源｜$Object`n来源地址：$safe`n目标位置：$Destination"
}
# 精确包仅在已选流程获取；临时网络失败持续重试，许可及确定本地错误停止。
function Install-JobsWinget {
    param([string]$Package,[switch]$Required,[ValidateSet('auto','install','upgrade','repair')][string]$Mode='auto')
    Show-JobsSource $Package 'https://github.com/microsoft/winget-pkgs' '原生 Windows 安装器；只刷新当前进程工具搜索路径'
    if(-not $Required){Confirm-JobsChange "安装 / 升级 $Package（软件许可由本人确认；不自动接受协议）"}
    $winget=Get-JobsRequiredWinget; $delay=1
    if($Mode -ceq 'auto'){
        $existing=Invoke-JobsFzfProcess $winget @('list','--id',$Package,'--exact','--source','winget') -Probe
        if($existing.Code -in @(130,1223,1602,-1073741510,-2147023673)){throw (New-Object OperationCanceledException('包状态查询已取消，未开始安装。'))}
        if($existing.Code -in @(126,127)){throw '必要包管理器无法正常执行，未开始安装。'}
        if($existing.Code -eq 0){$Mode='upgrade'}else{$Mode='install'}
    }
    while($true){
        $result=Invoke-JobsWingetPackage $winget $Package $Mode
        if($result.Code -eq 0){Update-JobsProcessPath;return $true}
        if($result.Code -in @(130,1223,1602,-1073741510,-2147023673)){throw (New-Object OperationCanceledException('已取消软件获取，未继续业务。'))}
        if($Mode -ceq 'upgrade' -and $result.Text -match '(?i)no.applicable.upgrade|no.available.upgrade|没有可用的升级|无可用升级'){Update-JobsProcessPath;return $true}
        if($result.Code -in @(126,127) -or $result.Text -match '(?i)permission|access.denied|no.space|disk.full|hash|checksum|certificate|unauthor|license|agreement|unsupported|not.supported|unknown.command|unrecognized|no.applicable|not.found|already.installed|权限|拒绝|空间不足|许可|协议|不支持|未知命令|无法找到|无适用|已安装'){
            Write-JobsLog $result.Text
            throw "精确包 $Package 遇到权限、许可或版本阻塞，退出码 $($result.Code)；未继续业务。"
        }
        Write-JobsLog "$Package 网络获取未完成，$delay 秒后在本流程重试；Ctrl+C 停止，不重复确认下载。"
        Start-Sleep -Seconds $delay; $delay=[Math]::Min(30,$delay*2)
    }
}
# 创建或启动所需引擎可在当前流程准备；查询、停止、删除只读检查既有引擎。
function Require-JobsDocker {
    param([switch]$Acquire)
    $package='';if($Acquire){$package='Docker.DockerDesktop'}
    $docker=Require-JobsCommand 'docker.exe' -Package $package
    $probe=Invoke-JobsFzfProcess $docker @('info','--format','{{.OSType}}') -Probe
    if($probe.Code -in @(130,1223,1602,-1073741510,-2147023673)){throw (New-Object OperationCanceledException('Docker 引擎检查已取消，未继续等待或容器操作。'))}
    if($probe.Code -ne 0 -or (($probe.Lines -join "`n").Trim()) -cne 'linux'){
        if(-not $Acquire){throw '当前操作需要既有 Docker Linux 引擎；未安装、启动或修改容器环境。'}
        Wait-JobsDockerReady $docker
    }
    return $docker
}
# 只读核对容器归属，拒绝操作同名第三方实例。
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
# 在有限服务启动窗口检查本机 HTTP，超时保留进程与诊断。
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
# 只接受本工具已创建并具有所有权标签的 MySQL。
function Get-JobsMySQLInfo([string]$Docker) {
    $item=Get-JobsContainer $Docker 'jobs-sh-mysql' 'JobsSh.MySQL'
    if(!$item){throw '本入口 MySQL 尚未创建，先运行 MySQL 管理工具。'}
    return $item
}
# 检查实际 MySQL ping 就绪状态，超时保留原容器供排查。
function Wait-JobsMySQL([string]$Docker) {
    $deadline=[DateTime]::UtcNow.AddSeconds(90)
    while([DateTime]::UtcNow -lt $deadline){
        $null=& $Docker exec jobs-sh-mysql mysqladmin ping --silent 2>$null
        if($LASTEXITCODE -eq 0){Write-JobsLog 'MySQL 已响应 ping；认证需要使用登录操作另验。';return}
        Start-Sleep -Seconds 1
    };throw 'MySQL 在 90 秒内未就绪，请查看容器日志。'
}
# 创建隔离持久卷与回环服务，密码仅通过进程环境短暂传入。
function New-JobsMySQL([string]$Docker,[string]$Volume,[switch]$EmptyPassword) {
    $state=Get-JobsShState 'MySQL';$config=Join-Path $state 'my.cnf'
    if(!(Test-Path -LiteralPath $config)){Write-JobsUtf8 $config "[mysqld]`ncharacter-set-server=utf8mb4`n"}
    if($config.Contains(',')){throw 'Docker配置目录不能含逗号。'}
    $image='mysql:8.4';Show-JobsSource 'MySQL 8.4 官方镜像' 'https://hub.docker.com/_/mysql' "$Volume → /var/lib/mysql；127.0.0.1:3306"
    $args=@('run','-d','--name','jobs-sh-mysql','--label','jobs.owner=JobsSh.MySQL','-p','127.0.0.1:3306:3306','--mount',"type=volume,source=$Volume,target=/var/lib/mysql",'--mount',"type=bind,source=$config,target=/etc/mysql/conf.d/jobs.cnf,readonly")
    if($EmptyPassword){$args+=@('-e','MYSQL_ALLOW_EMPTY_PASSWORD=yes');Invoke-JobsNative $Docker ($args+@($image));return}
    $secret=Read-JobsEnterChoiceHost '设置新 MySQL root 密码（不会写入日志）' -AsSecureString
    if($secret.Length -lt 8){throw '密码至少 8 字符。'}
    $pointer=[Runtime.InteropServices.Marshal]::SecureStringToBSTR($secret);$previous=$env:MYSQL_ROOT_PASSWORD
    try{$env:MYSQL_ROOT_PASSWORD=[Runtime.InteropServices.Marshal]::PtrToStringBSTR($pointer);$args+=@('-e','MYSQL_ROOT_PASSWORD');Invoke-JobsNative $Docker ($args+@($image))}
    finally{$env:MYSQL_ROOT_PASSWORD=$previous;[Runtime.InteropServices.Marshal]::ZeroFreeBSTR($pointer);$secret.Dispose()}
}
# 先选择动作，创建与启动才准备依赖，查询及删除不自愈。
function Invoke-JobsMySQL {
    $action=Select-JobsAction 'MySQL 管理（默认取消）' ([ordered]@{install='安装专属 MySQL';start='启动';stop='停止';status='查看状态';login='登录';logs='查看日志'})
    if(-not $action){return}
    $docker=Require-JobsDocker -Acquire:($action -in @('install','start'));$item=Get-JobsContainer $docker 'jobs-sh-mysql' 'JobsSh.MySQL'
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
# 先验证新配置再备份应用，失败按原运行状态恢复。
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
# 保留旧容器与卷，显式确认后另建测试实例并支持失败回滚。
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
# 删除自有容器保留数据，卷删除另需完整卷名和 YES。
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
# 先形成工程计划，确认后创建源码，下载与运行保留独立门禁。
function Invoke-JobsGoProject {
    $action=Select-JobsAction 'Go 工具（默认取消）' ([ordered]@{create='创建 Gin 工程';install='安装 / 升级 Go 并验证'})
    if(-not $action){return}
    if($action -ceq 'install'){$null=Install-JobsWinget 'GoLang.Go';$go=Require-JobsCommand 'go.exe' -Probe @('version');Invoke-JobsNative $go @('version');return}
    $go=Require-JobsCommand 'go.exe' -Package 'GoLang.Go' -Probe @('version');Invoke-JobsNative $go @('version');$parent=Get-JobsPath '选择工程父目录' -Directory;$name=Read-JobsText '工程目录名'
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
# 只转换首层 HEIC，保留原图与既有目标并逐项记录失败。
function Invoke-JobsHEIC {
    $action=Select-JobsAction 'HEIC 图片工具（默认取消）' ([ordered]@{convert='转换 HEIC 图片';install='安装 / 升级 ImageMagick 并验证'})
    if(-not $action){return}
    if($action -ceq 'install'){$null=Install-JobsWinget 'ImageMagick.ImageMagick';$magick=Require-JobsCommand 'magick.exe' -Probe @('-version');Invoke-JobsNative $magick @('-version');return}
    $magick=Require-JobsCommand 'magick.exe' -Package 'ImageMagick.ImageMagick' -Probe @('-version');$root=Get-JobsPath '选择 HEIC 输入目录（仅第一层）' -Directory;$output=Join-Path $root 'JPEG';$files=@(Get-ChildItem -LiteralPath $root -File|Where-Object{$_.Extension -ieq '.heic'})
    if($files.Count -eq 0){Write-JobsLog '没有 HEIC 文件。';return}
    Confirm-JobsChange "将 $($files.Count) 张 HEIC 转为 $output 下 JPEG；已有目标跳过";New-Item -ItemType Directory -Path $output -Force|Out-Null;$failed=0
    foreach($file in $files){$target=Join-Path $output ($file.BaseName+'.jpg');if(Test-Path -LiteralPath $target){Write-JobsLog "已存在，跳过：$target";continue};$stage=Join-Path $output ([Guid]::NewGuid().ToString('N')+'.jpg')
        try{Invoke-JobsNative $magick @($file.FullName,'-auto-orient','-quality','92',$stage);Move-Item -LiteralPath $stage -Destination $target;Write-JobsLog "已转换：$target"}catch{$failed++;Write-JobsLog "失败：$($file.FullName)"}finally{if(Test-Path -LiteralPath $stage){Remove-Item -LiteralPath $stage}}
    };if($failed){throw "$failed 张转换失败。"}
}
# 检查不写状态，配置前精确备份用户变量并保护恢复前提。
function Invoke-JobsJava {
    $action=Select-JobsAction 'Java 环境（默认取消）' ([ordered]@{check='只读检查';install='安装 / 升级 JDK 并验证';configure='配置用户环境';restore='恢复用户环境'})
    if(-not $action){return}
    $state=Join-Path (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'JobsSh') 'Java';$backup=Join-Path $state 'environment.json'
    switch($action){
        'install'{$null=Install-JobsWinget 'EclipseAdoptium.Temurin.21.JDK';$java=Require-JobsCommand 'java.exe' -Probe @('-version');$javac=Require-JobsCommand 'javac.exe' -Probe @('-version');Invoke-JobsNative $java @('-version');Invoke-JobsNative $javac @('-version')}
        'check'{$java=Require-JobsCommand 'java.exe' -Probe @('-version');$javac=Require-JobsCommand 'javac.exe' -Probe @('-version');Invoke-JobsNative $java @('-version');Invoke-JobsNative $javac @('-version');Write-JobsLog "JAVA_HOME：$env:JAVA_HOME"}
        'configure'{
            $root=Get-JobsPath '选择 JDK 根目录（含 bin/java.exe 与 bin/javac.exe）' -Directory
            foreach($tool in @('java.exe','javac.exe')){if(!(Test-Path -LiteralPath (Join-Path $root "bin\$tool"))){throw "JDK 缺少 $tool"}}
            Invoke-JobsNative (Join-Path $root 'bin\java.exe') @('-version');Confirm-JobsChange "设置当前用户 JAVA_HOME 为 $root；备份用户变量，不修改系统变量"
            if(Test-Path -LiteralPath $backup){throw "已有未恢复备份：$backup；先 restore 或人工归档。"}
            $oldHome=[Environment]::GetEnvironmentVariable('JAVA_HOME','User');$oldPath=[Environment]::GetEnvironmentVariable('Path','User');$newPath=(Join-Path $root 'bin')+';'+$oldPath
            $null=Get-JobsShState 'Java';@{OldHome=$oldHome;OldPath=$oldPath;NewHome=$root;NewPath=$newPath}|ConvertTo-Json|Set-Content -LiteralPath $backup -Encoding UTF8
            [Environment]::SetEnvironmentVariable('JAVA_HOME',$root,'User');[Environment]::SetEnvironmentVariable('Path',$newPath,'User');$env:JAVA_HOME=$root;$env:Path=(Join-Path $root 'bin')+';'+$env:Path;Write-JobsLog "备份：$backup；当前进程已刷新，新终端继承用户配置。"
        }
        'restore'{
            $r=Get-Content -LiteralPath $backup -Raw|ConvertFrom-Json
            if([Environment]::GetEnvironmentVariable('JAVA_HOME','User') -cne $r.NewHome -or [Environment]::GetEnvironmentVariable('Path','User') -cne $r.NewPath){throw '环境已被后续修改，拒绝覆盖，请按备份人工合并。'}
            Confirm-JobsChange '恢复本工具修改前用户 JAVA_HOME 与 Path';$env:JAVA_HOME=$r.OldHome;[Environment]::SetEnvironmentVariable('JAVA_HOME',$r.OldHome,'User');[Environment]::SetEnvironmentVariable('Path',$r.OldPath,'User');$env:Path=$r.OldPath+';'+[Environment]::GetEnvironmentVariable('Path','Machine');Remove-Item -LiteralPath $backup
        }
        default{throw '未知动作。'}
    }
}
# 先选动作，创建才获取运行依赖，容器必须属于本工具。
function Invoke-JobsWebContainer([string]$Kind) {
    $action=Select-JobsAction ($Kind+' 容器（默认取消）') ([ordered]@{install='安装容器';start='启动';stop='停止';status='查看状态';logs='查看日志';remove='删除容器'})
    if(-not $action){return}
    $docker=Require-JobsDocker -Acquire:($action -in @('install','start'))
    if($Kind -eq 'PhpApache'){$name='jobs-sh-php-apache';$image='php:8.4-apache';$containerRoot='/var/www/html';$port=8082;$containerPort=80;$source='https://hub.docker.com/_/php'}else{$name='jobs-sh-tomcat';$image='tomcat:10.1-jdk21-temurin';$containerRoot='/usr/local/tomcat/webapps';$port=8083;$containerPort=8080;$source='https://hub.docker.com/_/tomcat'}
    $owner='JobsSh.'+$Kind;$item=Get-JobsContainer $docker $name $owner
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
# 明确选择下载流程后准备必要模块，下载前核对授权 URL 与目标。
# 下载流程缺失模块时持续重试临时网络故障，安装成功后验证同一个 Python 的实际模块。
function Ensure-JobsYouGet {
    param([string]$Python,[switch]$Upgrade)
    $probe=Invoke-JobsFzfProcess $Python @('-m','you_get','--version') -Probe
    if($probe.Code -eq 0 -and -not $Upgrade){return}
    Show-JobsSource 'you-get' 'https://pypi.org/project/you-get/' '当前用户 Python site-packages'
    $arguments=@('-m','pip','install','--user','you-get');if($Upgrade){$arguments+=@('--upgrade')};$delay=1
    while($true){
        try{Invoke-JobsNative $Python $arguments;break}catch{
            $code=$_.Exception.Data['JobsNativeCode'];$diagnostic=[string]$_.Exception.Data['JobsNativeOutput']
            if($code -in @(130,1223,1602,-1073741510,-2147023673)){throw}
            if(-not $code -or $diagnostic -notmatch '(?i)connection|timed?.out|timeout|network|temporary.failure|name.resolution|retrying|网络|连接|超时|暂时') {throw}
            if($diagnostic -match '(?i)permission|access.denied|no.space|disk.full|hash|checksum|certificate|unauthor|license|agreement|unsupported|not.supported|no.matching.distribution|权限|拒绝|空间不足|许可|协议|不支持'){throw}
            Write-JobsLog "you-get 网络获取未完成，$delay 秒后重试；Ctrl+C 停止。";Start-Sleep -Seconds $delay;$delay=[Math]::Min(30,$delay*2)
        }
    }
    $probe=Invoke-JobsFzfProcess $Python @('-m','you_get','--version') -Probe
    if($probe.Code -ne 0){throw 'you-get 获取后未通过当前 Python 模块健康检查，未下载媒体。'}
}

# 先选动作；只有已选下载或模块安装流程才准备当前 Python 必需依赖。
function Invoke-JobsVideo {
    $action=Select-JobsAction '视频工具（默认取消）' ([ordered]@{download='下载已授权媒体';install='安装 / 升级 you-get'})
    if(-not $action){return}
    $python=Require-JobsCommand 'python.exe' -Package 'Python.Python.3.13'
    if($action -ceq 'install'){Confirm-JobsChange 'pip --user 安装或升级 you-get';Ensure-JobsYouGet $python -Upgrade;return}
    Ensure-JobsYouGet $python
    $url=Read-JobsText '输入有权下载的 HTTP / HTTPS 视频页面 URL';$uri=$null
    if(-not [Uri]::TryCreate($url,[UriKind]::Absolute,[ref]$uri) -or $uri.Scheme -notin @('http','https')){throw '只接受 HTTP / HTTPS URL。'}
    $output=Get-JobsPath '选择输出目录' -Directory;Show-JobsSource '视频' $url $output;Confirm-JobsChange '下载媒体至指定目录（可能联网；仅处理你有权下载的内容）'
    Invoke-JobsNative $python @('-m','you_get','--output-dir',$output,'--',$url)
}
# 可枚举动作和来源均用键盘选择，返回保留父菜单查询。
function Invoke-JobsGem {
    $state=@{};while($true){
    $action=Select-JobsAction 'RubyGems（默认取消）' ([ordered]@{status='只读检查';source='配置软件源';update='升级 RubyGems 和 Gem';cleanup='清理旧 Gem'}) -State $state
    if(-not $action){return}
    if($action -ceq 'source'){
        try{$choice=Select-JobsAction '选择 Gem 软件源' ([ordered]@{official='官方源';china='Ruby China'}) -Child}catch [OperationCanceledException]{if($_.Exception.Data['JobsPickerAction'] -ceq 'back'){continue};throw}
        if(-not $choice){return}
    }
    break
    }
    if($action -in @('source','update')){
        $existing=Get-Command 'gem.cmd' -CommandType Application -ErrorAction SilentlyContinue|Select-Object -First 1
        if(-not $existing -or -not (Test-JobsRequiredCommandHealth $existing.Source @('--version'))){Invoke-JobsRuby -Required}
    }
    $gem=Require-JobsCommand 'gem.cmd';Invoke-JobsNative $gem @('--version');Invoke-JobsNative $gem @('sources','--list')
    switch($action){
        'status'{Invoke-JobsNative $gem @('environment')}
        'source'{
            if($choice -eq 'official'){$url='https://rubygems.org/'}elseif($choice -eq 'china'){$url='https://gems.ruby-china.com/'}else{throw '无效软件源。'}
            $config=Join-Path $env:USERPROFILE '.gemrc';Confirm-JobsChange "备份用户 Gem 配置并将软件源设置为 $url";if(Test-Path -LiteralPath $config){$null=Backup-JobsFile $config}
            $old=@(& $gem sources --list|Where-Object{$_ -match '^https?://'})
            foreach($source in $old){Invoke-JobsNative $gem @('sources','--remove',$source)};Show-JobsSource 'Gem source' $url $config;Invoke-JobsNative $gem @('sources','--add',$url)
        }
        'update'{Confirm-JobsChange '升级当前 Ruby 环境的 RubyGems 与全部 Gem（原生扩展需要 RubyInstaller DevKit）';Invoke-JobsNative $gem @('update','--system');Invoke-JobsNative $gem @('update')}
        'cleanup'{Confirm-JobsChange '清理当前 Ruby 环境旧版 Gem';Invoke-JobsNative $gem @('cleanup')}
        default{throw '未知动作。'}
    }
}
# 实际目录搜索结果形成版本候选，返回只重选版本，不让用户复制易错包 ID。
function Invoke-JobsRuby {
    param([switch]$Required)
    $state=@{}
    while($true){
        $action=Select-JobsAction 'RubyInstaller（默认取消）' ([ordered]@{install='选择并安装 RubyInstaller 版本'}) -State $state
        if(-not $action){if($Required){throw (New-Object OperationCanceledException('必要 Ruby 版本选择已取消，未继续 Gem 写操作。'))};return}
        $winget=Get-JobsRequiredWinget
        $result=Invoke-JobsFzfProcess $winget @('search','RubyInstaller','--source','winget') -Probe
        if($result.Code -ne 0){Write-JobsLog (($result.Lines -join "`n")+"`n"+$result.Error);throw 'RubyInstaller 官方目录查询失败，未安装软件。'}
        $ids=@([regex]::Matches(($result.Lines -join "`n"),'RubyInstallerTeam\.Ruby(?:WithDevKit)?\.[0-9.]+')|ForEach-Object{$_.Value}|Select-Object -Unique)
        if($ids.Count -eq 0){throw '官方目录没有可核对的 RubyInstallerTeam 版本，未安装未知软件。'}
        $choice=Select-JobsFzfItems '选择明确 RubyInstaller 版本' $ids -Child -RequireConfirmation
        if($choice.Action -ceq 'back'){continue};if($choice.Action -cne 'selected'){if($Required){throw (New-Object OperationCanceledException('必要 Ruby 版本选择已取消，未继续 Gem 写操作。'))};return}
        $null=Install-JobsWinget ([string]$choice.Items[0])
        $ruby=Require-JobsCommand 'ruby.exe' -Probe @('-v');$gem=Require-JobsCommand 'gem.cmd'
        Invoke-JobsNative $ruby @('-v');Invoke-JobsNative $gem @('--version');return
    }
}
# 并发哈希校验后备份追加唯一文本，不自动提权。
function Invoke-JobsAppendProtected {
    $path=Get-JobsPath '输入唯一目标文本文件（受保护路径需自行用管理员终端启动）';$doc=Read-JobsUtf8 $path;$hash=(Get-FileHash -LiteralPath $path).Hash;$line=Read-JobsText '输入追加一行（内容不写日志）'
    if([string]::IsNullOrWhiteSpace($line)){throw '内容不能为空。'}
    Confirm-JobsChange "备份后向 $path 追加一行（保留 UTF-8 BOM 与原文）";$backup=Backup-JobsFile $path
    if((Get-FileHash -LiteralPath $path).Hash -ne $hash){throw '文件有并发修改，停止。'}
    $separator='';if($doc.Text -and !$doc.Text.EndsWith("`n")){$separator="`r`n"};Write-JobsUtf8 $path ($doc.Text+$separator+$line+"`r`n") $doc.Bom
    Write-JobsLog "已写入；恢复备份：$backup"
}
# 备份当前用户选项后设置扩展名显示，不改真实文件名。
function Invoke-JobsExtensions {
    $key='HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced';$current=Get-ItemProperty -LiteralPath $key -Name HideFileExt
    Write-JobsLog "当前 HideFileExt：$($current.HideFileExt)；Windows 按当前用户全局控制扩展名显示，没有 Finder 的逐文件开关。"
    $mode=Select-JobsAction '资源管理器扩展名（默认取消）' ([ordered]@{hide='隐藏已知扩展名';show='显示已知扩展名'});if(-not $mode){return}
    Confirm-JobsChange "设置当前用户资源管理器扩展名显示 $mode（范围为全部文件夹；保留真实文件名）"
    $state=Get-JobsShState 'Explorer';@{HideFileExt=$current.HideFileExt}|ConvertTo-Json|Set-Content -LiteralPath (Join-Path $state ('extensions-'+[DateTime]::Now.ToString('yyyyMMddHHmmss')+'.json')) -Encoding UTF8
    $value=1;if($mode -eq 'show'){$value=0};Set-ItemProperty -LiteralPath $key -Name HideFileExt -Value $value
    Write-JobsLog '设置已写入；关闭并重新打开资源管理器窗口后查看。恢复时运行本入口选择原状态。'
}
# 检查不修复；已选安装或打开在当前流程等待并验证实际 Linux 引擎。
function Invoke-JobsDockerSetup {
    $action=Select-JobsAction 'Docker Desktop（默认取消）' ([ordered]@{check='只读检查 CLI 与引擎';install='安装 / 升级并验证';open='打开并等待引擎'})
    if(-not $action){return}
    switch($action){
        'install'{$null=Install-JobsWinget 'Docker.DockerDesktop';$docker=Require-JobsCommand 'docker.exe';Wait-JobsDockerReady $docker}
        'open'{$docker=Require-JobsCommand 'docker.exe';Confirm-JobsChange '打开 Docker Desktop 并等待 Linux 引擎';Wait-JobsDockerReady $docker}
        'check'{$docker=Require-JobsCommand 'docker.exe';Invoke-JobsNative $docker @('--version');Invoke-JobsNative $docker @('version');Invoke-JobsNative $docker @('info');Write-JobsLog 'CLI 与引擎均已响应。'}
    }
}
# 入口先自述确认，检查模式只读，业务模式建立独立日志并分发。
function Invoke-JobsShTool([string]$Tool,[switch]$Check) {
    $script:JobsLog=$null
    $summary=@{'MySQL'='安装/管理专属 MySQL8.4 Docker容器；只回环3306，数据卷持久保留。';'MySQLConfig'='隔离验证并备份应用 MySQL配置，按原服务状态重启；失败恢复。';'MySQLReset'='保留旧容器与数据，另建全新空密码 MySQL，仅供本机测试并实连验证。';'MySQLRemove'='卸载本工具MySQL容器，默认保留数据；独立二次确认才删除明确数据卷。';'GoProject'='可选安装Go，创建新的Gin工程；依赖下载、测试、运行分别确认。';'HEIC2Jpg'='可选安装ImageMagick，将第一层HEIC转到JPEG目录，保留原图和既有目标。';'Java'='检查/安装Java；备份后配置或精确恢复当前用户JAVA_HOME和Path。';'PhpApache'='安装/管理PHP与Apache官方容器；只读挂载网站目录，回环8082。';'Tomcat'='安装/管理Tomcat官方容器；复制部署文件到持久卷，回环8083，保留源文件。';'VideoDownload'='安装you-get或下载本人有权使用的网页视频至所选目录，显示脱敏来源。';'Gem'='检查RubyGems，选择备份修改软件源、升级或清理旧Gem。';'Ruby'='从winget目录选择明确RubyInstaller版本并安装/升级，不覆盖未知管理器。';'AppendProtected'='备份后向选定普通UTF-8文件追加一行，权限不足停止，不自动提权。';'FileExtensions'='经明确确认设置当前用户全部Explorer窗口扩展名显示，保留真实文件名。';'Docker'='检查CLI与引擎、可选安装/升级并打开Docker Desktop，不自动修改WSL/系统功能。'}
    Write-JobsEnterChoiceText ("Jobs Windows｜$Tool`n用途与影响："+$summary[$Tool]+"`n确认后显示实际日志位置；Ctrl+C 取消，危险变更精确 YES。")
    if($Check){
        $dependencies=@{MySQL=@('docker.exe');MySQLConfig=@('docker.exe');MySQLReset=@('docker.exe');MySQLRemove=@('docker.exe');GoProject=@('go.exe');HEIC2Jpg=@('magick.exe');Java=@('java.exe','javac.exe');PhpApache=@('docker.exe');Tomcat=@('docker.exe');VideoDownload=@('python.exe');Gem=@('ruby.exe','gem.cmd');Ruby=@('winget.exe');Docker=@('docker.exe')}
        Write-JobsEnterChoiceText '只读检查：入口与模块加载成功；只查询命令是否存在，不启动或写业务文件。'
        if($dependencies.ContainsKey($Tool)){foreach($name in $dependencies[$Tool]){$found=Get-Command $name -ErrorAction SilentlyContinue;Write-JobsEnterChoiceText ($name+': '+$(if($found){'已发现'}else{'未发现'}))}}
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

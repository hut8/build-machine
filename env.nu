# Nushell Environment Config File
# Environment variables ported from .zshrc / .zshenv / .zprofile

# Locale
$env.LANG = 'en_US.UTF-8'
$env.LANGUAGE = 'en_US.UTF-8'

# Rust
$env.RUST_BACKTRACE = '1'

# Editors
$env.EDITOR = 'hx'
$env.VISUAL = 'hx'
$env.PAGER = 'less'

# Less options (from zprofile)
$env.LESS = '-g -i -M -R -S -w -X -z-4'

# Dotnet
$env.DOTNET_CLI_TELEMETRY_OPTOUT = '1'
$env.DOTNET_WATCH_RESTART_ON_RUDE_EDIT = 'true'

# Fly.io
$env.FLYCTL_INSTALL = ($env.HOME | path join '.fly')

# Bun
$env.BUN_INSTALL = ($env.HOME | path join '.bun')

# Android
$env.ANDROID_HOME = ($env.HOME | path join 'Android' 'Sdk')
$env.ANDROID_SDK_ROOT = $env.ANDROID_HOME

# Mise
$env.MISE_PYTHON_VENV_AUTO_CREATE = '1'

# Specifies how environment variables are:
# - converted from a string to a value on Nushell startup (from_string)
# - converted from a value back to a string when running external commands (to_string)
$env.ENV_CONVERSIONS = {
    "PATH": {
        from_string: { |s| $s | split row (char esep) | path expand -n }
        to_string: { |v| $v | path expand -n | str join (char esep) }
    }
    "Path": {
        from_string: { |s| $s | split row (char esep) | path expand -n }
        to_string: { |v| $v | path expand -n | str join (char esep) }
    }
}

# Directories to search for scripts when calling source or use
$env.NU_LIB_DIRS = [
    ($nu.default-config-dir | path join 'scripts')
]

# Directories to search for plugin binaries when calling register
$env.NU_PLUGIN_DIRS = [
    ($nu.default-config-dir | path join 'plugins')
]

# PATH
# Directories are prepended in reverse priority order (last prepend = highest priority)
$env.PATH = ($env.PATH | split row (char esep)
    | prepend ($env.HOME | path join '.kilo' 'bin')
    | prepend ($env.HOME | path join '.opencode' 'bin')
    | prepend ($env.HOME | path join '.bun' 'bin')
    | prepend ($env.HOME | path join '.fly' 'bin')
    | prepend ($env.HOME | path join '.config' 'emacs' 'bin')
    | prepend ($env.HOME | path join '.dotnet' 'tools')
    | prepend ($env.HOME | path join '.local' 'bin')
    | prepend ($env.HOME | path join '.cargo' 'bin')
    | prepend ($env.HOME | path join 'go' 'bin')
    | prepend '/usr/local/go/bin'
    | uniq
)

# Conditionally add Android SDK paths if the directory exists
if ($env.ANDROID_HOME | path exists) {
    $env.PATH = ($env.PATH
        | prepend ($env.ANDROID_HOME | path join 'emulator')
        | prepend ($env.ANDROID_HOME | path join 'platform-tools')
    )
}

# sccache for Rust
if not (which sccache | is-empty) {
    $env.RUSTC_WRAPPER = 'sccache'
    $env.SCCACHE_CACHE_SIZE = '50G'
}

# Starship prompt initialization
# Generates the starship init script so config.nu can source it
mkdir ($env.HOME | path join '.cache' 'starship')
if not (which starship | is-empty) {
    starship init nu | save -f ($env.HOME | path join '.cache' 'starship' 'init.nu')
} else {
    '' | save -f ($env.HOME | path join '.cache' 'starship' 'init.nu')
}

# Mise (runtime version manager) initialization
mkdir ($env.HOME | path join '.cache' 'mise')
if not (which mise | is-empty) {
    mise activate nu | save -f ($env.HOME | path join '.cache' 'mise' 'init.nu')
} else {
    '' | save -f ($env.HOME | path join '.cache' 'mise' 'init.nu')
}

#!/usr/bin/env nu
# curl -sSL https://raw.githubusercontent.com/hut8/build-machine/master/build-account.nu | nu
# Nushell port of build-account

mut failed_installs: list<string> = []

if (^id -u | str trim) == "0" {
    print "do not run this as root!"
    exit 1
}

cd $env.HOME

let home = $env.HOME
let build_machine = ($home | path join "build-machine")

# Git configuration
git config --global pull.rebase false
git config --global --add push.default current
git config --global --add --bool push.autoSetupRemote true
git config --global branch.autoSetupMerge true
git config --global user.name "Liam Bowen"
git config --global user.email "liam@supervillains.io"
git config --global init.defaultBranch main

if not ($build_machine | path exists) {
    git clone https://github.com/hut8/build-machine $build_machine
    cd $build_machine
    git remote set-url origin "git@github.com:hut8/build-machine"
    cd $home
} else {
    cd $build_machine
    git pull
    cd $home
}

# SSH setup
let ssh_dir = ($home | path join ".ssh")
mkdir $ssh_dir
http get https://github.com/hut8.keys | save -f ($ssh_dir | path join "authorized_keys")
^chmod 0600 ($ssh_dir | path join "authorized_keys")

# Fix SSH Agent Forwarding in tmux
let ssh_rc = ($ssh_dir | path join "rc")
if not ($ssh_rc | path exists) {
    print "Fixing SSH Agent Forwarding in tmux"
    ^ln -f ($build_machine | path join "sshrc") $ssh_rc
    ^chmod +x $ssh_rc
}

# Prezto
let zprezto = ($home | path join ".zprezto")
if not ($zprezto | path exists) {
    print "installing prezto"
    git clone --recursive https://github.com/hut8/prezto.git $zprezto

    let runcoms_dir = ($zprezto | path join "runcoms")
    for rcfile in (ls $runcoms_dir | where type == "file" | where { |it| ($it.name | path basename) != "README.md" } | get name) {
        let target = ($home | path join $".($rcfile | path basename)")
        rm -f $target
        ^ln -s $rcfile $target
    }
}

# Go
$env.PATH = ($env.PATH | prepend "/usr/local/go/bin")

let go_packages = [
    "golang.org/x/tools/gopls"
    "honnef.co/go/tools/cmd/staticcheck"
    "github.com/google/gops"
    "github.com/karol-broda/snitch"
    "github.com/clawscli/claws/cmd/claws"
    "github.com/chmouel/lazyworktree/cmd/lazyworktree"
    "github.com/surge-downloader/surge"
    "github.com/legostin/cull"
    "github.com/ramonvermeulen/whosthere"
    "github.com/edoardottt/cariddi/cmd/cariddi"
    "github.com/jbreckmckye/daylight"
    "github.com/pashkov256/deletor"
    "github.com/zyedidia/eget"
    "github.com/dundee/gdu"
    "github.com/wader/fq"
    "github.com/termkit/gama"
    "github.com/IAL32/az-tui/cmd/az-tui"
    "github.com/Oloruntobi1/pproftui"
    "github.com/alajmo/mani"
    "github.com/hymkor/csvi/cmd/csvi"
    "github.com/brandonyoungdev/tldx"
]

if (which go | is-not-empty) {
    for pkg in $go_packages {
        let desc = $"go install ($pkg)@latest"
        let r = (do -i { ^go install $"($pkg)@latest" } | complete)
        if $r.exit_code != 0 { $failed_installs = ($failed_installs | append $desc) }
    }
}

# Rust
let cargo_dir = ($home | path join ".cargo")
if not ($cargo_dir | path exists) {
    print "installing rust"
    ^curl -sSf "https://sh.rustup.rs" | ^sh -s -- -y
    $env.PATH = ($env.PATH | prepend ($cargo_dir | path join "bin"))
    ^rustup component add rust-src
}

# Ensure cargo/bin is in PATH
if ($cargo_dir | path exists) {
    $env.PATH = ($env.PATH | prepend ($cargo_dir | path join "bin"))
}

# Mise
let mise_config_dir = ($home | path join ".config" "mise")
mkdir $mise_config_dir
^ln -f ($build_machine | path join "mise.toml") ($mise_config_dir | path join "config.toml")

if (which mise | is-empty) {
    let r = (do -i { ^eget --to ($home | path join ".local" "bin") jdx/mise } | complete)
    if $r.exit_code != 0 {
        $failed_installs = ($failed_installs | append "eget --to ~/.local/bin jdx/mise")
    } else {
        do -i { ^mise install } | complete
    }
}

# Starship prompt
if (which starship | is-empty) {
    let r = (do -i { ^eget --to ($home | path join ".local" "bin") --asset gnu starship/starship } | complete)
    if $r.exit_code != 0 { $failed_installs = ($failed_installs | append "eget --to ~/.local/bin starship/starship") }
}

# Helix config
let helix_config_dir = ($home | path join ".config" "helix")
mkdir $helix_config_dir
print "linking helix config"
^ln -f ($build_machine | path join "helix-config.toml") ($helix_config_dir | path join "config.toml")

# Nushell config
let nushell_config_dir = ($home | path join ".config" "nushell")
mkdir $nushell_config_dir
for f in ["config.nu", "env.nu"] {
    print $"linking nushell config: ($f)"
    ^ln -f ($build_machine | path join $f) ($nushell_config_dir | path join $f)
}

# Register nushell plugins (installed to /usr/local/bin by build-machine-debian)
let nu_plugins = (glob "/usr/local/bin/nu_plugin_*")
if ($nu_plugins | is-not-empty) {
    for plugin in $nu_plugins {
        let r = (do -i { ^nu --plugin-add $plugin } | complete)
        if $r.exit_code != 0 { $failed_installs = ($failed_installs | append $"nu --plugin-add ($plugin)") }
    }
}

# Starship config
print "linking starship config"
^ln -f ($build_machine | path join "starship.toml") ($home | path join ".config" "starship.toml")

# Create cache dirs for nushell init scripts (generated at shell startup)
let starship_cache = ($home | path join ".cache" "starship")
let mise_cache = ($home | path join ".cache" "mise")
mkdir $starship_cache $mise_cache
touch ($starship_cache | path join "init.nu")
touch ($mise_cache | path join "init.nu")

# Various config files to be hardlinked
for f in [".sqliterc", ".tmux.conf", ".pryrc", ".p10k.zsh"] {
    print $"linking dotfile: ($f)"
    ^ln -f ($build_machine | path join $f) ($home | path join $f)
}

# Python tools via pipx
for tool in ["litecli", "pgcli"] {
    let r = (do -i { ^pipx install $tool } | complete)
    if $r.exit_code != 0 { $failed_installs = ($failed_installs | append $"pipx install ($tool)") }
}
if (which mysql | is-not-empty) {
    let r = (do -i { ^pipx install mycli } | complete)
    if $r.exit_code != 0 { $failed_installs = ($failed_installs | append "pipx install mycli") }
}

# Fly.io
if (which fly | is-empty) {
    let r = (do -i { ^curl -L https://fly.io/install.sh | ^sh } | complete)
    if $r.exit_code != 0 { $failed_installs = ($failed_installs | append "curl -L https://fly.io/install.sh | sh") }
}

# Cargo crates
let cargo_crates = ["hexhog", "rustormy", "systemd-manager-tui", "mcat"]
for crate in $cargo_crates {
    let desc = $"cargo install --locked ($crate)"
    let r = (do -i { ^cargo install --locked $crate } | complete)
    if $r.exit_code != 0 { $failed_installs = ($failed_installs | append $desc) }
}

# eget tools (eget installed via go above)
$env.EGET_BIN = ($home | path join ".local" "bin")

# On Linux, prefer gnu over musl and tar.gz over .deb to avoid
# interactive prompts when eget finds multiple matching assets.
let is_linux = ($nu.os-info.name == "linux")
let is_macos = ($nu.os-info.name == "macos")
let eget_gnu = if $is_linux { ["--asset", "gnu"] } else { [] }
let eget_gnu_tar = if $is_linux { ["--asset", "gnu", "--asset", "tar.gz"] } else { [] }

# eget tools: [description, ...args]
let eget_tools = [
    ["ikebastuz/wiper"]
    ["tokuhirom/dcv"]
    [...$eget_gnu "--file" "*" "nushell/nushell"]
    [...$eget_gnu "sharkdp/bat"]
    ["casey/just"]
    [...$eget_gnu "bootandy/dust"]
    ["lance0/xfr"]
    ["jacek-kurlit/pik"]
    [...$eget_gnu "pythops/tenere"]
    [...$eget_gnu_tar "alexpasmantier/television"]
    ["tarkah/tickrs"]
    [...$eget_gnu_tar "fujiapple852/trippy"]
    [...$eget_gnu "YS-L/flamelens"]
    # kdash: on Linux exclude musl, on macOS select macos
    ...(if $is_macos { [["--asset" "macos" "kdash-rs/kdash"]] } else { [["--asset" "^musl" "kdash-rs/kdash"]] })
    ...(if $is_linux { [["sectordistrict/intentrace"]] } else { [] })
    ...(if $is_linux { [[...$eget_gnu_tar "--asset" "^all-features" "--asset" "^.sha512" "--asset" "^.sig" "orhun/systeroid"]] } else { [] })
    ...(if $is_linux { [["Y2Z/monolith"]] } else { [] })
    # bandwhich: on Linux use gnu, on macOS use darwin
    ...(if $is_macos { [["--asset" "darwin" "imsnif/bandwhich"]] } else { [[...$eget_gnu "imsnif/bandwhich"]] })
    # binsider: on Linux use gnu and exclude sigs, on macOS use darwin and exclude sigs
    ...(if $is_macos { [["--asset" "darwin" "--asset" "^.sha512" "--asset" "^.sig" "orhun/binsider"]] } else { [[...$eget_gnu_tar "--asset" "^.sha512" "--asset" "^.sig" "orhun/binsider"]] })
    # wiki-tui: select by OS
    ...(if $is_macos { [["--asset" "macos" "Builditluc/wiki-tui"]] } else { [["--asset" "linux" "Builditluc/wiki-tui"]] })
    # xan: on Linux use gnu, on macOS use darwin
    ...(if $is_macos { [["--asset" "darwin" "medialab/xan"]] } else { [[...$eget_gnu_tar "medialab/xan"]] })
]

for args in $eget_tools {
    let repo = ($args | last)
    print $"=> eget ($args | str join ' ')"
    let r = (do -i { ^eget ...$args } | complete)
    if $r.exit_code != 0 { $failed_installs = ($failed_installs | append $"eget ($repo)") }
}

# Homebrew (mac only)
if ($nu.os-info.name == "macos") {
    let brew_formulas = ["gromgit/brewtils/taproom"]
    for formula in $brew_formulas {
        let r = (do -i { ^brew install $formula } | complete)
        if $r.exit_code != 0 { $failed_installs = ($failed_installs | append $"brew install ($formula)") }
    }
}

# Claude Code config
let claude_dir = ($home | path join ".claude")
mkdir $claude_dir
^ln -f ($build_machine | path join "claude-settings.json") ($claude_dir | path join "settings.json")
^ln -f ($build_machine | path join "statusline") ($claude_dir | path join "statusline")

# Install make-worktree script
let local_bin = ($home | path join ".local" "bin")
mkdir $local_bin
^ln -f ($build_machine | path join "make-worktree") ($local_bin | path join "make-worktree")
^chmod +x ($local_bin | path join "make-worktree")

# Report failures
if ($failed_installs | is-not-empty) {
    print ""
    print "=================================="
    print $"  ($failed_installs | length) install\(s\) failed:"
    print "=================================="
    for cmd in $failed_installs {
        print $"  - ($cmd)"
    }
    print "=================================="
    exit 1
}

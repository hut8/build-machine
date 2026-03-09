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
        try {
            ^go install $"($pkg)@latest"
        } catch {
            $failed_installs = ($failed_installs | append $"go install ($pkg)@latest")
        }
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
    try {
        ^eget --to ($home | path join ".local" "bin") jdx/mise
        ^mise install
    } catch {
        $failed_installs = ($failed_installs | append "eget --to ~/.local/bin jdx/mise")
    }
}

# Starship prompt
if (which starship | is-empty) {
    try {
        ^eget --to ($home | path join ".local" "bin") starship/starship
    } catch {
        $failed_installs = ($failed_installs | append "eget --to ~/.local/bin starship/starship")
    }
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
        try {
            ^nu --plugin-add $plugin
        } catch {
            $failed_installs = ($failed_installs | append $"nu --plugin-add ($plugin)")
        }
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
try { ^pipx install litecli } catch { $failed_installs = ($failed_installs | append "pipx install litecli") }
try { ^pipx install pgcli } catch { $failed_installs = ($failed_installs | append "pipx install pgcli") }
if (which mysql | is-not-empty) {
    try { ^pipx install mycli } catch { $failed_installs = ($failed_installs | append "pipx install mycli") }
}

# Fly.io
if (which fly | is-empty) {
    try {
        ^curl -L https://fly.io/install.sh | ^sh
    } catch {
        $failed_installs = ($failed_installs | append "curl -L https://fly.io/install.sh | sh")
    }
}

# Cargo crates
let cargo_crates = ["hexhog", "rustormy", "systemd-manager-tui", "mcat"]
for crate in $cargo_crates {
    try {
        ^cargo install --locked $crate
    } catch {
        $failed_installs = ($failed_installs | append $"cargo install --locked ($crate)")
    }
}

# eget tools (eget installed via go above)
$env.EGET_BIN = ($home | path join ".local" "bin")

# On Linux, prefer gnu over musl and tar.gz over .deb to avoid
# interactive prompts when eget finds multiple matching assets.
let is_linux = ((^uname -s | str trim) == "Linux")
let eget_gnu = if $is_linux { ["--asset", "gnu"] } else { [] }
let eget_gnu_tar = if $is_linux { ["--asset", "gnu", "--asset", "tar.gz"] } else { [] }

try { ^eget ikebastuz/wiper } catch { $failed_installs = ($failed_installs | append "eget ikebastuz/wiper") }
try { ^eget tokuhirom/dcv } catch { $failed_installs = ($failed_installs | append "eget tokuhirom/dcv") }
try { ^eget ...$eget_gnu --file '*' nushell/nushell } catch { $failed_installs = ($failed_installs | append "eget nushell/nushell") }
try { ^eget ...$eget_gnu sharkdp/bat } catch { $failed_installs = ($failed_installs | append "eget sharkdp/bat") }
try { ^eget casey/just } catch { $failed_installs = ($failed_installs | append "eget casey/just") }
try { ^eget ...$eget_gnu bootandy/dust } catch { $failed_installs = ($failed_installs | append "eget bootandy/dust") }
try { ^eget lance0/xfr } catch { $failed_installs = ($failed_installs | append "eget lance0/xfr") }
try { ^eget jacek-kurlit/pik } catch { $failed_installs = ($failed_installs | append "eget jacek-kurlit/pik") }
try { ^eget --asset "^.1.zip" bee-san/RustScan } catch { $failed_installs = ($failed_installs | append "eget bee-san/RustScan") }
try { ^eget pythops/tenere } catch { $failed_installs = ($failed_installs | append "eget pythops/tenere") }
try { ^eget ...$eget_gnu_tar alexpasmantier/television } catch { $failed_installs = ($failed_installs | append "eget alexpasmantier/television") }
try { ^eget tarkah/tickrs } catch { $failed_installs = ($failed_installs | append "eget tarkah/tickrs") }
try { ^eget ...$eget_gnu_tar fujiapple852/trippy } catch { $failed_installs = ($failed_installs | append "eget fujiapple852/trippy") }
try { ^eget YS-L/flamelens } catch { $failed_installs = ($failed_installs | append "eget YS-L/flamelens") }
try { ^eget kdash-rs/kdash } catch { $failed_installs = ($failed_installs | append "eget kdash-rs/kdash") }
try { ^eget sectordistrict/intentrace } catch { $failed_installs = ($failed_installs | append "eget sectordistrict/intentrace") }
try { ^eget ...$eget_gnu_tar --asset "^all-features" orhun/systeroid } catch { $failed_installs = ($failed_installs | append "eget orhun/systeroid") }
try { ^eget Y2Z/monolith } catch { $failed_installs = ($failed_installs | append "eget Y2Z/monolith") }
try { ^eget ...$eget_gnu imsnif/bandwhich } catch { $failed_installs = ($failed_installs | append "eget imsnif/bandwhich") }
try { ^eget ...$eget_gnu_tar orhun/binsider } catch { $failed_installs = ($failed_installs | append "eget orhun/binsider") }
try { ^eget Builditluc/wiki-tui } catch { $failed_installs = ($failed_installs | append "eget Builditluc/wiki-tui") }
try { ^eget medialab/xan } catch { $failed_installs = ($failed_installs | append "eget medialab/xan") }

# Homebrew (mac only)
let is_mac = ((^uname -s | str trim) == "Darwin")
if $is_mac {
    let brew_formulas = ["gromgit/brewtils/taproom", "ggozad/formulas/oterm"]
    for formula in $brew_formulas {
        try {
            ^brew install $formula
        } catch {
            $failed_installs = ($failed_installs | append $"brew install ($formula)")
        }
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

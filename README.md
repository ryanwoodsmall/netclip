# netclip

network clipboard built on docker with

- alipine linux
- bash
- dropbear ssh
- xclip x11 clipboard client
- xvfb virtual frame buffer x server
- x11vnc vnc server (for debugging)
- those perennial favorites, _**stdin**_ and _**stdout**_
- "last in, only out, maybe" technology

## usage

the `install` command will setup some scripts in `${HOME}/bin`

- `netclip`: netclip service interaction/control
- `sc`: shared clipboard copy
- `sp`: shared clipboard paste
- `localclip`: local clipboard manager
- `localclipin`: copy to local clipboard
- `localclipout`: paste from local clipboard
- `copysync`: copy stdin to both network and local clipboards

environment variables

var | purpose | default
--- | --- | ---
`clipuser` | netclip ssh user | *clippy*
`clipport` | netclip ssh port | *11922*
`cliphost` | netclip hostname/IP | docker container id
`clipinst` | netclip script installation path | `${HOME}/bin`
`clipssh` | netclip ssh command to use | `ssh`
`clipsshopts` | netclip ssh options | `-l ${clipuser} -p ${clipport}`

```
# netclip help
usage: /netclip [cmd]

  basics:
    export cliphost=hostname.domainname
    ssh -l clippy -p 11922 ${cliphost} /netclip install | bash
    cat ~/.ssh/id_rsa.pub | netclip addkey
    echo hello | sc
    sp
    cat /tmp/in.txt | netclip copy ; ssh remote 'netclip paste > /tmp/out.txt'

  commands:
          addkey: add an ssh key from stdin
           clear: clear the contents of the clipboard
       clearhist: clear all history entries
     clipboardin: manipulate clipboard selection stdin (abbrev: ci)
    clipboardout: manipulate clipboard selection stdout (abbrev: co)
            copy: copy stdin to the clipboard
        copysync: show script to copy to both network and local clipboard
             cut: alias for copy
         delhist: read a history entry from stdin and delete it
          delkey: read a key number from stdin and delete it
         delpass: delete the stored password file
     disautolock: disable autolocking the clipboard before copying
         dishist: disable capturing clipboard history
        dumpkeys: copy and paste ssh keys to stdout
      enautolock: enable autolocking the clipboard before copying
          enhist: enable capturing clipboard history
         gethist: read a history entry from stdin and show it
            help: show this help
         install: show install script for netclip/sc/sp
        listhist: list any existing history entries
        listkeys: show known ssh authorized keys
     listrawkeys: show ssh authorized_keys file
       localclip: show localclip script
     localclipin: show localclip stdin script
    localclipout: show localclip stdout script
            lock: mark the clipboard as read-only
         netclip: show netclip control script
           paste: paste the clipboard to stdout
       primaryin: manipulate primary selection stdin (abbrev: pi)
      primaryout: manipulate primary selection stdout (abbrev: po)
            reap: kill any lingering xclip processes
              sc: show network copy script
     secondaryin: manipulate secondary selection stdin (abbrev: si)
    secondaryout: manipulate secondary selection stdout (abbrev: so)
         setpass: read new password from stdin
    showautolock: show the clipboard autolocking status
        showhist: show the clipboard history status
        showlock: show the clipboard lock status
        showpass: show password
        showport: show the ssh clipboard port
        showuser: show the ssh clipboard user
              sp: show network paste script
          unlock: mark the clipboard as read-write
          update: update netclip scripts
```

## build

```
docker build --tag netclip .
```

## run

```
docker run -d --restart always --name netclip -p 11922:11922 netclip
```

## username/password

the username/password for ssh access is dumped to the logs at startup

```
docker logs netclip | awk -F: '/^user:/{print $NF}' | head -1 | tr -d ' '
docker logs netclip | awk -F: '/^pass:/{print $NF}' | head -1 | tr -d ' '
```

the ssh/vnc password can be shown using the `showpass` command as well

```
docker exec --user clippy netclip /netclip showpass
```

the ssh password can be reset from the docker host where netclip is running

```
docker exec --user clippy netclip sh -c 'echo SuperSecretNEWp@55W0rD+ | /netclip setpass'
```

the password file can be removed

```
docker exec --user clippy netclip /netclip delpass
```

## add an ssh key

substitute username/port/hostname below

enter password when prompted

```
cat ~/.ssh/id_rsa.pub | ssh -l clippy -p 11922 hostname /netclip addkey
```

test keys with

```
ssh -l clippy -p 11922 hostname /netclip help
```

## get scripts

automatic install

```
export cliphost=hostname
ssh -l clippy -p 11922 ${cliphost} /netclip install | bash
```

manual install

```
export cliphost=hostname
ssh -l clippy -p 11922 ${cliphost} /netclip netclip > ~/bin/netclip
chmod 755 ~/bin/netclip
~/bin/netclip sc > ~/bin/sc
~/bin/netclip sp > ~/bin/sp
chmod 755 ~/bin/s{c,p}
which -a netclip sc sp
```

## use scripts

set a hostname for `${cliphost}` and copy/paste to your heart's content

```
export cliphost=hostname
echo something | sc
sp
```

that's it!

once a host's key is in place it has full copy/paste powers as long as the cliphost is reachable

## set up a bunch of keys at once

bootstrapping keys is relatively simple assuming they're exchanged with the netclip host

```
git clone https://github.com/ryanwoodsmall/dockerfiles.git
git submodule init
git submodule update
cd alpine-netclip
git checkout master
git pull
docker build --tag netclip .
docker run -d --restart always --name netclip -p 11922:11922 netclip
docker exec --user clippy netclip /netclip delpass
docker cp ~/.ssh/id_rsa.pub netclip:/tmp/key.pub
docker exec --user clippy netclip bash -c 'cat /tmp/key.pub | /netclip addkey'
docker exec --user clippy netclip /netclip install | bash
for h in h01 h02 h03 ; do
  ssh $h cat .ssh/id_rsa.pub | netclip addkey
  netclip install | ssh $h
done
```

### uses

- system monitor?
  - htop/iostat/ifstat/etc. output on secondary
  - aggregate views w/tmux
- ring buffer with sponge
- ripple i/o loops
- broadcast/subscription/todo system?
- daemon/service/plugins for whatever programs for centralized clipping

### todo

- probably need a `clipproxycmd` setting
  - `nc`, `socat`, or similar to encapsulate SSH in HTTPS, act as VPN, etc.
  - can do this easily with `ProxyCommand` in `~/.ssh/config` for OpenSSH, Dropbear with `-J` option
  - wrapper script might be enough and is much simpler
    - works better with `dbclent -J...` as well without having to do coprocess/filedescriptor stuff
- debug environment var - run vs build time
- debug x11vnc should run as debug user connecting to clippy xvfb? xhost?
- just remove vnc stuff for now?
- watch a fifo?
- read-only flag? write-host check? "only host with IP #.#.#.# can copy"
- or read-only user? read-only port?
- lock down ssh command (requires openssh) similar to git
- remove root user requirement after setup, run as regular user
- ability to turn ssh password auth off
- ability to update: netclip script, startup .sh scripts, and dropbear packages
- peel out unnecessary/big packages
- clear on read, i.e. delete the clipboard when paste
- something more "enterprise-y" on centos/rhel w/auth (pam, ldap, kerberos, ...) stuff built in
- service discovery for user/host/port (mdns? other broadcast?)
- gui???
- real supervisor instead of shell loops?
- network of clipboards? local service, master service with broadcast, distribution?
- actual c/go/rust service process?
  - ssh replacement to gen a single binary?
  - i/o is the easy part
  - go: crypto/ssh and https://github.com/gliderlabs/ssh
    - garbage collection?
  - c: libssh2
- libssh2 server?
- multiple clipboards?
  - multiple copy/paste is ugh, complicates input
  - use as undo? implicit/explicit?
  - if clipboard is text, automatically copy to primary?
  - xclip supports primary/secondary/clipboard/buffer-cut
  - xsel supports primary/secondary/clipboard
  - clipboard is any data type, cut buffer is old, primary is "text only", secondary is underdefined
- xclip `-verbose`?
- xsel?
  - more features than xclip
  - `--append` option for stdin to selection
  - `--follow` option for tail-like stdin
  - `--exchange` option for primary/secondary
  - `--logfile` for logging errors
  - `--keep` option for primary/secondary persistence
  - `--verbose` option
- sselp
  - suckless simple x selection printer
  - works on primary, out only
  - https://tools.suckless.org/x/sselp/
- case-generation for function expansion
  - pipes are parsed BEFORE vars in $v1|$v2|$v3) ... case examples
  - ugh
- explicit file copy support?
  - would require "client" code
  - no
- volumes for docker stuff
  - dropbear
  - settings
  - history/log files
- localclip/localclipin/localclipout
  - windows/wsl: clip.exe, `powershell.exe Get-Clipboard`, winclip from putty, doit
    - https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/get-clipboard
    - https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.management/set-clipboard
    - probably need raw fo Get-Clipboard
    - clip.exe -> `powershell.exe Set-Clipboard -Value "..."`?
    - of course
  - screen/tmux: copy buffers?
- loadkeys (import keys from dumpkeys)
- history - separation in to YYYY/MM/DD/HH/MM/SS/N nanosecond format
  - UUID for filename?
  - sqlite db w/sha256sum/index for dedupe?
- ssh keys - show fingerprints
- make sc/sp/etc. script symlinks to netclip client
- base64 encode everything?
- gpg sign history?
- associate clip with ssh pubkey some how
- stack: clipboard->primary->secondary
- private keys? for external sync
- zero clipboards on xvfb start with `echo -n`
- move to `rbash`
  - disable compound execution, i.e... `netclip 'sp ; ls -lA /'`
  - just make netclip a valid shell and deal with ';' casing there?
- limit sudo usage to specific commands
  - apk, chown, chmod, sponge, etc.
- dumpkeys is copying but not pasting, not sure why
- ability to connect to "real"/existing x-window display via custom `DISPLAY=` setting & no xvfb
- default cincmd/coutcmd to sc/sp in localclip script?
- convert to 9p w/c9 (https://git.sr.ht/~ft/c9) and/or 9pro (https://git.sr.ht/~ft/9pro)
- rename `copy` and `paste` with "net" prefix to avoid conflict with `/usr/bin/paste`
- host key dump - `/etc/dropbear` in .tar?
- full backup/restore - `/data/clip` and `/data/vnc`(?) and `/home/clippy` and `/etc/dropbear` and ??? in .tar?
- pastebin-like web+url generation w/history
  - expiry is ugly
  - content-addressable (ish) with sha-256 (-512? b2sum? b3sum?) sums as key, data as value
    - i.e., `/data/persist/$sum/content`
    - combine w/cliphistory dated log dir files+symlinks for historical-ish tracking
    - current clipboard, primary, secondary aliases for in-memory clipboard
  - store uuid along with hash?
    - every file only has one sha-### sum
    - uuid is equally unique
    - but a uuid with a collection of sums could represent a bundle of files - i.e., .tar or similar
  - version with `.#` extension?
    - only makes sense with uuid/hash sum mapping
    - would have to do tombstones when a file is removed from a bundle at a version
    - woof
  - just use venti, man
    - or nix or guix or...
  - wow: https://github.com/golang-design/clipboard and https://github.com/changkun/midgard
- i need to rip some of this shit out
- ooh, small xclipd/xclipin/xclipout: https://github.com/phillbush/xcliputils
- stripped down container with only bash+xvfb+tinysshd+xclipd+tr+fold+printf+tee+sponge+...
  - replace as much as possible w/pure bash; `echo` -> `>>>` ???
  - ed25519 only!
    - ssh keys are the _only_ state; negative features.
    - dropbearkey for generation
  - other utilities? date, tee, grep, ...
  - decrease attack surface significantly

### links

- https://github.com/danielguerra69/alpine-vnc
- https://github.com/jkuri/alpine-xfce4
- https://wiki.archlinux.org/index.php/Clipboard

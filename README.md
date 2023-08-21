git-tools - Convenient Abbreviated Git CLI Commands
===================================================

This provides a small set of Bash¹ functions and commands that greatly
shorten the amount of typing you have to do for common Git operations (even
if you already use command-line completion). For example:

    com     # git commit -v
    cam     # git commit -v --amend
    logm    # LESS=-aeFimsXR -j.15 -SR git log --graph --abbrev-commit --pretty=oneline --decorate=short --pretty=tformat:%C(auto)%h %C(green)%<(12,trunc)%ar%C(auto) %C(black)%<(20,trunc)%ae%C(auto)%C(auto)% D%n%C(blue)%s

The same command-line completions are available as for the long Git
commands.

¹ Bash is required; this uses Bash features that do not exist in POSIX
shells.


Installation
------------

### Stand-alone Use

Ensure the files under `bin/` are in your $PATH, e.g. by doing one of the
following:
- Add `…/git-tools/bin/` to your $PATH.
- Add links to those files in an existing directory in your $PATH.
- Copy the files to an existing directory in your $PATH.

Then add `source gitcmd-short.bash` to your `~/.bashrc`.

### dot-home Use

    mkdir -p ~/.home
    cd ~/.home
    git clone https://github.com/dot-home/_dot-home.git     # Core system
    git clone https://github.com/dot-home/git-tools.git     # This repo
    ~/.home/_dot-home/bin/dot-home-setup


Commands
--------

For the exact details of what each command does (i.e., to work out the
traditional `git` command line that is eventually produced), see
`bin/gitcli-short.bash`.

Almost all commands take the same additional options as the underlying Git
command, and command line completion is the same as the underlying Git
command.

These commands will tweak the $LESS variable where necessary to produce
prettier output.

### Terminology Note

- A __branch__ is a sequence of commits. It may or may not be pointed to by
  a ref, (though it can be garbage-collected if not), and multiple refs may
  point to the same branch, or different commits on the same branch.
- A __ref__ is any named pointer to a commit, e.g., as created with the
  `git branch REFNAME` command. Note that this does _not_ create a new
  _branch_ as that term is used here: `@` and `REFNAME` are two refs
  poining to the _same_ branch.
- A __head__ is any ref pointing to a commit that has no children pointed
  to by any any other head. (I.e., a head points to the tip of a branch,
  not the middle of a branch.)

### Commmit Graph Display (git log)

- `log`: Same as `git log`.

- `logs`: As `log` with the list of files changed in each commit. The stat
  widths are slightly tweaked to maximize the amount of the filename you
  see.

- `logp`, `logp1`, `slp1`: As `logs` with the diff from the previous commit
  (`--patch`) as well. `logp1` does this for a single commit, rather than
  all commits down that branch of the graph. `slp1` does the same with a
  few blank lines prefixed to clearly separate the commit from previous
  output in the terminal. (This is useful mainly on tall terminal windows.)

- `logb`: Brief (one line per commit) graph of current or specified
  refs. The $LESS variable will have `-RS` appended to enable proper
  display of colour and turn off line wrapping so that all commits take up
  one line. (You can scroll left and right to see more of the commit
  summary line.)

- `logab`: As `logb` but for all heads in the repo.

- `logh`: Show "recent" (within a week) changes on all heads.
  (The implementation of this needs to be improved.)

- `logm`: Brief graph with commit metadata, using two lines per commit. The
  first line gives the abbreviated commit ID, age of the commit, author,
  and ref information. The second line is the commit summary line.

- `logmn`: As `logm` without single-parent merge commits.

### Ref (Branch) Information (git branch/checkout/etc.)

- `br`: As `git branch`.

- `glr`, `glra`: List refs, as `git branch -l`. This automatically uses the
  most verbose format (giving short commit ID, tracking branch and
  ahead/behind status, and a bit of the most recent commit summary
  message). Output is sent through `less` by default limiting the line
  length to the terminal width; you may add `-n` to avoid less quitting
  immediately at EOF so you can scroll horizontally or turn on line wrap by
  typing `-S`. `glra` is just `glr -a`. (This is named to avoid conflicts
  with the `lr` file listing program.)

- `co`: As `git checkout`

- `mbase`: Display the base whence the current branch diverged from `master`.
  (This needs considerable fixing.)

### Commit Text/Diff Display (git diff/blame)

See also above `logp`, `logp1`, `slp1`.

- `blame`
- `dif`
- `difs`
- `dift`

### Resetting the Work Tree (git reset/clean)

- `gre`
- `grehard`
- `greupstream`
- `clean`
- `iclean`
- `stash`

### Creating Commits (git add/commit/submodule)

- `add`
- `com`
- `coma`
- `cam`
- `gsub`

### Rebasing (git rebase)

- `gr`
- `grmu`
- `grabort`
- `grcontinue`
- `grskip`
- `gri`
- `grwhere`
- `cpick`

- `mergeff`: As `git merge --ff-only`.

### Remote Operations (git remote/fetch/push/pull)

- `gurl`
- `rem`
- `fetch`
- `pull`
- `push`
- `pushf`
- `pushu`

### Misc.

- `ggrep`
- `gfgrep`
- `gk`

### Repository Maintenance

- `gpack`



Other Tools
-----------

* [dustin/bindir] contains quite a few useful git tools, written
  mainly in Python.



<!-------------------------------------------------------------------->
[dustin/bindir]: https://github.com/dustin/bindir

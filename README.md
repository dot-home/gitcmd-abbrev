gitcmd-abbrev - Convenient Abbreviated Git CLI Commands
===================================================

gitcmd-abbrev¹ provides a small set of Bash² functions and commands that
greatly shorten the amount of typing you have to do for common Git
operations (even if you already use command-line completion). For example:

    com     # git commit -v
    cam     # git commit -v --amend
    logm    # LESS=-aeFimsXR -j.15 -SR git log --graph --abbrev-commit --pretty=oneline --decorate=short --pretty=tformat:%C(auto)%h %C(green)%<(12,trunc)%ar%C(auto) %C(black)%<(20,trunc)%ae%C(auto)%C(auto)% D%n%C(blue)%s

The same command-line completions are available as for the long Git
commands.

¹ This is not named `git-abbrev` because that is the name that would be
used for the script supporting a `git abbrev` subcommand.

² Bash is required; this uses Bash features that do not exist in POSIX shells.

Contents:
- [Installation](#installation)
- [Commands](#commands)
- [Other Tools](#other-tools)


Installation
------------

### Stand-alone Use

Ensure the files under `bin/` are in your $PATH, e.g. by doing one of the
following:
- Add `…/gitcmd-abbrev/bin/` to your $PATH.
- Add links to those files in an existing directory in your $PATH.
- Copy the files to an existing directory in your $PATH.

Then add `source gitcmd-abbrev.bash` to your `~/.bashrc`.

### dot-home Use

    mkdir -p ~/.home
    cd ~/.home
    git clone https://github.com/dot-home/_dot-home.git     # Core system
    git clone https://github.com/dot-home/gitcmd-abbrev.git # This repo
    ~/.home/_dot-home/bin/dot-home-setup

### Testing

Sadly, testing is mostly manual at the moment, with some assistance from
the (admittedly crappy) `Test` script. That script also has notes on manual
testing in the comments.


Commands
--------

Almost all commands take the same additional options as the underlying Git
command, and command line completion is the same as the underlying Git
command. However, some commands (mostly those that run `git log`) can
take "comma-options" as the first argument on the command line. This is
a comma followed by one or more characters, e.g., `,rd` will log in
reverse and suppress decoration. The available comma options are:

    d   --no-decorate
    g   --graph
    r   --reverse

All commands will tweak the $LESS variable where necessary to produce
prettier output.

Where the documentation below does not suffice, you can examine the actual
functions in `bin/gitcmd-abbrev.bash` or `set -x` to turn on tracing before
running the command. (`set +x` will undo the tracing).

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

### Status Display

- `st`: Similar to `git status -bs`, except:
  - Within a Git repo it will recursively display status of submodules up
    to a given level _n_ specified with the `-n` option (default `-1`).
  - Outside of a Git repo, given arguments that are directories, will
    display a brief status for each directory, including whether it's a
    plain directory, a Git repo, etc., the number of changed and untracked
    files, and the current branch and latest commit message summary.
  - Within a CVS checkout it will display the status of that. It should be
    extended to give basic information about other VCS checkouts as well.
- `st0`, `st9`: Same as `st -0` and `st -999`, respectively.

### Commmit Graph Display (git log)

- `log`: Same as `git log`.

- `logs`: As `log` with the list of files changed in each commit. This
  always gives the full path for each file, even if this causes wrapping;
  use `-S` in `less` if you want horizontal scrolling instead of wrapping.
  It minimizes the the size of the histogram for adds/deletes (5 max)
  because that provides minimal information anyway. It also shows a
  specific indication on new and deleted ("gone") files.

- `logp`, `logp1`, `slp1`, `logpr`:
  As `logs` with the diff from the previous commit (`--patch`) as well.
  `logp1` does this for a single commit, rather than all commits down that
  branch of the graph. `slp1` does the same with a few blank lines prefixed
  to clearly separate the commit from previous output in the terminal.
  (This is useful mainly on tall terminal windows.) `logpr` prints
  the commits in reverse order, which is useful for doing a "walk forward
  through the commits" review of code. (To review a dev branch, for example,
  you could use `logpr main@{u}..origin/dev/joe/bugfix`.

- `logb`: Brief (one line per commit) log of current or specified refs.
  (`,g` or `,r` is particularly useful here.) The $LESS variable will have
  `-RS` appended to enable proper display of colour and turn off line
  wrapping so that all commits take up one line. (You can scroll left and
  right to see more of the commit summary line.)

- `logab`: As `logb` but graph output for all heads in the repo.

- `logd`: As `logb`, but for the following refs:
  - All of the following that exist:
    `main`, `main@{upstream}`, `master`, `master@{upstream}`.
  - The current HEAD and, if it has a tracking ref, its tracking ref.
  - All local and remote tracking refs matching `dev/*/DESC` where `DESC`
    is the last component of the current branch name. E.g., if you are on
    `dev/cjs/24g31/new-feature`, it will match all other refs
    `dev/*/new-feature` local and remote.

- `logh`: Show "recent" (within a week) changes on all heads.
  (The implementation of this needs to be improved.)

- `logm`: Brief log with commit metadata, using two lines per commit. The
  first line gives the abbreviated commit ID, age of the commit, author,
  and ref information. The second line is the commit summary line.

- `logmn`: As `logm` without single-parent merge commits.

### Other Commit Information Display (git shortlog)

- `gauthors`: Show all authors and their commit counts for the commit range
  given (default `@`, i.e., all commits from HEAD back to the first
  commit).

### Ref (Branch) Information (git branch/checkout/etc.)

- `br`: As `git branch`.

- `lr`, `lrg`, `lrh`, `lra`: List refs, as `git branch -l`. As well as some
  standard git-branch arguments, these also accept a list of string
  fragments that will limit the output to refs matching any of them. (E.g.,
  you might use `lra dev/cjs/` to see only development branches made by
  user `cjs`.)
  - `lr`: local heads only.
  - `lrg` local heads whose upstream is "gone" (remember to `fetch -p` first)
  - `lrh` all heads (local and remote),
  - `lra` all refs, even if not a head (i.e., unknown to `git branch`).

  This automatically uses the most verbose format (giving short commit ID,
  tracking branch and ahead/behind status, and a bit of the most recent
  commit summary message). Output is sent through `less` by default
  limiting the line length to the terminal width; you may add `-n` to avoid
  less quitting immediately at EOF so you can scroll horizontally or turn
  on line wrap by typing `-S`.

  This name conflicts with the with the `lr` file listing program. This is
  not normally an issue in script files, since they will not inherit this
  function, but if you need to get around it locally, consider adding
  an `lrr` function that calls `/usr/bin/lr`.

- `co`: As `git checkout`

- `cond`: Checkout new development branch. Typicaly used as `cond foo` to
  start a new branch `dev/user/date/foo` at `main@{upstream}`.
  See `cond -h` and experiment with `cond -n` for full details.

- `mbase`: Display the base whence the current branch diverged from `master`.
  (This needs considerable fixing.)

### Commit Text/Diff Display (git diff/blame)

See also above `logp`, `logp1`, `slp1`.

- `blame`: As `git blame`.
- `dif`: As `git diff`.
- `difs`: Diff staged files, as `dif --cached`.
- `dift`: As `git difftool -y`

### Resetting the Work Tree (git reset/clean)

- `gre`: As `git reset`.
- `grehard`: As `git reset --hard`.
- `greupstream`: As `git reset --hard @{upstream}`
- `clean`: With no arguments, as `git clean --dry-run`. Supplying `-f` will
  suppress the `-n`/`--dry-run` argument.
- `iclean`: Clean ignored files and directories too, as `clean -dX`.
- `stash`: With no arguments, lists stash entries.
  With any arguments, as `git stash`.

### Creating Commits (git add/commit/submodule)

- `add`: As `git add`.
- `com`: As `git commit -v`.
- `coma`: As `com --all`
- `cam`: As `com --amend`
- `gsub`: As `git submodule`.

### Rebasing (git rebase)

- `gr`: As `git rebase`
- `grmu`: As `git rebase … master@{upstream}`. (XXX this needs to be fixed
  to use the default head, so it works with `main` as well.)
- `grabort`: As `git rebase --abort`.
- `grcontinue`: As `git rebase --continue`.
- `grskip`: As `git rebase --skip`.
- `gri`, `grim`: Do a `git rebase -i`. `gri` defaults to the last ten
  commits; you may give it a number for a different number of commits, or
  any ref and it will start at that ref. `grim` starts at the first commit
  that diverges from `main@{upstream}` (i.e., your entire current
  development branch.)
- `grwhere`
- `cpick`: As `git cherry-pick`.
- `cpcontinue`: As `cpcick --continue`.

- `mergeff`: As `git merge --ff-only`.

### Remote Operations (git remote/fetch/push/pull)

- `gurl [REPO-DIR …]`: Show fetch URLs for the repo(s) at or above
  _REPO-DIR,_ (default: current working directory), one per line.
- `rem`:
  - With no arguments, display a line for each remote giving the name and
    fetch URL. If the push URL is different, a second line with the name
    and the push URL will be displayed.
  - With arguments other than below, as `git remote`.
  - With `-H` as the first argument, check for remote HEAD branch updates
    and update local refs to match. This changes the local {remote}/HEAD
    ref to be the same as the remote and, if there is a local branch of
    the same name tracking the old {remote}/HEAD, makes it track the new
    {remote}/HEAD and renames it to the new branch name.
- `fetch`, `pfetch`
  - With no arguments, fetch from `remotes.default` or, if that's not set,
    all remotes. Then show the current status of the working copy (as `git
    status -bs`).
  - With any argument that's a path to a directory containing a .git/
    subdirectory, assume all args are paths to repos to be fetched as
    above or paths to be ignored. The user is informed for each one
    whether it's being feched or ignored.
  - With arguments, as `git fetch`.
  - `pfetch` is `fetch --prune` (It has the _p_ at the start, rather than
    at the end, to improve command-line completion.) Note that this does
    not prune tags by default, for reasons described in the comment on
    that function; you may add `--prune-tags` if you want to do this.
- `pull`: As `git pull --ff-only`. (This keeps you from accidentally
  getting stuck in a complicated merge.)
- `push`: As `git push`, but does not accept the `-f`/`--force` options.
- `pushf`: As `git push --force-with-lease`. This also does not accept the
  `-f`/`--force` options; to do that (which is quite dangerous) use `git
  push`.
- `pushu [-f] REMOTE [REMOTE-REF]`: Push the current branch to a branch of
  the same name on _remote,_ or to a branch named _remote-ref_ if given,
  and set the upstream of the current branch to that. This will refuse to
  operate if the current branch already has an upstream configured. The
  `-f` option will override this, removing any currently configured
  upstream before pushing and configuring the new upstream.

### Misc.

- `ggrep`: As `git grep`.
- `gfgrep`: As `ggrep -F` (i.e., without interpreting the pattern as a
  regex).
- `gk [START-COMMITISH]`: Runs `gitk --all`, with the commit at
  _START-COMMITISH_ selected if supplied.

### Repository Maintenance

- `gpack`: Do a garbage collection (`git gc`) and then pack the repo down
  to the minimum number of files, removing all loose object files and
  similar. Any arguments are passed on to `git gc` so you may use, e.g.,
  `--aggressive` to collect down to a smaller size before the pack.


Other Tools
-----------

* [dustin/bindir] contains quite a few useful git tools, written
  mainly in Python.



<!-------------------------------------------------------------------->
[dustin/bindir]: https://github.com/dustin/bindir

#   Function (command) definitions for shortened Git commands.
#   `source` this file in your ~/.bashrc.

#   Is Git version on this host >= given version?
__gitcmdabbrev_gitver_GE() {
    local vs=($(git --version | sed -e 's/git version //' -e 's/\./ /g'))
    local ws=($(echo "$@" | sed -e 's/\./ /g'))
    # For `-lt`, empty string is 0
    [[ ${vs[0]} -lt ${ws[0]} ]] && return 1
    [[ ${vs[1]} -lt ${ws[1]} ]] && return 1
    [[ ${vs[2]} -lt ${ws[2]} ]] && return 1
    [[ ${vs[3]} -lt ${ws[3]} ]] && return 1
    return 0
}

__ifref() {
    : ' Verify that all arguments name commits.
        Return success (0) if they all do, or failure (1) if any do not.
    '
    local ref
    for ref in "$@"; do
        git rev-parse -q --verify "$ref^{commit}" >/dev/null \
            || return 1
    done
    return 0
}

#   Very short date format for use in branch names:
#   two-digit year, letter for the month, two-digit day.
#   December is renamed from `l` to `m` because `l` looks to much like `1`.
__gitcmdabbrev_bdate() {
    local y=$(date +%y);
    local m=$(date +%m);
    local d=$(date +%d);
    if [[ $m < 10 ]]; then
        m=$(echo ${m#0} | tr 1-9 a-i);
    else
        m=$(echo ${m#1} | tr 0-2 jkm);
    fi;
    echo "$y$m$d"
}

############################################################
# "Copy" git completion to our custom functions

#   Ensure we have __git_wrap__git_main
[ -f /usr/share/bash-completion/completions/git ] \
    && source /usr/share/bash-completion/completions/git
[ -f /mingw64/share/git/completion/git-completion.bash ] \
    && source /mingw64/share/git/completion/git-completion.bash

copy_git_completion() {
    type __git_wrap__git_main >/dev/null || return 0
    local command="$1"; shift
    eval "
        function __copy_git_completion::$command {
            (( COMP_CWORD += 1 ))
            COMP_WORDS=("$@" \${COMP_WORDS[@]:1})
            (( COMP_POINT -= \${#COMP_LINE} ))
            COMP_LINE=\${COMP_LINE/$command/"$@"}
            (( COMP_POINT += \${#COMP_LINE} ))
            __git_wrap__git_main
        }
    "
    complete -o bashdefault -o default -o nospace \
        -F "__copy_git_completion::$command" "$command"
}

############################################################
# git status functions

st0() { st -0   "$@"; }
st9() { st -999 "$@"; }

############################################################
# git log functions (completion setup at end)

#   "Full" commit output (multiple lines per commit)

log()  { git log --date=iso "$@"; }

logs() {        # full paths of changed files
    log --compact-summary --stat=999 --stat-graph-width=5 "$@"
}

logp() {        # log with patches
                # changed paths are truncated in stat, full in diff
    log --stat -p "$@"
}

logpr() { logp --reverse "$@"; }

logp1() {       # most recent patch
    logp -1 "$@"
}

slp1() {        # most recent patch with leading blank lines for readability
    local i; for i in 1 2 3 4 5; do echo; done
    logp1 "$@"
}

#   "Oneline" commit output (1-2 lines per commit)

logb() {        # brief graph of current or specified branches
    # Use `-S` in less to switch to wrapped lines instead of sideways scrolling
    LESS="$LESS -SR -X" \
    log --graph --abbrev-commit --pretty=oneline --decorate=short "$@"
}

logab() {       # brief graph of all branches
    local exclude_notes='--exclude=refs/notes/\*'
    __gitcmdabbrev_gitver_GE 1.8 || exclude_notes=
    logb --all $exclude_notes "$@"
}

logd() {       # brief graph of this dev branch, related, and main
    local refs=()
    __ifref main && refs+=( main )
    __ifref main && refs+=( main@{upstream} )
    __ifref master && refs+=( master )
    __ifref master && refs+=( master@{upstream} )
    __ifref HEAD@{upstream} && refs+=( HEAD@{upstream} )
    local devbr=$(git rev-parse --symbolic-full-name HEAD)
    refs+=("$devbr")
    local desc="${devbr##*/}"
    #   XXX this fails on ref names with spaces in them
    refs+=( $(git rev-parse --symbolic-full-name \
        --branches="dev/*/$desc" --remotes="*/dev/*/$desc") )
    logb "${refs[@]}" "$@"
}

logh() {        # the "head" of the repo
    #   The idea is to get a quick overview of the relationships between
    #   the tips of recent branches that are at least moderately closely
    #   related to HEAD (or master?). This method of selecting the commits
    #   and limiting the number shown could probably be improved. In
    #   particular, it would be nice to show a bit of HEAD no matter how
    #   old it is.
    LESS="$LESS -E -X" logab --since '1 week ago' -n 30 "$@";
}

logm() {        # brief graph with commit metadata
    local sha='%C(auto)%h'
    # Truncated relative works better for quick review than %ad
    local date='%C(green)%<(12,trunc)%ar%C(auto)'
    local author='%C(black)%<(20,trunc)%ae%C(auto)'
    local branches='%C(auto)% D'
    local subject='%n%C(blue)%s'

    local format="$sha $date $author$branches$subject"
    logb --pretty="tformat:$format" "$@"
}

logmn() {       # logm without merges
    logm --no-merges "$@"
}

logbr() {   # XXX FIXME
    local -a argv=("$@")
    local branchref=@
    if [[ ${#argv[@]} -gt 0 ]] && [[ ${argv[-1]} != -* ]]; then
        local branchref="${argv[-1]}"
        unset 'argv[-1]'
    fi
    logs "${argv[@]}" $(mbase "$branchref").."$branchref"
}

#   Completion

for f in log logs logp logpr logp1 slp1 logb logab logh logm logmn logbr; do
    copy_git_completion $f git log
done

############################################################
# git shortlog functions

gauthors() {      # list authors and their commit counts
    git shortlog -e -sn "$@"
}; copy_git_completion gauthors git shortlog

############################################################
# git diff, other repo search/browse/etc. functions

blame() { git blame "$@"; }; copy_git_completion blame git blame

dif()   { git diff "$@"; }; copy_git_completion dif git diff
difs()  { dif --cached "$@"; }; copy_git_completion difs git diff
dift()  { git difftool -y "$@"; }; copy_git_completion dift git difftool

ggrep()         { git grep "$@"; }; copy_git_completion ggrep git grep
gfgrep()        { ggrep -F "$@"; }; copy_git_completion gfgrep git grep

gk()            {
    [ -n "$1" ] && { start="--select-commit=$1"; shift; }
    [ -n "$1" ] && { echo 1>&2 'Usage: gk [start-commitish]'; return 2; }
    gitk --all "$start";
}


############################################################
# git checkout, stage, commit, clean

co()        { git checkout "$@"; }; copy_git_completion co git checkout
#complete -r co 2>/dev/null  # Perhaps not necessary given all options below?

__gitcmdabbrev_cond_usage() {
    echo 'Usage: cond [opts] branch-desc [start-ref]'
    echo 'If `branch-desc` has a slash in it, it will be used as the entire branch name.'
    echo '`start-ref` is 'main@{u}' if not supplied'
    echo 'Options (defaults may be put in $GITCMD_ABBREV_COND_ARGS):'
    echo '  -h        print this help'
    echo "  -n        don't create branch, just print what this would do"
    echo '  -u USER   set developer name in branch to USER'
    echo '  -ds       short date format: YYmDD'
    echo '  -di       ISO date format: YYYY-MM-DD'
    echo '  -dn       no date in branch name'
}
cond() {
    local dry_run= user=$(id -nru) date=$(__gitcmdabbrev_bdate) branchdesc \
        start_ref='main@{u}' branchname
    #   Avoid a 'set' command with no args, which prints all vars/funcs.
    [[ -n ${GITCMD_ABBREV_COND_ARGS:-} ]] \
        && set -- $GITCMD_ABBREV_COND_ARGS "$@"
    while [[ $# -gt 0 ]]; do case "$1" in
        -h)     __gitcmdabbrev_cond_usage; return 0;;
        -n)     shift; dry_run=echo;;
        -u)     shift; user="$1"; shift;;
        -ds)    shift; date=$(__gitcmdabbrev_bdate);;
        -di)    shift; date=$(date -I);;
        -dn)    shift; date='';;
        -*)     echo 1>&2 "cond: bad option '$1'"; return 1;;
        *)      break;;
    esac; done
    [[ -n ${1:-} ]] \
        && { branchdesc="$1"; shift; } \
        || { echo 1>&2 'cond: branch-desc required; -h for help'; return 0; }
    [[ -n ${1:-} ]] && { start_ref="$1"; shift; }
    [[ $branchdesc = */* ]] \
        && branchname="$branchdesc" \
        || branchname="dev/$user/${date:+$date/}$branchdesc"
    $dry_run co --no-track -b "$branchname" "$start_ref"
}

add()       { git add "$@"; }; copy_git_completion add git add

com()       { git commit -v "$@"; }; copy_git_completion com git commit
coma()      {
                # If we have changes staged in the index, assume we don't
                # want to commit unstaged changes.
                local _a=''
                git diff-index --quiet --cached HEAD -- && _a='-a'
                com $_a "$@";
            }; copy_git_completion coma git commit
cam()       { com --amend "$@"; }; copy_git_completion cam git commit
cpick()     { git cherry-pick "$@"; }; copy_git_completion cpick git cherry-pick
cpcontinue() { cpick --continue "$@"; }; copy_git_completion cpcontinue git cherry-pick

#   `git clean` with `-n` supplied for you unless you specify `-f`
clean()     {
    local noforce=-n
    for arg in "$@"; do case "$arg" in
        -*f*)  noforce=;;
    esac; done
    git clean $noforce "$@";
}; copy_git_completion clean git clean

#   Clean explicitly ignored files and directories
iclean()    { clean -dX "$@"; }; copy_git_completion iclean git clean

#   This avoids conflicts with `gs` (Ghostscript) and `gm` (GraphicsMagick)
sm()       { git submodule "$@"; }
copy_git_completion sm git submodule

gpack()     {
    #   Pack down a repo to the minimun number of files. This is useful
    #   when archiving repos, sync'ing filesystems, etc.
    #   The gc ensures that we don't have unrefrenced objects, but will
    #   leave loose objects not referenced by branches (e.g., reflog
    #   stuff). The repack takes care of this.
    #   This also removes the pointless sample hooks that git loves to create.
    #
    #   XXX Argument handling is currently wrong. We should accept
    #   --aggressive to pass to `gc`, and any other args should be for
    #   `git` itself (e.g., --git-dir).
    #
    git gc "$@" || return
    git repack -adk         # Also packs unreachable objects
    local gitdir=$(git rev-parse --git-dir)
    rm "$gitdir"/hooks/*.sample "$gitdir"/modules/*/hooks/*.sample \
        2>/dev/null || true
    rmdir "$gitdir"/hooks "$gitdir"/modules/*/hooks 2>/dev/null || true
}


############################################################
# git branch

#   List local refs matching the optional pattern(s) anywhere in the ref
#   name. This always lists in -v -v mode (giving short commit ID, tracking
#   branch and ahead/behind status) and truncates lines to the terminal
#   width. You may give it the -n option to have less not exit immediately
#   at EOF if you need to scroll left/right to see more of the output.
#
#   TODO: look into using `git branch --format` or maybe even `git
#   for-each-ref` to improve formatting, add multi-line output, or
#   whatever.
lr() {
    #   (This is named to avoid conflicts with the 'lr' file listing program.)
    local -a args=("$@") skipnext=false eofquit=-E
    for i in $(seq 0 $((${#args[@]}-1))); do
        #echo "$i:" $skipnext \'${args[$i]}\'
        $skipnext && { skipnext=false; continue; }
        case "${args[$i]}" in
            -n)             args[$i]="-l"; eofquit=-e;;
            --contains)     skipnext=true;;
            --no-contains)  skipnext=true;;
            --merged)       skipnext=true;;
            --no-merged)    skipnext=true;;
            --points-at)    skipnext=true;;
            --sort)         skipnext=true;;
            --format)       skipnext=true;;
            -t|-u)          skipnext=true;;
            [^-]*)          args[$i]="*${args[$i]}*"
        esac
    done
    git branch -l -v -v --color "${args[@]}" | less $eofquit -R -S -J -X
}; copy_git_completion lr git branch

#   As lr() but for all (local and remote) refs.
lrh() { lr -a "$@"; }
copy_git_completion lrh git branch

#   XXX TODO: This should always show the tracking branch and unpushed
#   commits (à la `git branch -vv`), and should probably be rewritten
br() { git branch "$@"; }
copy_git_completion br git branch

#   XXX FIXME: Not well tested (or documented).
mbase() {
    local range_to=false
    [ _"$1" = _-t ] && { range_to=true; shift; }
    local here=${1:-HEAD}
    local there=${2:-main@{upstream}}

    local base=$(git merge-base "$here" "$there")
    if $range_to; then
        echo "$base..$here"
    else
        echo "$base"
    fi
}

############################################################
# git rebase, reset, similar

mergeff()       { git merge --ff-only "$@"; }   # Should be `integrate`?

gr()            { git rebase "$@"; }
grmu()          { git rebase "$@" main@{upstream}; }
grabort()       { git rebase --abort "$@"; }
grcontinue()    { git rebase --continue "$@"; }
grskip()        { git rebase --skip "$@"; }
gri()           {
    local arg=${1:-10}                  # default: 10 commits back
    [ $arg -lt 1000 ] 2>/dev/null \
        && git rebase -i "HEAD~$arg" \
        || git rebase -i "$arg^"
}
grim()          { git rebase -i "$(mbase)" "$@"; }
for f in gr grm grabort grcontinue grskip gri grim; do
    copy_git_completion $f git rebase
done

grwhere()       { logb ORIG_HEAD HEAD --not $(git merge-base ORIG_HEAD HEAD)^; }

gre()           { git reset "$@"; }
grehard()       { git reset -q --hard "$@" \
                  && echo 'Current and previous locations:' \
                  && git reflog show -2 #'HEAD@{1}'
                }
greupstream()   { grehard '@{upstream}'; }
for f in gre grehard greupstream; do
    copy_git_completion $f git reset
done

stash()         { if [ "$1" = "" ]
                    then echo; git stash list
                    else git stash "$@"
                    fi
                }
copy_git_completion stash git stash


############################################################
# git remote operations

# Most of these are planned to have further additional functionality,
# e.g., having `fetch` be able to take a list of paths to
# repos/workdirs and fetch in each of them.

#   List fetch URLs for the repos given on the command line.
#   Options:
#       -o  Show `origin` push URL only
#
#   XXX TODO: Fix -o so that it doesn't care about the remote name, but
#   shows the "primary" remote identified by the one whence the tracking
#   branch for `main` or `master` comes. (And possibly rename the option.)
#
gurl()  {
    local origin_only=''
    [[ $1 = -o ]] && { shift; origin_only='/^origin[[:space:]]/!d'; }
    [[ -n $1 ]] || set .    # default arg
    for dir in "$@"; do
        git -C "$dir" remote -v | sed \
            -e '/ (push)$/d' \
            -e 's/ (fetch)$//' \
            -e "$origin_only" \
            -e 's/^[^[:blank:]]*[[:space:]]*//'
    done
}

rem()   {
    local format_table='column -t'
    #   Without the `column` command (`bsdmainutils` package) we do a
    #   fixed 12-column format for repo names, overflowing if necessary.
    column </dev/null 2>/dev/null || format_table=cat

    if [[ ${#@} -gt 0 ]]; then
        git remote "$@"
    else
        # List all remotes with their push URLs.
        local rems
        mapfile -t rems < <(git remote)
        for rem in "${rems[@]}"; do
            printf "%-12s %s\n" "$rem" "$(git remote get-url --push "$rem")"
        done | $format_table
    fi
}; copy_git_completion rem git remote

#   Given no args, fetch from remotes.default or, if not set, all remotes.
#
#   Otherwise, args may be of two forms for different functionality:
#   • If any argument is a path to a directory containing a .git/ subdir,
#     we assume that all args are paths. For those that are Git repos,
#     we recursively run fetch() on them. For those that are not, we
#     inform the user that we're ignoring them.
#   • Otherwise we're fetching the repo for the current working directory,
#     and we run `git fetch` with the arguments given.
#
#   This massages the output of `git fetch` to be significantly more quiet.
#
fetch() {
    local allarg='--all' fetchcwd=true
    for arg in "$@"; do
        # Disable --all if remote or dir specified (arg without leading `-`)
        [[ ${arg#-} == $arg ]] && allarg=''
    done

    for arg in "$@"; do
        # If any arg is a directory with a .git/ dir under it, the repo is
        # not that of the current working directory, but a list of paths
        # to repos to fetch.
        [[ -d "$arg/.git" ]] && fetchcwd=false
    done
    if ! $fetchcwd; then    # multi-repo fetch
        for path in "$@"; do
            if [[ -d "$path/.git/" ]]; then
                echo "===== Fetching $path"
                (cd "$path" && fetch)
            else
                echo "===== Ignoring $path"
            fi
        done
        return 0
    fi

    #   Single-repo fetch
    #
    ( set -o pipefail   # in subshell only, so we don't affect user's value
      #     git-fetch does not produce the annoying 'remote: ...' and
      #     'Unpacking objects: ...' lines when stderr is not a terminal,
      #     so we need only join the 'Fetching <remote-name>' to a following
      #     'From <remote-URL>' line, if the latter is present.
      git fetch $allarg "$@" 2>&1 \
        | tr '\n' '\0' | sed -e '
           #p;d     # debug: ignore all code below and show original input

            #   WARNING: This must be tested with both multiple remotes in
            #   one fetch (a group or --all), which produces "From
            #   <remote>" lines, and a single remote, which does not.
            #   Currently the latter produces the "From" line as the first
            #   line, so with no leading newline/NUL the join below will
            #   not take effect.

            #   `tr` has changed all the newlines to NULs, so that we can
            #   detect "Fetching ...", "From ..." pairs. (This cannot be
            #   handled in regular line-mode sed because it cannot deal
            #   with possible "Fetching...", "Fetching..." pairs.)

            s/\x00From / from /g            # "\nFrom" always joins w/prev line
            s/\x00/\n/g                     # restore all original newlines
            '
    ) || return
    git status -bs
}; copy_git_completion fetch git fetch

pfetch() { fetch --prune --prune-tags "$@"; }
copy_git_completion pfetch git fetch

pull()  { git pull --ff-only "$@"; }; copy_git_completion pull git pull

# Disallow use of -f and --force. If `pushf` doesn't work for you, you
# can use `git push --force`.
#
push()          {
    for i in "$@"; do case "$i" in
        -f)      echo 1>&2 "Do not use -f option, use pushf"; return 1;;
        --force) echo 1>&2 "Do not use --force option, use pushf"; return 1;;
    esac; done
    git push "$@";
}; copy_git_completion push git push

pushf()         {
    for i in "$@"; do case "$i" in
        -f) echo 1>&2 "Do not use -f option, use --force"; return 1;;
    esac; done
    git push --force-with-lease "$@";
}; copy_git_completion pushf git push

# Create upstream branch in given remote.
# This will unset any current upstream, if present.
# XXX This should be able to figure out a default remote.
#
pushu()         {
    # XXX This doesn't properly handle arguments before the <remote>
    [ -z "$1" ] && { echo 1>&2 "Usage: pushu <remote> [<branch>]"; return 2; }
    local -a argv=("$1"); shift
    [ -z "$1" ] && argv+=($(git rev-parse --abbrev-ref=strict HEAD))
    for i in "$@"; do argv+=("$i"); done
    git branch --unset-upstream 2>/dev/null || true
    push --set-upstream "${argv[@]}"
}; copy_git_completion pushu git push

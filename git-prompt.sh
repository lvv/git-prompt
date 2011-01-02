
        # don't set prompt if this is not interactive shell
        [[ $- != *i* ]]  &&  return

###################################################################   CONFIG

        #####  read config file if any.

        unset   dir_color rc_color user_id_color root_id_color init_vcs_color clean_vcs_color
        unset modified_vcs_color added_vcs_color addmoded_vcs_color untracked_vcs_color op_vcs_color detached_vcs_color

        conf=git-prompt.conf;                   [[ -r $conf ]]  && . $conf
        conf=/etc/git-prompt.conf;              [[ -r $conf ]]  && . $conf
        conf=~/.git-prompt.conf;                [[ -r $conf ]]  && . $conf
        conf=~/.config/git-prompt.conf;         [[ -r $conf ]]  && . $conf
        unset conf

        #####  set defaults if not set

        git_module=${git_module:-on}
        svn_module=${svn_module:-off}
        hg_module=${hg_module:-on}
        vim_module=${vim_module:-on}
        error_bell=${error_bell:-off}
        cwd_cmd=${cwd_cmd:-\\w}


        #### dir, rc, root color
        cols=`tput colors`                              # in emacs shell-mode tput colors returns -1
        if [[ -n "$cols" && $cols -ge 8 ]];  then       #  if terminal supports colors
                dir_color=${dir_color:-CYAN}
                rc_color=${rc_color:-red}
                user_id_color=${user_id_color:-blue}
                root_id_color=${root_id_color:-magenta}
        else                                            #  only B/W
                dir_color=${dir_color:-bw_bold}
                rc_color=${rc_color:-bw_bold}
        fi
        unset cols

	#### prompt character, for root/non-root
	prompt_char=${prompt_char:-'>'}
	root_prompt_char=${root_prompt_char:-'>'}

        #### vcs state colors
                 init_vcs_color=${init_vcs_color:-WHITE}        # initial
                clean_vcs_color=${clean_vcs_color:-blue}        # nothing to commit (working directory clean)
             modified_vcs_color=${modified_vcs_color:-red}      # Changed but not updated:
                added_vcs_color=${added_vcs_color:-green}       # Changes to be committed:
             addmoded_vcs_color=${addmoded_vcs_color:-yellow}
            untracked_vcs_color=${untracked_vcs_color:-BLUE}    # Untracked files:
                   op_vcs_color=${op_vcs_color:-MAGENTA}
             detached_vcs_color=${detached_vcs_color:-RED}

        max_file_list_length=${max_file_list_length:-100}
        upcase_hostname=${upcase_hostname:-on}

        aj_max=20
        timer_starts_at=10


#####################################################################  post config

        ################# make PARSE_VCS_STATUS
        unset PARSE_VCS_STATUS
        [[ $git_module = "on" ]]   &&   type git >&/dev/null   &&   PARSE_VCS_STATUS+="parse_git_status"
        [[ $svn_module = "on" ]]   &&   type svn >&/dev/null   &&   PARSE_VCS_STATUS+="${PARSE_VCS_STATUS+||}parse_svn_status"
        [[ $hg_module  = "on" ]]   &&   type hg  >&/dev/null   &&   PARSE_VCS_STATUS+="${PARSE_VCS_STATUS+||}parse_hg_status"
                                                                    PARSE_VCS_STATUS+="${PARSE_VCS_STATUS+||}return"
        ################# terminfo colors-16
        #
        #       black?    0 8
        #       red       1 9
        #       green     2 10
        #       yellow    3 11
        #       blue      4 12
        #       magenta   5 13
        #       cyan      6 14
        #       white     7 15
        #
        #       terminfo setaf/setab - sets ansi foreground/background
        #       terminfo sgr0 - resets all attributes
        #       terminfo colors - number of colors
        #
        #################  Colors-256
        #  To use foreground and background colors:
        #       Set the foreground color to index N:    \033[38;5;${N}m
        #       Set the background color to index M:    \033[48;5;${M}m
        # To make vim aware of a present 256 color extension, you can either set
        # the $TERM environment variable to xterm-256color or use vim's -T option
        # to set the terminal. I'm using an alias in my bashrc to do this. At the
        # moment I only know of two color schemes which is made for multi-color
        # terminals like urxvt (88 colors) or xterm: inkpot and desert256,

        ### if term support colors,  then use color prompt, else bold

              black='\['`tput sgr0; tput setaf 0`'\]'
                red='\['`tput sgr0; tput setaf 1`'\]'
              green='\['`tput sgr0; tput setaf 2`'\]'
             yellow='\['`tput sgr0; tput setaf 3`'\]'
               blue='\['`tput sgr0; tput setaf 4`'\]'
            magenta='\['`tput sgr0; tput setaf 5`'\]'
               cyan='\['`tput sgr0; tput setaf 6`'\]'
              white='\['`tput sgr0; tput setaf 7`'\]'

              BLACK='\['`tput setaf 0; tput bold`'\]'
                RED='\['`tput setaf 1; tput bold`'\]'
              GREEN='\['`tput setaf 2; tput bold`'\]'
             YELLOW='\['`tput setaf 3; tput bold`'\]'
               BLUE='\['`tput setaf 4; tput bold`'\]'
            MAGENTA='\['`tput setaf 5; tput bold`'\]'
               CYAN='\['`tput setaf 6; tput bold`'\]'  # why 14 doesn't work?
              WHITE='\['`tput setaf 7; tput bold`'\]'

            bw_bold='\['`tput bold`'\]'

        on=''
        off=': '
        bell="\[`eval ${!error_bell} tput bel`\]"
        colors_reset='\['`tput sgr0`'\]'

        # replace symbolic colors names to raw treminfo strings
                 init_vcs_color=${!init_vcs_color}
             modified_vcs_color=${!modified_vcs_color}
            untracked_vcs_color=${!untracked_vcs_color}
                clean_vcs_color=${!clean_vcs_color}
                added_vcs_color=${!added_vcs_color}
                   op_vcs_color=${!op_vcs_color}
             addmoded_vcs_color=${!addmoded_vcs_color}
             detached_vcs_color=${!detached_vcs_color}

        unset PROMPT_COMMAND

        #######  work around for MC bug.
        #######  specifically exclude emacs, want full when running inside emacs
        if   [[ -z "$TERM"   ||  ("$TERM" = "dumb" && -z "$INSIDE_EMACS")  ||  -n "$MC_SID" ]];   then
                unset PROMPT_COMMAND
                PS1="\w$prompt_char "
                return 0
        fi

        ####################################################################  MARKERS
        screen_marker="sCRn"
        if [[ $LC_CTYPE =~ "UTF" && $TERM != "linux" ]];  then
                elipses_marker="…"
        else
                elipses_marker="..."
        fi

        export who_where


cwd_truncate() {
        # based on:   https://www.blog.montgomerie.net/pwd-in-the-title-bar-or-a-regex-adventure-in-bash

        # arg1: max path lenght
        # returns abbrivated $PWD  in public "cwd" var

        cwd=${PWD/$HOME/\~}             # substitute  "~"

        case $1 in
                full)
                        return
                        ;;
                last)
                        cwd=${PWD##/*/}
                        [[ $PWD == $HOME ]]  &&  cwd="~"
                        return
                        ;;
                *)
                        # if bash < v3.2  then don't truncate
			if [[  ${BASH_VERSINFO[0]} -eq 3   &&   ${BASH_VERSINFO[1]} -le 1  || ${BASH_VERSINFO[0]} -lt 3 ]] ;  then
				return
			fi
                        ;;
        esac

        # split path into:  head='~/',  truncateble middle,  last_dir

        local cwd_max_length=$1
        # expression which bash-3.1 or older can not understand, so we wrap it in eval
        exp31='[[ "$cwd" =~ (~?/)(.*/)([^/]*)$ ]]'
        if  eval $exp31 ;  then  # only valid if path have more then 1 dir
                local path_head=${BASH_REMATCH[1]}
                local path_middle=${BASH_REMATCH[2]}
                local path_last_dir=${BASH_REMATCH[3]}

                local cwd_middle_max=$(( $cwd_max_length - ${#path_last_dir} ))
                [[ $cwd_middle_max < 0  ]]  &&  cwd_middle_max=0


		# trunc middle if over limit
                if   [[ ${#path_middle}   -gt   $(( $cwd_middle_max + ${#elipses_marker} + 5 )) ]];   then
			
			# truncate
			middle_tail=${path_middle:${#path_middle}-${cwd_middle_max}}

			# trunc on dir boundary (trunc 1st, probably tuncated dir)
			exp31='[[ $middle_tail =~ [^/]*/(.*)$ ]]'
			eval $exp31
			middle_tail=${BASH_REMATCH[1]}

			# use truncated only if we cut at least 4 chars
			if [[ $((  ${#path_middle} - ${#middle_tail}))  -gt 4  ]];  then
				cwd=$path_head$elipses_marker$middle_tail$path_last_dir
			fi
                fi
        fi
        return
 }


set_shell_label() {

        xterm_label() { echo  -n "]2;${@}" ; }   # FIXME: replace hardcodes with terminfo codes

        screen_label() {
                # FIXME: run this only if screen is in xterm (how to test for this?)
                xterm_label  "$screen_marker  $plain_who_where $@"

                # FIXME $STY not inherited though "su -"
                [ "$STY" ] && screen -S $STY -X title "$*"
        }

        case $TERM in

                screen*)
                        screen_label "$*"
                        ;;

                xterm* | rxvt* | gnome-terminal | konsole | eterm | wterm )
                        # is there a capability which we can to test
                        # for "set term title-bar" and its escapes?
                        xterm_label  "$plain_who_where $@"
                        ;;

                *)
                        ;;
        esac
 }

    export -f set_shell_label

###################################################### ID (user name)
        id=`id -un`
        id=${id#$default_user}

########################################################### TTY
        tty=`tty`
        tty=`echo $tty | sed "s:/dev/pts/:p:; s:/dev/tty::" `           # RH tty devs
        tty=`echo $tty | sed "s:/dev/vc/:vc:" `                         # gentoo tty devs

        if [[ "$TERM" = "screen" ]] ;  then

                #       [ "$WINDOW" = "" ] && WINDOW="?"
                #
                #               # if under screen then make tty name look like s1-p2
                #               # tty="${WINDOW:+s}$WINDOW${WINDOW:+-}$tty"
                #       tty="${WINDOW:+s}$WINDOW"  # replace tty name with screen number
                tty="$WINDOW"  # replace tty name with screen number
        fi

        # we don't need tty name under X11
        case $TERM in
                xterm* | rxvt* | gnome-terminal | konsole | eterm | wterm )  unset tty ;;
                *);;
        esac

        dir_color=${!dir_color}
        rc_color=${!rc_color}
        user_id_color=${!user_id_color}
        root_id_color=${!root_id_color}

        ########################################################### HOST
        ### we don't display home host/domain  $SSH_* set by SSHD or keychain

        # How to find out if session is local or remote? Working with "su -", ssh-agent, and so on ?

        ## is sshd our parent?
        # if    { for ((pid=$$; $pid != 1 ; pid=`ps h -o pid --ppid $pid`)); do ps h -o command -p $pid; done | grep -q sshd && echo == REMOTE ==; }
        #then

        host=${HOSTNAME}
        #host=`hostname --short`
        host=${host#$default_host}
        uphost=`echo ${host} | tr a-z A-Z`
        if [[ $upcase_hostname = "on" ]]; then
                host=${uphost}
        fi

        host_color=${uphost}_host_color
        host_color=${!host_color}
        if [[ -z $host_color && -x /usr/bin/cksum ]] ;  then
                cksum_color_no=`echo $uphost | cksum  | awk '{print $1%7}'`
                color_index=(green yellow blue magenta cyan white)              # FIXME:  bw,  color-256
                host_color=${color_index[cksum_color_no]}
        fi

        host_color=${!host_color}

        # we might already have short host name
        host=${host%.$default_domain}


#################################################################### WHO_WHERE
        #  [[user@]host[-tty]]

        if [[ -n $id  || -n $host ]] ;   then
                [[ -n $id  &&  -n $host ]]  &&  at='@'  || at=''
                color_who_where="${id}${host:+$host_color$at$host}${tty:+ $tty}"
                plain_who_where="${id}$at$host"

                # add trailing " "
                color_who_where="$color_who_where "
                plain_who_where="$plain_who_where "

                # if root then make it root_color
                if [ "$id" == "root" ]  ; then
                        user_id_color=$root_id_color
                        prompt_char="$root_prompt_char"
                fi
                color_who_where="$user_id_color$color_who_where$colors_reset"
        else
                color_who_where=''
        fi


parse_svn_status() {

        [[   -d .svn  ]] || return 1

        vcs=svn

        ### get rev
        eval `
            svn info |
                sed -n "
                    s@^URL[^/]*//@repo_dir=@p
                    s/^Revision: /rev=/p
                "
        `
        ### get status

        unset status modified added clean init added mixed untracked op detached
        eval `svn status 2>/dev/null |
                sed -n '
                    s/^A...    \([^.].*\)/modified=modified;             modified_files[${#modified_files[@]}]=\"\1\";/p
                    s/^M...    \([^.].*\)/modified=modified;             modified_files[${#modified_files[@]}]=\"\1\";/p
                    s/^\?...    \([^.].*\)/untracked=untracked;  untracked_files[${#untracked_files[@]}]=\"\1\";/p
                '
        `
        # TODO branch detection if standard repo layout

        [[  -z $modified ]]   &&  [[ -z $untracked ]]  &&  clean=clean
        vcs_info=svn:r$rev
 }

parse_hg_status() {

        # ☿

        [[  -d ./.hg/ ]]  ||  return  1

        vcs=hg

        ### get status
        unset status modified added clean init added mixed untracked op detached

        eval `hg status 2>/dev/null |
                sed -n '
                        s/^M \([^.].*\)/modified=modified; modified_files[${#modified_files[@]}]=\"\1\";/p
                        s/^A \([^.].*\)/added=added; added_files[${#added_files[@]}]=\"\1\";/p
                        s/^R \([^.].*\)/added=added;/p
                        s/^! \([^.].*\)/modified=modified;/p
                        s/^? \([^.].*\)/untracked=untracked; untracked_files[${#untracked_files[@]}]=\\"\1\\";/p
        '`

        branch=`hg branch 2> /dev/null`

        [[ -z $modified ]]   &&   [[ -z $untracked ]]   &&   [[ -z $added ]]   &&   clean=clean
        vcs_info=${branch/default/D}
 }


parse_git_complete() {
        if [ "${BASH_VERSION%.*}" \< "3.0" ]; then
                # echo "You will need to upgrade 'bash' to version 3.0 \
                # for full programmable completion features (bash complete) \
                # Please install bash-completion packet like: $ yum -y install bash-completion"
                return
        fi

        complete -f -W "$(
                echo `git branch -a | sed -e s/[\ \*]//g | cut -f 1 -d ' ' | uniq`; \
                echo `git remote | sed -e s/[\ \*]//g | cut -f 1 -d ' ' | uniq`; \
                echo `git | tail -23 | head -21 | cut -d ' ' -f 4`; \
                echo '--help'; \
                echo '--staged'; \
                echo 'remote'; \
                echo 'help'; \
        )" g git
}

parse_git_status() {

        # TODO add status: LOCKED (.git/index.lock)

        git_dir=`[[ $git_module = "on" ]]  &&  git rev-parse --git-dir 2> /dev/null`
        #git_dir=`eval \$$git_module  git rev-parse --git-dir 2> /dev/null`
        #git_dir=` git rev-parse --git-dir 2> /dev/null`

        [[  -n ${git_dir/./} ]]   ||   return  1

        vcs=git
        parse_git_complete

        ##########################################################   GIT STATUS
	file_regex='\([^/]*\/\{0,1\}\).*'
	added_files=()
	modified_files=()
	untracked_files=()
        unset branch status modified added clean init added mixed untracked op detached

	# quoting hell
        eval " $(
                git status 2>/dev/null |
                    sed -n '
                        s/^# On branch /branch=/p
                        s/^nothing to commit (working directory clean)/clean=clean/p
                        s/^# Initial commit/init=init/p

                        /^# Changes to be committed:/,/^# [A-Z]/ {
                            s/^# Changes to be committed:/added=added;/p

                            s/^#	modified:   '"$file_regex"'/	[[ \" ${added_files[*]} \" =~ \" \1 \" ]] || added_files[${#added_files[@]}]=\"\1\"/p
                            s/^#	new file:   '"$file_regex"'/	[[ \" ${added_files[*]} \" =~ \" \1 \" ]] || added_files[${#added_files[@]}]=\"\1\"/p
                            s/^#	renamed:[^>]*> '"$file_regex"'/	[[ \" ${added_files[*]} \" =~ \" \1 \" ]] || added_files[${#added_files[@]}]=\"\1\"/p
                            s/^#	copied:[^>]*> '"$file_regex"'/ 	[[ \" ${added_files[*]} \" =~ \" \1 \" ]] || added_files[${#added_files[@]}]=\"\1\"/p
                        }

                        /^# Changed but not updated:/,/^# [A-Z]/ {
                            s/^# Changed but not updated:/modified=modified;/p
                            s/^#	modified:   '"$file_regex"'/	[[ \" ${modified_files[*]} \" =~ \" \1 \" ]] || modified_files[${#modified_files[@]}]=\"\1\"/p
                            s/^#	unmerged:   '"$file_regex"'/	[[ \" ${modified_files[*]} \" =~ \" \1 \" ]] || modified_files[${#modified_files[@]}]=\"\1\"/p
                        }

                        /^# Untracked files:/,/^[^#]/{
                            s/^# Untracked files:/untracked=untracked;/p
                            s/^#	'"$file_regex"'/		[[ \" ${untracked_files[*]} ${modified_files[*]} ${added_files[*]} \" =~ \" \1 \" ]] || untracked_files[${#untracked_files[@]}]=\"\1\"/p
                        }
                    '
        )"

        if  ! grep -q "^ref:" $git_dir/HEAD  2>/dev/null;   then
                detached=detached
        fi


        #################  GET GIT OP

        unset op

        if [[ -d "$git_dir/.dotest" ]] ;  then

                if [[ -f "$git_dir/.dotest/rebasing" ]] ;  then
                        op="rebase"

                elif [[ -f "$git_dir/.dotest/applying" ]] ; then
                        op="am"

                else
                        op="am/rebase"

                fi

        elif  [[ -f "$git_dir/.dotest-merge/interactive" ]] ;  then
                op="rebase -i"
                # ??? branch="$(cat "$git_dir/.dotest-merge/head-name")"

        elif  [[ -d "$git_dir/.dotest-merge" ]] ;  then
                op="rebase -m"
                # ??? branch="$(cat "$git_dir/.dotest-merge/head-name")"

        # lvv: not always works. Should  ./.dotest  be used instead?
        elif  [[ -f "$git_dir/MERGE_HEAD" ]] ;  then
                op="merge"
                # ??? branch="$(git symbolic-ref HEAD 2>/dev/null)"

        elif  [[ -f "$git_dir/index.lock" ]] ;  then
                op="locked"

        else
                [[  -f "$git_dir/BISECT_LOG"  ]]   &&  op="bisect"
                # ??? branch="$(git symbolic-ref HEAD 2>/dev/null)" || \
                #    branch="$(git describe --exact-match HEAD 2>/dev/null)" || \
                #    branch="$(cut -c1-7 "$git_dir/HEAD")..."
        fi


        ####  GET GIT HEX-REVISION
        rawhex=`git rev-parse HEAD 2>/dev/null`
        rawhex=${rawhex/HEAD/}
        rawhex=${rawhex:0:6}

        #### branch
        branch=${branch/master/M}

                        # another method of above:
                        # branch=$(git symbolic-ref -q HEAD || { echo -n "detached:" ; git name-rev --name-only HEAD 2>/dev/null; } )
                        # branch=${branch#refs/heads/}

        ### compose vcs_info

        if [[ $init ]];  then 
                vcs_info=${white}init

        else
                if [[ "$detached" ]] ;  then
                        branch="<detached:`git name-rev --name-only HEAD 2>/dev/null`"


                elif   [[ "$op" ]];  then
                        branch="$op:$branch"
                        if [[ "$op" == "merge" ]] ;  then
                            branch+="<--$(git name-rev --name-only $(<$git_dir/MERGE_HEAD))"
                        fi
                        #branch="<$branch>"
                fi
                vcs_info="$branch$white=$rawhex"

        fi
 }


parse_vcs_status() {

        unset   file_list modified_files untracked_files added_files
        unset   vcs vcs_info
        unset   status modified untracked added init detached
        unset   file_list modified_files untracked_files added_files

        [[ $vcs_ignore_dir_list =~ $PWD ]] && return

        eval   $PARSE_VCS_STATUS


        ### status:  choose primary (for branch color)
        unset status
        status=${op:+op}
        status=${status:-$detached}
        status=${status:-$clean}
        status=${status:-$modified}
        status=${status:-$added}
        status=${status:-$untracked}
        status=${status:-$init}
                                # at least one should be set
                                : ${status?prompt internal error: git status}
        eval vcs_color="\${${status}_vcs_color}"
                                # no def:  vcs_color=${vcs_color:-$WHITE}    # default


        ### VIM

        if  [[ $vim_module = "on" ]] ;  then
                # equivalent to vim_glob=`ls .*.vim`  but without running ls
                unset vim_glob vim_file vim_files
                old_nullglob=`shopt -p nullglob`
                    shopt -s nullglob
                    vim_glob=`echo .*.sw?`
                eval $old_nullglob

                if [[ $vim_glob ]];  then
                    vim_file=${vim_glob#.}
                    vim_file=${vim_file/.sw?/}
                    # if swap is newer,  then this is unsaved vim session
                    #[[ .${vim_file}.swp -nt $vim_file ]]  && vim_files=$vim_file
                    # [temoto custom] if swap is older, then it must be deleted, so show all swaps.
                    vim_files=$vim_file
                fi
        fi


        ### file list
        unset file_list
        [[ ${added_files[0]}     ]]  &&  file_list+=" "$added_vcs_color${added_files[@]}
        [[ ${modified_files[0]}  ]]  &&  file_list+=" "$modified_vcs_color${modified_files[@]}
        [[ ${untracked_files[0]} ]]  &&  file_list+=" "$untracked_vcs_color${untracked_files[@]}
        [[ ${vim_files}          ]]  &&  file_list+=" "${RED}vim:${vim_files}
        file_list=${file_list:+:$file_list}

        if [[ ${#file_list} -gt $max_file_list_length ]]  ;  then
                file_list=${file_list:0:$max_file_list_length}
                if [[ $max_file_list_length -gt 0 ]]  ;  then
                        file_list="${file_list% *} $elipses_marker"
                fi
        fi


        head_local="(${vcs_info}$vcs_color${file_list}$vcs_color)"

        ### fringes
        head_local="${head_local+$vcs_color$head_local }"
        #above_local="${head_local+$vcs_color$head_local\n}"
        #tail_local="${tail_local+$vcs_color $tail_local}${dir_color}"
 }

# this is stolen from http://www.twistedmatrix.com/users/glyph/preexec.bash.txt
# do nothing we could do in the trap hook directly
preexec_invoke_exec () {
        if [[ -z "$preexec_interactive_mode" ]]
        then
                # We're doing something related to displaying the prompt.  Let the
                # prompt set the title instead of me.
                return
        else
                # If we're in a subshell, then the prompt won't be re-displayed to put
                # us back into interactive mode, so let's not set the variable back.
                # In other words, if you have a subshell like
                #   (sleep 1; sleep 2)
                # You want to see the 'sleep 2' as a set_command_title as well.
                if [[ 0 -eq "$BASH_SUBSHELL" ]]
                then
                        preexec_interactive_mode=""
                fi
        fi
        if [[ "prompt_command_function" == "$BASH_COMMAND" ]]
        then
                # Sadly, there's no cleaner way to detect two prompts being displayed
                # one after another.  This makes it important that PROMPT_COMMAND
                # remain set _exactly_ as below in preexec_install.  Let's switch back
                # out of interactive mode and not trace any of the commands run in
                # precmd.

                # Given their buggy interaction between BASH_COMMAND and debug traps,
                # versions of bash prior to 3.1 can't detect this at all.
                preexec_interactive_mode=""
                return
        fi

        # In more recent versions of bash, this could be set via the "BASH_COMMAND"
        # variable, but using history here is better in some ways: for example, "ps
        # auxf | less" will show up with both sides of the pipe if we use history,
        # but only as "ps auxf" if not.
        local this_command=`history 1 | sed -e "s/^[ ]*[0-9]*[ ]*//g"`;

        # If none of the previous checks have earlied out of this function, then
        # the command is in fact interactive and we should invoke the user's
        # preexec hook with the running command as an argument.
        if [[ -n "$this_command" ]] ; then
                    preexec_command_function "$this_command"
        fi
 }

disable_preexec_command_function() {
        trap - DEBUG  >& /dev/null
 }


# register a preexec hook eg to show currently executed command in label
enable_preexec_command_function() {
        disable_preexec_command_function
        
        trap '[[ -z "$COMP_LINE"  ]] && preexec_invoke_exec' DEBUG  >& /dev/null
 }

# autojump (see http://wiki.github.com/joelthelion/autojump)
j (){
        : ${1? usage: j dir-beginning}
        # go in ring buffer starting from current index.  cd to first matching dir
        for (( i=(aj_idx+1)%aj_max;   i != aj_idx%aj_max;  i=++i%aj_max )) ; do
                #echo == ${aj_dir_list[$i]} == $i
                if [[ ${aj_dir_list[$i]} =~ ^.*/$1[^/]*$ ]] ; then
                        cd "${aj_dir_list[$i]}"
                        return
                fi
        done
        echo '?'
}

alias jumpstart='echo ${aj_dir_list[@]}'

###################################################################### PROMPT_COMMAND

preexec_interactive_mode=""
prompt_command_function() {
        timer_stop
        preexec_interactive_mode="yes"

        rc="$?"

        if [[ "$rc" == "0" ]]; then
                rc=""
        else
                rc="$rc_color$rc$colors_reset$bell "
        fi

        cwd=${PWD/$HOME/\~}                     # substitute  "~"
        set_shell_label "${cwd##[/~]*/}/"       # default label - path last dir

        parse_vcs_status

        # autojump
        if [[ ${aj_dir_list[aj_idx%aj_max]} != $PWD ]] ; then
              aj_dir_list[++aj_idx%aj_max]="$PWD"
        fi

        # if cwd_cmd have back-slash, then assign it value to cwd
        # else eval cwd_cmd,  cwd should have path after exection
        eval "${cwd_cmd/\\/cwd=\\\\}"

        PS1="$colors_reset$rc$head_local$color_who_where$dir_color$cwd$tail_local$dir_color$prompt_char $colors_reset"

        unset head_local tail_local pwd
}

timer_start() {
        export TIMER_COMMAND="$1"
        export TIMER_STARTED_AT=$(date +'%s')
}

timer_stop() {
        local stopped_at=$(date +'%s')
        local started_at=${TIMER_STARTED_AT:-$stopped_at}
        let elapsed=$stopped_at-$started_at
        local min=${TIMER_STARTS_AT:-${timer_starts_at:-10}}
        if [ $elapsed -gt $min ]; then
                timer_message
        fi
        export TIMER_COMMAND=""
}

timer_message() {
        local stamper=''
        if [ $elapsed -gt 60 ] ; then
                if [ $elapsed -gt 3600 ] ; then
                        stamper="%-Hh, %-Mm, %-Ss"
                else
                        stamper="%-Mm, %-Ss"
                fi
        else
                stamper="%-S seconds"
        fi
        local message="took $(date -d "@$elapsed" +"$stamper")"

        # decide which status to use
        if [ "$?" == "0" ] ; then
            result="completed"
        else
            result="FAILED ($status)"
        fi
        local title="$TIMER_COMMAND $result"


        if type -P notify-send >&/dev/null ; then
                notify-send -i terminal "$title" "$message" &
        fi
        if type -P growlnotify >&/dev/null ; then
                growlnotify -s "$title" -m "$message"  &
        fi
}

preexec_command_function() {
        local this_command="$1"

        set_shell_label "$this_command"
        timer_start "$this_command"
}


        PROMPT_COMMAND="prompt_command_function"

        enable_preexec_command_function

        unset rc id tty modified_files file_list

# vim: set ft=sh ts=8 sw=8 et:

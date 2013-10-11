        # don't set prompt if this is not interactive shell
        [[ $- != *i* ]]  &&  return

###################################################################   CONFIG

        #####  read config file if any.

        unset make_color_ok make_color_dirty jobs_color_bkg jobs_color_stop slash_color at_color at_color_remote
        unset dir_color rc_color user_id_color root_id_color init_vcs_color clean_vcs_color
        unset modified_vcs_color added_vcs_color untracked_vcs_color deleted_vcs_color op_vcs_color detached_vcs_color hex_vcs_color
        unset rawhex_len

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
        virtualenv_module=${virtualenv_module:-on}
        battery_module=${battery_module:-off}
        make_module=${make_module:-off}
        jobs_module=${jobs_module:-on}
        rc_module=${rc_module:-on}
        error_bell=${error_bell:-off}
        cwd_cmd=${cwd_cmd:-\\w}

        default_host_abbrev_mode=${default_host_abbrev_mode:-delete}
        default_id_abbrev_mode=${default_id_abbrev_mode:-delete}

        prompt_modules_order=${prompt_modules_order:-RC VIRTUALENV VCS WHO_WHERE JOBS BATTERY CWD MAKE}

        #### check for acpi, make, disable corresponding module if not installed
        if [[ -z $(which acpi 2> /dev/null) || -z $(acpi -b) ]]; then
            battery_module=off
        fi
        if [[ -z $(which make 2> /dev/null) ]]; then
            make_module=off
        fi

        #### dir, rc, root color
        cols=`tput colors`                              # in emacs shell-mode tput colors returns -1
        if [[ -n "$cols" && $cols -ge 8 ]];  then       #  if terminal supports colors
                dir_color=${dir_color:-CYAN}
                slash_color=${slash_color:-CYAN}
                prompt_color=${prompt_color:-white}
                rc_color=${rc_color:-red}
                virtualenv_color=${virtualenv_color:-green}
                user_id_color=${user_id_color:-blue}
                root_id_color=${root_id_color:-magenta}
                at_color=${at_color:-green}
                at_color_remote=${at_color_remote:-RED}
                jobs_color_bkg=${jobs_color:-yellow}
                jobs_color_stop=${jobs_color:-red}
                make_color_ok=${make_color_ok:-BLACK}
                make_color_dirty=${make_color_dirty:-RED}

        else                                            #  only B/W
                dir_color=${dir_color:-bw_bold}
                rc_color=${rc_color:-bw_bold}
        fi
        unset cols

	#### prompt character, for root/non-root
	prompt_char=${prompt_char:-'>'}
	root_prompt_char=${root_prompt_char:-'>'}

        #### vcs colors
                 init_vcs_color=${init_vcs_color:-WHITE}        # initial
                clean_vcs_color=${clean_vcs_color:-blue}        # nothing to commit (working directory clean)
             modified_vcs_color=${modified_vcs_color:-red}      # Changed but not updated:
                added_vcs_color=${added_vcs_color:-green}       # Changes to be committed:
            untracked_vcs_color=${untracked_vcs_color:-BLUE}    # Untracked files:
              deleted_vcs_color=${deleted_vcs_color:-yellow}    # Deleted files:
                   op_vcs_color=${op_vcs_color:-MAGENTA}
             detached_vcs_color=${detached_vcs_color:-RED}

                  hex_vcs_color=${hex_vcs_color:-BLACK}         # gray


        max_file_list_length=${max_file_list_length:-100}
        short_hostname=${short_hostname:-off}
        upcase_hostname=${upcase_hostname:-on}
        count_only=${count_only:-off}
        rawhex_len=${rawhex_len:-5}
        hg_revision_display=${hg_revision_display:-none}
        hg_multiple_heads_display=${hg_multiple_heads_display:-on}


        aj_max=20


#####################################################################  post config

        ################# make PARSE_VCS_STATUS
        unset PARSE_VCS_STATUS
        [[ $git_module = "on" ]]   &&   type git >&/dev/null   &&   PARSE_VCS_STATUS+="parse_git_status"
        [[ $svn_module = "on" ]]   &&   type svn >&/dev/null   &&   PARSE_VCS_STATUS+="${PARSE_VCS_STATUS+||}parse_svn_status"
        [[ $hg_module  = "on" ]]   &&   type hg  >&/dev/null   &&   PARSE_VCS_STATUS+="${PARSE_VCS_STATUS+||}parse_hg_status"
                                                                    PARSE_VCS_STATUS+="${PARSE_VCS_STATUS+||}return"

        ### determining svn version information
        ### In svn versions 1.7 and above there is only a single .svn directory
        ### in the repository root, while before there was a .svn in every subdirectory.
        ### Here we determine and save svn version information 
        ### and use the appropriate method in the runtime module
        if [[ $PARSE_VCS_STATUS =~ "svn" ]]; then
            svn_version_str=$(svn --version 2> /dev/null | head -1 | sed -ne 's/.* \([0-9]\)\.\([0-9]\{1,2\}\).*/\1\2/p')
            if [[ $svn_version_str > 16 ]]; then
                svn_use_info=1
            else
                svn_use_info=
            fi
            unset svn_version_str
        fi

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
               CYAN='\['`tput setaf 6; tput bold`'\]'
              WHITE='\['`tput setaf 7; tput bold`'\]'

              whiteonred='\['`tput setaf 7; tput setab 1; tput bold`'\]'

                dim='\['`tput sgr0; tput setaf p1`'\]'  # half-bright

            bw_bold='\['`tput bold`'\]'

        on=''
        off=': '
        bell="\[`eval ${!error_bell} tput bel`\]"
        colors_reset='\['`tput sgr0`'\]'

        # replace symbolic colors names to raw terminfo strings
                 init_vcs_color=${!init_vcs_color}
             modified_vcs_color=${!modified_vcs_color}
            untracked_vcs_color=${!untracked_vcs_color}
                clean_vcs_color=${!clean_vcs_color}
                added_vcs_color=${!added_vcs_color}
                   op_vcs_color=${!op_vcs_color}
             detached_vcs_color=${!detached_vcs_color}
              deleted_vcs_color=${!deleted_vcs_color}
                  hex_vcs_color=${!hex_vcs_color}

        unset PROMPT_COMMAND

        # assemble prompt command string based on the module order specified above

        # RC, VIRTUALENV and VCS has to be flanked by spaces on either side
        # except if they are at the start or end of the sequence.
        # excess spaces (which may occur if some of the modules produce empty output)
        # will be trimmed at runtime, in the prompt_command_function.

        prompt_command_string=$(echo $prompt_modules_order |
            sed '
                s/RC/\$space\$rc\$space/;
                s/VIRTUALENV/\$space\$virtualenv_string\$space/;
                s/VCS/\$space\$head_local\$space/;
                s/WHO_WHERE/\$color_who_where\$colors_reset/;
                s/JOBS/\$jobs_indicator/;
                s/BATTERY/\$battery_indicator/;
                s/CWD/\$dir_color\$cwd/;
                s/MAKE/\$make_indicator/;
                s/ //g;
                s/\$space\$space/\$space/g;
                s/^\$space//;
                s/\$space$//;
                s/\$space/ /g;
                ')

        ####################################################################  MARKERS
        ellipse_marker_utf8="…"
        ellipse_marker_plain="..."
        if [[ ("$LC_CTYPE $LC_ALL $LANG" =~ "UTF" || $LANG =~ "utf") && $TERM != "linux" ]];  then
                utf8_prompt=1
                ellipse_marker=$ellipse_marker_utf8
        else
                utf8_prompt=
                ellipse_marker=$ellipse_marker_plain
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
                if   [[ ${#path_middle}   -gt   $(( $cwd_middle_max + ${#ellipse_marker} + 5 )) ]];   then

			# truncate
			middle_tail=${path_middle:${#path_middle}-${cwd_middle_max}}

			# trunc on dir boundary (trunc 1st, probably tuncated dir)
			exp31='[[ $middle_tail =~ [^/]*/(.*)$ ]]'
			eval $exp31
			middle_tail=${BASH_REMATCH[1]}

			# use truncated only if we cut at least 4 chars
			if [[ $((  ${#path_middle} - ${#middle_tail}))  -gt 4  ]];  then
				cwd=$path_head$ellipse_marker$middle_tail$path_last_dir
			fi
                fi
        fi
        return
 }


set_shell_label() {

        xterm_label() {
                local args="$*"
                printf "\033]0;%s\033\\" "${args:0:200}"
        }

        screen_label() {
		local param
		param="$plain_who_where $@"
		# workaround screen UTF-8 bug
		param=${param//$ellipse_marker/$ellipse_marker_plain}

                # FIXME: run this only if screen is in xterm (how to test for this?)
                xterm_label  "$param"

                # FIXME $STY not inherited though "su -"
                [ "$STY" ] && screen -S $STY -X title "$*"
        }
        if [[ -n "$STY" ]]; then
                screen_label "$*"
        else
                case $TERM in

                        screen*)
                                screen_label "$*"
                                ;;

                        xterm* | rxvt* | gnome-* | konsole | eterm | wterm )
                                # is there a capability which we can to test
                                # for "set term title-bar" and its escapes?
                                xterm_label  "$plain_who_where $@"
                                ;;

                        *)
                                ;;
                esac
        fi
 }

    export -f set_shell_label

###################################################### ID (user name)
        id=`id -un`

        # abbreviate user name if needed
        if   [[ "$default_id_abbrev_mode" == "delete" ]]
        then
            id=${id#$default_user}
        elif [[ "$default_id_abbrev_mode" == "abbrev" ]]
        then
            # only abbreviate if the abbreviated string is actually shorter than the full one
            if [[ "$id" == "$default_user" && ${#id} -ge $((${#ellipse_marker} + 1)) ]]
            then
                id="${id:0:1}$ellipse_marker"
            fi
        #else
            # keep full user name
        fi

########################################################### TTY
        tty=`tty`
        tty=`echo $tty | sed "s:/dev/pts/:p:; s:/dev/tty::" `           # RH tty devs
        tty=`echo $tty | sed "s:/dev/vc/:vc:" `                         # gentoo tty devs

        if [[ "$TERM" =~ "screen" ]] ;  then

                #       [ "$WINDOW" = "" ] && WINDOW="?"
                #
                #               # if under screen then make tty name look like s1-p2
                #               # tty="${WINDOW:+s}$WINDOW${WINDOW:+-}$tty"
                #       tty="${WINDOW:+s}$WINDOW"  # replace tty name with screen number
                tty="$WINDOW"  # replace tty name with screen number
        fi

        # we don't need tty name under X11
        case $TERM in
                xterm* | rxvt* | gnome-terminal | konsole | eterm* | wterm | cygwin)  unset tty ;;
                *);;
        esac

        dir_color=${!dir_color}
        slash_color=${!slash_color}
        prompt_color=${!prompt_color}
        rc_color=${!rc_color}
        virtualenv_color=${!virtualenv_color}
        user_id_color=${!user_id_color}
        root_id_color=${!root_id_color}

        ########################################################### HOST
        ### we don't display home host/domain  $SSH_* set by SSHD or keychain

        # How to find out if session is local or remote? Working with "su -", ssh-agent, and so on ?

        ## is sshd our parent?
        # if    { for ((pid=$$; $pid != 1 ; pid=`ps h -o pid --ppid $pid`)); do ps h -o command -p $pid; done | grep -q sshd && echo == REMOTE ==; }
        #then
        
        if [[ -n ${SSH_CLIENT} || -n ${SSH2_CLIENT} ]]; then
            probably_ssh_session=1
            at_color=$at_color_remote
        else
            probably_ssh_session=
        fi

        host=${HOSTNAME}
        if [[ $short_hostname = "on" ]]; then
			if [[ "$(uname)" =~ "CYGWIN" ]]; then
				host=`hostname`
			else
				host=`hostname -s`
			fi
        fi

        uphost=`echo ${host} | tr a-z-. A-Z_`

        host_color=${uphost}_host_color
        host_color=${!host_color}
        if [[ -z $host_color && -x /usr/bin/cksum ]] ;  then
                cksum_color_no=`echo $uphost | cksum  | awk '{print $1%6}'`
                color_index=(green yellow blue magenta cyan white)              # FIXME:  bw,  color-256
                host_color=${color_index[cksum_color_no]}
        fi

        # abbreviate host name if needed
        # disregard setting and display full host if session is remote
        if   [[ "$default_host_abbrev_mode" == "delete" && -z $probably_ssh_session ]]
        then
            host=${host#$default_host}
        elif [[ "$default_host_abbrev_mode" == "abbrev" && -z $probably_ssh_session ]]
        then
            # only abbreviate if the abbreviated string is actually shorter than the full one
            if [[ "$host" == "$default_host" && ${#host} -ge $((${#ellipse_marker} + 1)) ]]
            then
                host="${host:0:1}$ellipse_marker"
            fi
        else
            # set upcase hostname if needed
            if [[ $upcase_hostname = "on" ]]; then
                host=${uphost}
            fi
        fi

        at_color=${!at_color}
        host_color=${!host_color}

        # we might already have short host name
        host=${host%.$default_domain}

        unset probably_ssh_session

#################################################################### WHO_WHERE
        #  [[user@]host[-tty]]

        if [[ -n $id  || -n $host ]] ;   then
                [[ -n $id  &&  -n $host ]]  &&  at='@'  || at=''
                color_who_where="${id//\\/\\\\}${host:+$at_color$at$host_color$host}${tty:+ $tty}"
                plain_who_where="${id}$at$host"

                # if root then make it root_color
                if [ "$id" == "root" ]  ; then
                        user_id_color=$root_id_color
                        prompt_char="$root_prompt_char"
                fi

                color_who_where="$user_id_color$color_who_where$colors_reset"
        else
                color_who_where=''
        fi

        # There are at least two separate problems with mc:
        # it clobbers $PROMPT_COLOR, so none of the dynamically generated 
        # components can work,
        # and it swallows escape sequences, so colors don't work either.
        # Here we try to salvage some of the functionality for shells within mc.
        #
        # specifically exclude emacs, want full when running inside emacs
        if [[ -z "$TERM" || ("$TERM" = "dumb" && -z "$INSIDE_EMACS") || -n "$MC_SID" ]]; then
            unset PROMPT_COMMAND
            if [[ -n $id  || -n $host ]] ;   then
                PS1="$color_who_where:\w$prompt_char "
            else
                PS1="\w$prompt_char "
            fi
            return 0
        fi


create_battery_indicator () {
        # if not a laptop: :
        # if laptop on AC, not charging: ⚡ 
        # if laptop on AC, charging: ▕⚡▏
        # if laptop on battery: one of ▕▁▏▕▂▏▕▃▏▕▄▏▕▅▏▕▆▏▕▇▏▕█▏
        # color: red if power < 30 %, else normal

        local battery_string
        local battery_percent
        local battery_color
        local tmp
        battery_string=$(acpi -b)

        if [[ $battery_string ]]; then
            tmp=${battery_string%\%*}
            battery_percent=${tmp##* }
            if [[ "$battery_string" =~ "Discharging" ]]; then
                if [[ $utf8_prompt ]]; then
                    battery_diagrams=( ▕▁▏ ▕▂▏ ▕▃▏ ▕▄▏ ▕▅▏ ▕▆▏ ▕▇▏ ▕█▏ )
                    battery_pwr_index=$(($battery_percent/13))
                    battery_indicator=${battery_diagrams[battery_pwr_index]}
                else
                    battery_indicator="|$battery_percent|"
                fi
            elif [[ "$battery_string" =~ "Charging" ]]; then
                if [[ $utf8_prompt ]]; then
                    battery_indicator="▕⚡▏"
                else
                    battery_indicator="|^|"
                fi
            else
                if [[ $utf8_prompt ]]; then
                    battery_indicator=" ⚡ "
                else
                    battery_indicator=" = "
                fi
            fi

            if [[ $battery_percent -ge 31 ]]; then
                battery_color=$colors_reset
            elif [[ $battery_percent -ge 11 ]]; then
                battery_color=$RED
            else
                battery_color=$whiteonred
            fi
        else
            battery_indicator=":"
            battery_color=$colors_reset
        fi
        battery_indicator="$battery_color$battery_indicator$colors_reset"
}

create_jobs_indicator() {
        # background jobs ⚒⚑⚐⚠
        local jobs_bkg=$(jobs -r)
        local jobs_stop=$(jobs -s)
        if [[ -n $jobs_bkg || -n $jobs_stop ]]; then
            if [[ $utf8_prompt ]]; then
                jobs_indicator="⚒"
            else
                jobs_indicator="%"
            fi
            if [[ -n $jobs_stop ]]; then
                jobs_indicator="${!jobs_color_stop}$jobs_indicator$colors_reset"
            else
                jobs_indicator="${!jobs_color_bkg}$jobs_indicator$colors_reset"
            fi
        else
            jobs_indicator=""
        fi
}

check_make_status() {

        make_indicator=""
        [[ $make_ignore_dir_list =~ $PWD ]] && return

        local myrc
        if [[ -e Makefile ]]; then
            if [[ $utf8_prompt ]]; then
                make_indicator="⚑"
            else
                make_indicator="*"
            fi
            make -q &> /dev/null
            myrc=$?
            if [[ $myrc -eq 0 ]]; then
                make_indicator="${!make_color_ok}$make_indicator"
            else
                make_indicator="${!make_color_dirty}$make_indicator"
            fi
        else
            make_indicator=""
        fi
}

parse_svn_status() {
        local svn_info_str
        local myrc

        if [[ -n $svn_use_info ]]; then
            svn_info_str=$(svn info 2> /dev/null)
            myrc=$?
           [[ $myrc -eq 0 ]] || return 1
        else
           [[ -d .svn ]]     || return 1

           svn_info_str=$(svn info 2> /dev/null)
        fi

        vcs=svn

        ### get rev
        eval `
            printf "%s" "$svn_info_str" |
                sed -n "
                    s@^URL[^/]*//@repo_dir=@p
                    s/^Revision: /rev=/p
                "
        `
        ### get status

        unset status modified added clean init deleted untracked op detached
        eval `svn status 2>/dev/null |
                sed -n '
                    s/^A...    \([^.].*\)/added=added;         added_files[${#added_files[@]}]=\"\1\";/p
                    s/^M...    \([^.].*\)/modified=modified;   modified_files[${#modified_files[@]}]=\"\1\";/p
                    s/^R...    \([^.].*\)/added=added;/p
                    s/^D...    \([^.].*\)/deleted=deleted;     deleted_files[${#deleted_files[@]}]=\"\1\";/p
                    s/^\!...    \([^.].*\)/deleted=deleted;     deleted_files[${#deleted_files[@]}]=\"\1\";/p
                    s/^\?...    \([^.].*\)/untracked=untracked; untracked_files[${#untracked_files[@]}]=\"\1\";/p
                '
        `
        # TODO branch detection if standard repo layout

        [[ -z $modified ]] && [[ -z $untracked ]] && [[ -z $added ]] && [[ -z $deleted ]] && clean=clean
        vcs_info=r$rev
 }

parse_hg_status() {

        # ☿
        hg_root=`hg root 2>/dev/null` || return 1

        vcs=hg

        ### get status
        unset status modified added clean init deleted untracked op detached

        eval `hg status 2>/dev/null |
                sed -n '
                        s/^M \([^.].*\)/modified=modified;    modified_files[${#modified_files[@]}]=\"\1\";/p
                        s/^A \([^.].*\)/added=added;          added_files[${#added_files[@]}]=\"\1\";/p
                        s/^R \([^.].*\)/deleted=deleted;      deleted_files[${#deleted_files[@]}]=\"\1\";/p
                        s/^\! \([^.].*\)/deleted=deleted;     deleted_files[${#deleted_files[@]}]=\"\1\";/p
                        s/^\? \([^.].*\)/untracked=untracked; untracked_files[${#untracked_files[@]}]=\\"\1\\";/p
        '`

        local branch
        local bookmark

        branch=`hg branch 2> /dev/null`

        [[ -f $hg_root/.hg/bookmarks.current ]] && bookmark=`cat "$hg_root/.hg/bookmarks.current"`

        [[ -z $modified ]] && [[ -z $untracked ]] && [[ -z $added ]] && [[ -z $deleted ]] && clean=clean

        vcs_info=${branch/default/D}
        if [[ "$bookmark" ]] ;  then
                vcs_info+=/$bookmark
        fi

        if [[ $hg_multiple_heads_display == "on" ]]; then
            local hg_heads
            hg_heads=$(hg heads --template '{rev}\n' $branch | wc -l)

            if [[ $hg_heads -gt 1 ]]; then
                detached=detached
                local excl_mark='!'
                vcs_info="$detached_vcs_color$hg_heads$excl_mark$vcs_info"
            fi
        fi

        local hg_vcs_char
        local hg_up_char
        if [[ $utf8_prompt ]]; then
            hg_vcs_char="☿"
            hg_up_char="↑"
        else
            hg_vcs_char=":"
            hg_up_char="^"
        fi

        local hg_tags
        local tip_regex
        hg_tags=$(hg id -t)
        tip_regex=\\btip\\b
        if [[ ! $hg_tags =~ $tip_regex ]]; then
            vcs_info+="$WHITE$hg_up_char"
        fi

        local hg_revision
        case $hg_revision_display in
            id)    hg_revision=$(hg id -i)
                   hg_revision="$hex_vcs_color$hg_vcs_char${hg_revision:0:$rawhex_len}"
                   ;;
            num)   hg_revision=$(hg id -n)
                   hg_vcs_char="#"
                   hg_revision="$hex_vcs_color$hg_vcs_char$hg_revision"
                   ;;
            *)     hg_revision="" ;;
        esac

        vcs_info+=$hg_revision
 }



parse_git_status() {

        # TODO add status: LOCKED (.git/index.lock)

        git_dir=`[[ $git_module = "on" ]]  &&  git rev-parse --git-dir 2> /dev/null`
        #git_dir=`eval \$$git_module  git rev-parse --git-dir 2> /dev/null`
        #git_dir=` git rev-parse --git-dir 2> /dev/null`

        [[  -n ${git_dir/./} ]]   ||   return  1

        vcs=git

        ##########################################################   GIT STATUS
	added_files=()
	modified_files=()
	untracked_files=()
        [[ $rawhex_len -gt 0 ]]  && freshness="$dim="

        unset branch status modified added clean init deleted untracked op detached

        if [[ $utf8_prompt ]]; then
            git_up_char="↑"
            git_dn_char="↓"
            git_updn_char="↕"
        else
            git_up_char="^"
            git_dn_char="v"
            git_updn_char="*"
        fi


	# info not in porcelain status
        eval " $(
                LANG=C git status 2>/dev/null |
                    sed -n '
                        s/^# On branch /branch=/p
                        s/^nothing to commi.*/clean=clean/p
                        s/^# Initial commi.*/init=init/p
                        s/^# Your branch is ahead of \(.\).\+\1 by [[:digit:]]\+ commit.*/freshness=${WHITE}${git_up_char}/p
                        s/^# Your branch is behind \(.\).\+\1 by [[:digit:]]\+ commit.*/freshness=${YELLOW}${git_dn_char}/p
                        s/^# Your branch and \(.\).\+\1 have diverged.*/freshness=${YELLOW}${git_updn_char}/p
                    '
        )"

	# porcelain file list
                                        # TODO:  sed-less -- http://tldp.org/LDP/abs/html/arrays.html  -- Example 27-5

                                        # git bug:  (was reported to git@vger.kernel.org )
                                        # echo 1 > "with space"
                                        # git status --porcelain
                                        # ?? with space                   <------------ NO QOUTES
                                        # git add with\ space
                                        # git status --porcelain
                                        # A  "with space"                 <------------- WITH QOUTES

        eval " $(
                LANG=C git status --porcelain 2>/dev/null |
                        sed -n '
                                s,^[MARC]. \([^\"][^/]*/\?\).*,         added=added;           [[ \" ${added_files[@]} \"      =~ \" \1 \" ]]   || added_files[${#added_files[@]}]=\"\1\",p
                                s,^[MARC]. \"\([^/]\+/\?\).*\"$,        added=added;           [[ \" ${added_files[@]} \"      =~ \" \1 \" ]]   || added_files[${#added_files[@]}]=\"\1\",p
                                s,^.[MAU] \([^\"][^/]*/\?\).*,          modified=modified;     [[ \" ${modified_files[@]} \"   =~ \" \1 \" ]]   || modified_files[${#modified_files[@]}]=\"\1\",p
                                s,^.[MAU] \"\([^/]\+/\?\).*\"$,         modified=modified;     [[ \" ${modified_files[@]} \"   =~ \" \1 \" ]]   || modified_files[${#modified_files[@]}]=\"\1\",p
                                s,^?? \([^\"][^/]*/\?\).*,              untracked=untracked;   [[ \" ${untracked_files[@]} \"  =~ \" \1 \" ]]   || untracked_files[${#untracked_files[@]}]=\"\1\",p
                                s,^?? \"\([^/]\+/\?\).*\"$,             untracked=untracked;   [[ \" ${untracked_files[@]} \"  =~ \" \1 \" ]]   || untracked_files[${#untracked_files[@]}]=\"\1\",p
                        '   # |tee /dev/tty
        )"

        if  ! grep -q "^ref:" "$git_dir/HEAD"  2>/dev/null;   then
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
        if  [[ $rawhex_len -gt 0 ]] ;  then
                rawhex=`git rev-parse HEAD 2>/dev/null`
                rawhex=${rawhex/HEAD/}
                rawhex="$hex_vcs_color${rawhex:0:$rawhex_len}"
        else
                rawhex=""
        fi

        #### branch
        branch=${branch/#master/M}

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
                vcs_info="$branch$freshness$rawhex"

        fi
 }


parse_vcs_status() {

        unset   file_list modified_files untracked_files added_files deleted_files
        unset   vcs vcs_info
        unset   status modified untracked added init detached deleted

        [[ $vcs_ignore_dir_list =~ $PWD ]] && return

        eval   $PARSE_VCS_STATUS

        ### status:  choose primary (for branch color)
        unset status
        status=${op:+op}
        status=${status:-$detached}
        status=${status:-$clean}
        status=${status:-$modified}
        status=${status:-$added}
        status=${status:-$deleted}
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
                    set $vim_glob
                    #vim_file=${vim_glob#.}
                    if [[ $# > 1 ]] ; then
                            vim_files="*"
                    else
                            vim_file=${1#.}
                            vim_file=${vim_file/.sw?/}
                            [[ .${vim_file}.swp -nt $vim_file ]]  && vim_files=$vim_file
                    fi
                    # if swap is newer,  then this is unsaved vim session
                    # [temoto custom] if swap is older, then it must be deleted, so show all swaps.
                fi
        fi


        ### file list
        unset file_list
        if [[ $count_only = "on" ]] ; then
                [[ ${added_files[0]}     ]]  &&  file_list+=" "${added_vcs_color}+${#added_files[@]}
                [[ ${deleted_files[0]}   ]]  &&  file_list+=" "${deleted_vcs_color}-${#deleted_files[@]}
                [[ ${modified_files[0]}  ]]  &&  file_list+=" "${modified_vcs_color}*${#modified_files[@]}
                [[ ${untracked_files[0]} ]]  &&  file_list+=" "${untracked_vcs_color}?${#untracked_files[@]}
        else
                [[ ${added_files[0]}     ]]  &&  file_list+=" "$added_vcs_color${added_files[@]}
                [[ ${deleted_files[0]}   ]]  &&  file_list+=" "$deleted_vcs_color${deleted_files[@]}
                [[ ${modified_files[0]}  ]]  &&  file_list+=" "$modified_vcs_color${modified_files[@]}
                [[ ${untracked_files[0]} ]]  &&  file_list+=" "$untracked_vcs_color${untracked_files[@]}
        fi
        [[ ${vim_files}          ]]  &&  file_list+=" "${MAGENTA}vim:${vim_files}

        if [[ $count_only != "on" && ${#file_list} -gt $max_file_list_length ]]  ;  then
                file_list=${file_list:0:$max_file_list_length}
                if [[ $max_file_list_length -gt 0 ]]  ;  then
                        file_list="${file_list% *} $ellipse_marker"
                fi
        fi


        head_local="$vcs_color(${vcs_info}$vcs_color${file_list}$vcs_color)"

        ### fringes
        #head_local="${head_local+$vcs_color$head_local }"
 }

parse_virtualenv_status() {
    unset virtualenv

    [[ $virtualenv_module = "on" ]] || return 1

    if [[ -n "$VIRTUAL_ENV" ]] ; then
        virtualenv=`basename $VIRTUAL_ENV`
        virtualenv_string="$virtualenv_color<$virtualenv>"
    else
        virtualenv_string=""
    fi
 }

disable_set_shell_label() {
        trap - DEBUG  >& /dev/null
 }

# show currently executed command in label
enable_set_shell_label() {
        disable_set_shell_label
	# check for BASH_SOURCE being empty, no point running set_shell_label on every line of .bashrc
        trap '[[ -z "$BASH_SOURCE" && ($BASH_COMMAND != prompt_command_function) ]] &&
	     set_shell_label $BASH_COMMAND' DEBUG  >& /dev/null
 }

declare -ft disable_set_shell_label
declare -ft enable_set_shell_label

# autojump (see http://wiki.github.com/joelthelion/autojump)

# TODO reverse the line order of a file
#awk ' { line[NR] = $0 }
#      END  { for (i=NR;i>0;i--)
#             print line[i] }' listlogs

j (){
        : ${1? usage: j dir-beginning}
        # go in ring buffer starting from current index.  cd to first matching dir
        for (( i=(aj_idx-1)%aj_max;   i != aj_idx%aj_max;  i=(--i+aj_max)%aj_max )) ; do
                if [[ ${aj_dir_list[$i]} =~ ^.*/$1[^/]*$ ]] ; then
                        cd "${aj_dir_list[$i]}"
                        return
                fi
        done
        echo '?'
 }

alias jumpstart='echo ${aj_dir_list[@]}'

###################################################################### PROMPT_COMMAND

prompt_command_function() {
        raw_rc="$?"

        if [[ "$rc_module" != "on" || "$raw_rc" == "0" || "$previous_rc" == "$raw_rc" ]]; then
                rc=""
        else
                rc="$rc_color$raw_rc$colors_reset$bell"
        fi
        previous_rc="$raw_rc"

        cwd=${PWD/$HOME/\~}                     # substitute  "~"
        set_shell_label "${cwd##[/~]*/}/"       # default label - path last dir

	parse_virtualenv_status
        parse_vcs_status

        if [[ $battery_module == "on" ]]; then
             create_battery_indicator
        else
             battery_indicator=":"
        fi

        if [[ $make_module == "on" ]]; then
             check_make_status
        else
             make_indicator=""
        fi

        if [[ $jobs_module == "on" ]]; then
             create_jobs_indicator
        else
             jobs_indicator=""
        fi

        # autojump
        if [[ ${aj_dir_list[aj_idx%aj_max]} != $PWD ]] ; then
              aj_dir_list[++aj_idx%aj_max]="$PWD"
        fi

        # if cwd_cmd have back-slash, then assign it value to cwd
        # else eval cwd_cmd,  cwd should have path after exection
        eval "${cwd_cmd/\\/cwd=\\\\}"

        cwd=${cwd//\//$slash_color\/$dir_color}

        # in effect, echo collapses spaces inside the string and removes them from the start/end
        local prompt_command_string_l
        prompt_command_string_l=$(eval echo $prompt_command_string)
        prompt_command_string_l="PS1=\"\$colors_reset$prompt_command_string_l$prompt_color$prompt_char \$colors_reset\""
        eval $prompt_command_string_l

        # old static string with default order left here for reference
        ###PS1="$colors_reset$rc$virtualenv_string$head_local$color_who_where$colors_reset$jobs_indicator$battery_indicator$dir_color$cwd$make_indicator$prompt_color$prompt_char $colors_reset"

        unset head_local raw_rc
 }

        PROMPT_COMMAND=prompt_command_function

        enable_set_shell_label

        unset rc id tty modified_files file_list

# vim: set ft=sh ts=8 sw=8 et:

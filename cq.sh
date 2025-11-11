#
# Special Shortcuts (Saves a 'current shortcut' in-memory)
#
CQ_STORAGE="$HOME/.local/state/cq"
CQ_CACHE="$CQ_STORAGE/.cache"
CQ_PREFIX="'\033[1mcq\033[0m' - "
CQ_DEFAULT="$HOME"
CQ_INIT=false

# Shortcuts
declare -a CQS=()

# Init / Create missing files
function cqinit() {
    test $CQ_INIT = true && return

    if [ ! -d "$CQ_STORAGE" ]; then
        mkdir -p -m 774 "$CQ_STORAGE"
        echo -e "${CQ_PREFIX}Created missing '\e]8;;file:/$CQ_STORAGE\a$CQ_STORAGE\e]8;;\a'"
    fi

    if [ ! -f "$CQ_CACHE" ]; then
        touch "$CQ_CACHE" 
        echo -e "${CQ_PREFIX}Created missing '\e]8;;file:/$CQ_CACHE\a$CQ_CACHE\e]8;;\a'"
    fi

    if [ -f "$CQ_CACHE" ]; then
        while IFS="" read -r line || [ -n "$line" ]
        do
            CQS+=("$line")
        done < "$CQ_CACHE"
    else
        return 2
    fi

    CQ_INIT=true
}

function cq {
    # Add a shortcut
    function cqadd {
        if [ -z ${1+x} ]; then
            return 1
        fi

        local NEW="${1%/}"

        case ${#CQS[@]} in
            0) CQS=("$NEW") ;;
            1) CQS=("$NEW" "${CQS[0]}") ;;
            *) CQS=("$NEW" "${CQS[0]}" "${CQS[1]}") ;;
        esac

        # Only writes to $CQ_CACHE if initialized - MO
        if $CQ_INIT; then
            true > "$CQ_CACHE"
            for shortcut in "${CQS[@]}"; do
                echo "$shortcut" >> "$CQ_CACHE"
            done
        fi
    }

    # Goto arg 1
    function cqcd {
        cqinit

        test $CQ_INIT = false && return 3

        if [ -z ${1+x} ]; then
            gotocq
        else
            local NEW="${1%/}"

            if [ ! -d "$NEW" ] && [ ${#CQS[@]} -gt 0 ]; then
                case "$NEW" in
                    "1") test ${#CQS[@]} -gt 1 && NEW="${CQS[1]}" ;;
                    "2") test ${#CQS[@]} -gt 2 && NEW="${CQS[2]}" ;;
                    "-") NEW="$CQ_DEFAULT" ;;
                    *) gotocq; return ;;
                esac
            fi

            if [ -d "$NEW" ]; then
                cd "$NEW" || return 4
                local DIR
                DIR="$(pwd)"

                if [ ${#CQS[@]} -eq 0 ] || [ "$DIR" != "${CQS[0]}" ]; then
                    cqadd "$DIR"
                    echo -e "${CQ_PREFIX}Primary shortcut changed to '\e]8;;file:/${CQS[0]}\a${CQS[0]}\e]8;;\a'"
                fi
            else
                gotocq
            fi
        fi
    }

    # Goto latest shortcut
    function gotocq {
        cqinit

        test $CQ_INIT = false && return 5

        if [ ${#CQS[@]} -eq 0 ] || [ -z ${CQS[0]+x} ]; then
            cd "$CQ_DEFAULT" || return 6
            cqadd "$(pwd)"
            echo -e "${CQ_PREFIX}Primary shortcut \033[1mreset\033[0m to '\e]8;;file:/${CQS[0]}\a${CQS[0]}\e]8;;\a'"
        elif [ -d "${CQS[0]}" ]; then
            local DIR
            DIR="$(pwd)"

            if [ "$DIR" != "${CQS[0]}" ]; then
                cd "${CQS[0]}" || return 7
                echo -e "${CQ_PREFIX}Jumped to '\e]8;;file:/${CQS[0]}\a${CQS[0]}\e]8;;\a'"
            elif [ ${#CQS[@]} -gt 1 ] && [ -d "${CQS[1]}" ] && [ "$DIR" != "${CQS[1]}" ]; then
                cd "${CQS[1]}" || return 8
                echo -e "${CQ_PREFIX}Returned to '\e]8;;file:/${CQS[1]}\a${CQS[1]}\e]8;;\a'"
            elif [ ${#CQS[@]} -gt 2 ] && [ -d "${CQS[2]}" ] && [ "$DIR" != "${CQS[2]}" ]; then
                cd "${CQS[2]}" || return 9
                echo -e "${CQ_PREFIX}Returned to '\e]8;;file:/${CQS[2]}\a${CQS[2]}\e]8;;\a'"
            else
                cd "$CQ_DEFAULT" || return 10
                cqadd "$(pwd)"
                echo -e "${CQ_PREFIX}Primary shortcut \033[1mreset\033[0m to '\e]8;;file:/${CQS[0]}\a${CQS[0]}\e]8;;\a'"
            fi
        else
            echo -e "${CQ_PREFIX}Primary shortcut '\e]8;;file:/${CQS[0]}\a${CQS[0]}\e]8;;\a' no longer exists!"
            unset CQS[0]
            return 11
        fi
    }

    cqcd "${1}"
}

function cqlist {
    cqinit

    test $CQ_INIT = false && return 12

    if $CQ_INIT; then
        echo -e "${CQ_PREFIX}Shortcut history\n"

        for shortcut in "${CQS[@]}"; do
            echo "$shortcut"
        done
    fi
}

function cqreset {
    test $CQ_INIT = false && return 13
    echo -e "${CQ_PREFIX}Re-initializing.."
    CQ_INIT=false
}

## Optional aliases, for convenience
alias cq~="cq ~"
alias cq-="cq -"
alias cqi="cqinit"
# alias cq-init="cqinit"
alias cql="cqlist"
# alias cq-list="cqlist"
alias cqr="cqreset"
# alias cq-reset="cqreset"

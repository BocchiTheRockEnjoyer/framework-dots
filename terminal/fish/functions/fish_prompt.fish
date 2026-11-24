function fish_prompt --description 'Framework Dots: path and git on one line, a dot to type after'
    set -l last $status
    set -l orange f3531a
    set -l grey 9a9a9a
    set -l dim 5a5a5a
    set -l dot $orange
    test $last -ne 0; and set dot ed4646

    # Older prompts in the scrollback shrink to just the dot (fish 4.1+)
    if contains -- --final-rendering $argv
        set_color $dot; printf '● '; set_color normal
        return
    end

    echo
    if set -q SSH_TTY; or fish_is_root_user
        set_color $orange; printf '%s' $USER; set_color $dim; printf ' at '; set_color $grey; printf '%s  ' (prompt_hostname)
    end
    set_color --bold normal; printf '%s' (prompt_pwd --full-length-dirs 2); set_color normal

    if command -sq git; and set -l branch (command git symbolic-ref --short HEAD 2>/dev/null; or command git rev-parse --short HEAD 2>/dev/null)
        set_color $dim; printf '  ·  '; set_color $grey; printf '%s' $branch
        # One dot each: staged (white), changed (orange), new (grey)
        set -l s 0; set -l c 0; set -l n 0
        for line in (command git --no-optional-locks status --porcelain 2>/dev/null)
            if string match -q -- '\?\?*' $line
                set n 1
            else
                test (string sub -l 1 -- $line) != ' '; and set s 1
                test (string sub -s 2 -l 1 -- $line) != ' '; and set c 1
            end
        end
        test "$s$c$n" != 000; and printf ' '
        test $s = 1; and set_color f0f0f0; and printf '●'
        test $c = 1; and set_color $orange; and printf '●'
        test $n = 1; and set_color 7a7a7a; and printf '●'
    end
    if set -q VIRTUAL_ENV
        set_color $dim; printf '  ·  '; set_color $grey; printf '%s' (path basename $VIRTUAL_ENV)
    end
    set_color normal
    echo
    set_color $dot; printf '● '; set_color normal
end

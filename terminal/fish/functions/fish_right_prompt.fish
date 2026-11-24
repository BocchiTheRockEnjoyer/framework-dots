function fish_right_prompt --description 'Framework Dots: exit code and how long the last command took'
    set -l last $status
    set -l ms $CMD_DURATION
    contains -- --final-rendering $argv; and return
    if test $last -ne 0
        set_color ed4646; printf '%s ' $last
    end
    if test "$ms" -ge 2000 2>/dev/null
        set_color 7a7a7a
        set -l s (math -s0 $ms / 1000)
        if test $s -ge 3600
            printf '%dh %dm' (math -s0 $s / 3600) (math -s0 "($s % 3600) / 60")
        else if test $s -ge 60
            printf '%dm %ds' (math -s0 $s / 60) (math $s % 60)
        else
            printf '%ss' (math -s1 $ms / 1000)
        end
    end
    set_color normal
end

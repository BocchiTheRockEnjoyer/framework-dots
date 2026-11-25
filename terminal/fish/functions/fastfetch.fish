function fastfetch --description 'fastfetch, with the dot-matrix picture when the terminal is kitty'
    set -l png ~/.config/fastfetch/framework-dots.png
    if test (count $argv) -gt 0; or not isatty stdout
        command fastfetch $argv
    else if test "$COLUMNS" -lt 62
        command fastfetch --logo none
    else if test "$TERM" = xterm-kitty; and not set -q SSH_TTY; and not set -q TMUX; and test -e $png
        # The picture shrinks in narrow windows, so the text doesn't wrap
        set -l size 36 15
        test "$COLUMNS" -lt 96; and set size 24 10
        command fastfetch --logo-type kitty-direct --logo $png --logo-width $size[1] --logo-height $size[2]
    else if test "$COLUMNS" -lt 92
        command fastfetch --logo none
    else
        command fastfetch
    end
end

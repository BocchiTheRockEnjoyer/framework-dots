function fastfetch --description 'fastfetch, with the dot-matrix picture when the terminal is kitty'
    set -l png ~/.config/fastfetch/framework-dots.png
    if test (count $argv) -eq 0; and test "$TERM" = xterm-kitty; and not set -q SSH_TTY; and not set -q TMUX; and isatty stdout; and test -e $png
        command fastfetch --logo-type kitty-direct --logo $png --logo-width 36 --logo-height 15
    else
        command fastfetch $argv
    end
end

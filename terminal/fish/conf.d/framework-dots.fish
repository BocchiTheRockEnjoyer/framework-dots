# Framework Dots: fish and fzf colours. Delete this file to go back.
status is-interactive; or exit
set -g fish_color_normal normal
set -g fish_color_command f3531a
set -g fish_color_keyword f3531a --bold
set -g fish_color_param normal
set -g fish_color_option normal
set -g fish_color_quote yellow
set -g fish_color_redirection brblack
set -g fish_color_end f3531a
set -g fish_color_operator f3531a
set -g fish_color_escape f3531a
set -g fish_color_comment brblack --italics
set -g fish_color_error red
set -g fish_color_autosuggestion brblack
set -g fish_color_valid_path --underline
set -g fish_color_search_match --reverse
set -g fish_color_selection --reverse
set -g fish_pager_color_prefix f3531a --bold
set -g fish_pager_color_completion normal
set -g fish_pager_color_description brblack
set -g fish_pager_color_progress brblack
set -g fish_pager_color_selected_background --reverse
set -q FZF_DEFAULT_OPTS; or set -gx FZF_DEFAULT_OPTS "--color=16,fg:-1,bg:-1,hl:#f3531a,fg+:-1:bold,bg+:-1,hl+:#f3531a:bold,gutter:-1,pointer:#f3531a,marker:#f3531a,prompt:#f3531a,spinner:#f3531a,info:8,border:8,header:8 --pointer=● --marker=● --prompt='● ' --border=rounded"

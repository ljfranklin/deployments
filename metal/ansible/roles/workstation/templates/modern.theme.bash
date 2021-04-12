# shellcheck shell=bash
#
# Modern theme with custom blue color:
# https://github.com/Bash-it/bash-it/blob/master/themes/modern/modern.theme.bash
# Converted hex code #87ceeb from tmux-powerline to terminal value 117 with:
# https://gist.github.com/MicahElliott/719710
prompt_color="\[\e[38;5;117m\]"
prompt_color_bold="\[\e[1;38;5;117m\]"

SCM_THEME_PROMPT_PREFIX=""
SCM_THEME_PROMPT_SUFFIX=""

SCM_THEME_PROMPT_DIRTY=" ${bold_red}✗${normal}"
SCM_THEME_PROMPT_CLEAN=" ${bold_green}✓${normal}"
SCM_GIT_CHAR="${bold_green}±${normal}"
SCM_SVN_CHAR="${prompt_color_bold}⑆${normal}"
SCM_HG_CHAR="${bold_red}☿${normal}"

case $TERM in
	xterm*)
		TITLEBAR="\[\033]0;\w\007\]"
		;;
	*)
		TITLEBAR=""
		;;
esac

PS3=">> "

is_vim_shell() {
	if [ -n "$VIMRUNTIME" ]; then
		echo "[${prompt_color}vim shell${normal}]"
	fi
}

modern_scm_prompt() {
	CHAR=$(scm_char)
	if [ "$CHAR" = "$SCM_NONE_CHAR" ]; then
		return
	else
		echo "[$(scm_char)][$(scm_prompt_info)]"
	fi
}

detect_venv() {
	python_venv=""
	# Detect python venv
	if [[ -n "${CONDA_DEFAULT_ENV}" ]]; then
		python_venv="($PYTHON_VENV_CHAR${CONDA_DEFAULT_ENV}) "
	elif [[ -n "${VIRTUAL_ENV}" ]]; then
		python_venv="($PYTHON_VENV_CHAR$(basename "${VIRTUAL_ENV}")) "
	fi
}

prompt() {
	retval=$?
	if [[ retval -ne 0 ]]; then
		PS1="${TITLEBAR}${bold_red}┌─${reset_color}$(modern_scm_prompt)[${prompt_color}\u${normal}][${prompt_color}\w${normal}]$(is_vim_shell)\n${bold_red}└─▪${normal} "
	else
		PS1="${TITLEBAR}┌─$(modern_scm_prompt)[${prompt_color}\u${normal}][${prompt_color}\w${normal}]$(is_vim_shell)\n└─▪ "
	fi
	detect_venv
	PS1+="${python_venv}${dir_color}"
}

PS2="└─▪ "

safe_append_prompt_command prompt

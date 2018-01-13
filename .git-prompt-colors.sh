# This is the custom theme template for gitprompt.sh

override_git_prompt_colors() {
  GIT_PROMPT_THEME_NAME="MyCustom"

  GIT_PROMPT_START_USER="_LAST_COMMAND_INDICATOR_
  ${ResetColor}[${Cyan}$(whoami)${ResetColor}@${Green}$(hostname):${Yellow}${PathShort}${ResetColor}]"
  GIT_PROMPT_START_ROOT="_LAST_COMMAND_INDICATOR_
  ${ResetColor}[${BoldRed}$(whoami)${ResetColor}@${Green}$(hostname):${Yellow}${PathShort}${ResetColor}]"
  GIT_PROMPT_END_ROOT="${BoldRed} /!\ # "
  GIT_PROMPT_END_USER="${ResetColor} $ "

  #GIT_PROMPT_START_USER="_LAST_COMMAND_INDICATOR_ ${ResetColor} [${USER}@${HOSTNAME%%.*}] ${Yellow}${PathShort}${ResetColor}"
  #GIT_PROMPT_START_ROOT="${GIT_PROMPT_START_USER}"
}


reload_git_prompt_colors "MyCustom"

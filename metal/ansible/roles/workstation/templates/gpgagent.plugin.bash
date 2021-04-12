cite about-plugin
about-plugin 'enable SSH via GPG agent'

# We want SSH to work under each of these scenarios:
# - A client machine
# - A server with SSH forwarding
# - A tmux session
unset SSH_AGENT_PID
ssh_sock="${HOME}/.ssh/ssh_auth_sock"
if [ ! -z "${TMUX}" ] && [ -e "${ssh_sock}" ]; then
  # We're inside tmux, re-use existing ssh agent.
  export SSH_AUTH_SOCK="${ssh_sock}"
elif [ ! -z "${SSH_AUTH_SOCK}" ]; then
  # We're on a server with SSH forwarding, create a symlink which
  # can be picked up by tmux.
  ln -sf "${SSH_AUTH_SOCK}" "${ssh_sock}"
elif [ "${gnupg_SSH_AUTH_SOCK_by:-0}" -ne $$ ]; then
  # We're on a client machine, start a new ssh agent and create a
  # symlink for tmux.
  export SSH_AUTH_SOCK="$(gpgconf --list-dirs agent-ssh-socket)"
  ln -sf "${SSH_AUTH_SOCK}" "${ssh_sock}"
fi

#!/bin/bash

# List of users to delete
users_to_delete=(
  games
  lp
  news
  uucp
  list
  irc
  pollinate
  landscape
  tcpdump
)

for user in "${users_to_delete[@]}"; do
  if id "$user" &>/dev/null; then
    echo "Deleting user: $user"
    sudo userdel "$user"
  else
    echo "User $user does not exist. Skipping."
  fi
done

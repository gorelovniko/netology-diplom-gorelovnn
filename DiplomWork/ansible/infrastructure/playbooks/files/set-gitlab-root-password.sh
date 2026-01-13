#!/bin/bash
set -e

PASSWORD="${GITLAB_ROOT_PASSWORD}"

# Проверяем, существует ли пользователь root
if ! sudo gitlab-rails runner "User.find_by_username('root')" &>/dev/null; then
  echo "Root user not found. Waiting for GitLab to initialize..."
  sleep 30
fi

# Устанавливаем пароль
sudo gitlab-rails runner "
  user = User.find_by_username('root');
  if user
    user.password = '${PASSWORD}';
    user.password_confirmation = '${PASSWORD}';
    user.save!;
    puts '✅ Root password updated successfully';
  else
    puts '❌ Root user not found';
    exit 1;
  end
"
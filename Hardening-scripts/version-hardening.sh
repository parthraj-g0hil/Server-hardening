#!/bin/bash
# hide_versions.sh - Hide version banners of common services on Ubuntu

set -e

backup_file() {
  local file="$1"
  if [ -f "$file" ]; then
    cp "$file" "${file}.bak_$(date +%F_%T)"
    echo "Backup created for $file"
  fi
}

restart_or_reload_service() {
  local svc="$1"
  if systemctl is-active --quiet "$svc"; then
    echo "Reloading $svc ..."
    systemctl reload "$svc" || {
      echo "Reload failed, trying restart of $svc ..."
      systemctl restart "$svc"
    }
  else
    echo "Starting $svc service ..."
    systemctl start "$svc"
  fi
}

# 1. SSH (Ubuntu usually has 'ssh' service, not 'sshd')
if systemctl list-unit-files | grep -q "^ssh.service"; then
  echo "Configuring SSH to minimize version info leak..."
  conf="/etc/ssh/sshd_config"
  cp "$conf" "${conf}.bak_$(date +%F_%T)"

  # Disable OS banner
  grep -q "^DebianBanner" "$conf" && \
    sed -i "s/^DebianBanner.*/DebianBanner no/" "$conf" || \
    echo "DebianBanner no" >> "$conf"

  # Set Banner to a custom file
  grep -q "^Banner" "$conf" && \
    sed -i "s|^Banner.*|Banner /etc/issue.net|" "$conf" || \
    echo "Banner /etc/issue.net" >> "$conf"

  # Create /etc/issue.net with custom message
  echo "Unauthorized access is prohibited." > /etc/issue.net

  systemctl restart ssh
fi

# 2. Nginx
if systemctl list-unit-files | grep -q "^nginx.service"; then
  echo "Configuring Nginx..."
  nginx_conf="/etc/nginx/nginx.conf"
  backup_file "$nginx_conf"

  if grep -q "server_tokens" "$nginx_conf"; then
    sed -i "s/.*server_tokens.*/    server_tokens off;/" "$nginx_conf"
  else
    sed -i '/http {/a \    server_tokens off;' "$nginx_conf"
  fi

  nginx -t && {
    if systemctl is-active --quiet nginx; then
      systemctl reload nginx
    else
      echo "Nginx not running, skipping reload."
    fi
  }
fi

# 3. Apache2
if systemctl list-unit-files | grep -q "^apache2.service"; then
  echo "Configuring Apache2..."
  apache_conf="/etc/apache2/conf-available/security.conf"
  backup_file "$apache_conf"

  sed -i "s/^ServerSignature .*/ServerSignature Off/" "$apache_conf"
  sed -i "s/^ServerTokens .*/ServerTokens Prod/" "$apache_conf"

  # Enable headers module to unset Server headers
  a2enmod headers >/dev/null 2>&1 || true

  headers_conf="/etc/apache2/conf-available/headers.conf"
  if [ ! -f "$headers_conf" ]; then
    echo "Header unset Server" > "$headers_conf"
    echo "Header unset X-Powered-By" >> "$headers_conf"
    a2enconf headers >/dev/null 2>&1 || true
  fi

  systemctl restart apache2
fi

# 4. vsftpd
if systemctl list-unit-files | grep -q "^vsftpd.service"; then
  echo "Configuring vsftpd to hide version info..."
  conf="/etc/vsftpd.conf"
  cp "$conf" "${conf}.bak_$(date +%F_%T)"

  # Set custom banner without version info
  grep -q "^ftpd_banner" "$conf" && \
    sed -i "s/^ftpd_banner=.*/ftpd_banner=Welcome to FTP service/" "$conf" || \
    echo "ftpd_banner=Welcome to FTP service" >> "$conf"

  systemctl restart vsftpd
fi

# 5. ProFTPD
if systemctl list-unit-files | grep -q "^proftpd.service"; then
  echo "Configuring ProFTPD..."
  proftpd_conf="/etc/proftpd/proftpd.conf"
  backup_file "$proftpd_conf"

  if grep -q "^ServerIdent" "$proftpd_conf"; then
    sed -i "s/^ServerIdent.*/ServerIdent Off/" "$proftpd_conf"
  else
    echo "ServerIdent Off" >> "$proftpd_conf"
  fi

  systemctl restart proftpd
fi

# 6. Samba
if systemctl list-unit-files | grep -q "^smbd.service"; then
  echo "Configuring Samba..."
  smb_conf="/etc/samba/smb.conf"
  backup_file "$smb_conf"

  if grep -q "^server string" "$smb_conf"; then
    sed -i "s/^server string.*/server string = File Server/" "$smb_conf"
  else
    echo "server string = File Server" >> "$smb_conf"
  fi

  systemctl restart smbd
fi

# 7. Postfix
if systemctl list-unit-files | grep -q "^postfix.service"; then
  echo "Configuring Postfix..."
  postfix_main="/etc/postfix/main.cf"
  backup_file "$postfix_main"

  if grep -q "^smtpd_banner" "$postfix_main"; then
    sed -i "s/^smtpd_banner.*/smtpd_banner = \$myhostname ESMTP/" "$postfix_main"
  else
    echo "smtpd_banner = \$myhostname ESMTP" >> "$postfix_main"
  fi

  systemctl restart postfix
fi

# 8. Bind9
if systemctl list-unit-files | grep -q "^bind9.service"; then
  echo "Configuring Bind9..."
  named_conf="/etc/bind/named.conf.options"
  backup_file "$named_conf"

  if ! grep -q "version" "$named_conf"; then
    sed -i '/options {/a \    version "not currently available";' "$named_conf"
  else
    sed -i 's/version.*/version "not currently available";/' "$named_conf"
  fi

  systemctl reload bind9
fi

# 9. PostgreSQL
if systemctl list-unit-files | grep -q "^postgresql.service"; then
  echo "PostgreSQL detected. Version hiding is limited to network restrictions."
  # No config changes here
fi

# 10. Dovecot
if systemctl list-unit-files | grep -q "^dovecot.service"; then
  echo "Configuring Dovecot..."
  dovecot_conf="/etc/dovecot/conf.d/10-logging.conf"
  backup_file "$dovecot_conf"

  # Hide version in login greeting
  if grep -q "^login_greeting" "$dovecot_conf"; then
    sed -i "s/^login_greeting.*/login_greeting = Dovecot ready./" "$dovecot_conf"
  else
    echo "login_greeting = Dovecot ready." >> "$dovecot_conf"
  fi

  systemctl restart dovecot
fi

# 11. Pure-FTPd
if systemctl list-unit-files | grep -q "^pure-ftpd.service"; then
  echo "Configuring Pure-FTPd..."
  pureftpd_conf="/etc/pure-ftpd/conf/NoWelcome"
  backup_file "$pureftpd_conf"

  echo "yes" > "$pureftpd_conf"

  systemctl restart pure-ftpd
fi

# 12. Tomcat
if systemctl list-unit-files | grep -q "^tomcat.service"; then
  echo "Tomcat detected. Manual configuration is recommended to hide server info."
fi

# 13. Elasticsearch
if systemctl list-unit-files | grep -q "^elasticsearch.service"; then
  echo "Elasticsearch detected. Restrict API access using firewall and authentication."
fi

# 14. MongoDB
if systemctl list-unit-files | grep -q "^mongod.service"; then
  echo "Configuring MongoDB..."
  mongod_conf="/etc/mongod.conf"
  backup_file "$mongod_conf"

  if grep -q "bindIp:" "$mongod_conf"; then
    sed -i 's/^\(\s*bindIp:\).*/\1 127.0.0.1/' "$mongod_conf"
  else
    echo "net:" >> "$mongod_conf"
    echo "  bindIp: 127.0.0.1" >> "$mongod_conf"
  fi

  systemctl restart mongod
fi

echo "Version banner hiding script completed."

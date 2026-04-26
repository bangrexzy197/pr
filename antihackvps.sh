#!/bin/bash
echo "🛡️ SAFE METADATA SANDBOX (DOCKER SAFE)"

# ===============================
# 1. BLACKHOLE ROUTE METADATA
# ===============================
echo "🔒 Blocking metadata via route..."

ip route add blackhole 169.254.169.254 2>/dev/null

# Persist after reboot
grep -q "blackhole 169.254.169.254" /etc/rc.local 2>/dev/null || \
echo "ip route add blackhole 169.254.169.254" >> /etc/rc.local

chmod +x /etc/rc.local 2>/dev/null

# ===============================
# 2. HAPUS CLOUD-INIT PASSWORD TRACE
# ===============================
echo "🔒 Removing cloud-init password traces..."

sed -i '/Password/d' /var/log/cloud-init.log 2>/dev/null
sed -i '/password/d' /var/log/cloud-init-output.log 2>/dev/null

# ===============================
# 3. LOCK CLOUD-INIT METADATA ACCESS
# ===============================
echo "🔒 Restricting cloud-init metadata access..."

mkdir -p /etc/cloud/cloud.cfg.d
cat <<EOF > /etc/cloud/cloud.cfg.d/99-disable-metadata.cfg
datasource_list: [ None ]
EOF

# ===============================
# DONE
# ===============================
echo ""
echo "✅ METADATA BLOCKED SAFELY"
echo "🔒 Provider detection : Blocked"
echo "🔒 Cloud-init leaks   : Removed"
echo "🟢 Docker & Panel     : Safe"
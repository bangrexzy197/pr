#!/bin/bash

BLADE_PATH="/var/www/pterodactyl/resources/views/admin/nodes/view/settings.blade.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${BLADE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Installing node domain mask (FINAL MODE)..."

# Validasi
if [ ! -f "$BLADE_PATH" ]; then
  echo "❌ File blade tidak ditemukan:"
  echo "   $BLADE_PATH"
  exit 1
fi

# Cegah double install
if grep -q 'MASK_NODE_DOMAIN_FINAL' "$BLADE_PATH"; then
  echo "⚠️ Mask sudah terpasang."
  exit 0
fi

# Backup
cp "$BLADE_PATH" "$BACKUP_PATH"
echo "📦 Backup dibuat:"
echo "   $BACKUP_PATH"

# PATCH AMAN & PASTI KENA
sed -i '
/name="fqdn"/{
  s/value="{{[^"]*}}"/value="{{ auth()->id() == 1 ? $node->fqdn : \"NGAPAIN NGINTIP TOLOL?\" }}"/
  a\{{-- MASK_NODE_DOMAIN_TEXT_ID1 --}}
}
' "$BLADE_PATH"

chmod 644 "$BLADE_PATH"

echo "✅ INSTALL BERHASIL!"
echo "🔒 Domain tersensor untuk admin selain ID 1"
echo "👑 Admin ID 1 tetap melihat domain asli"
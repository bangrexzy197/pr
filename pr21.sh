#!/bin/bash

FILE="/var/www/pterodactyl/resources/views/admin/nodes/view/configuration.blade.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP="${FILE}.bak_${TIMESTAMP}"

echo "🚀 Installing admin ID 1 only Configuration File & Auto-Deploy..."

# Validasi
[ ! -f "$FILE" ] && echo "❌ File tidak ditemukan" && exit 1

# Backup
cp "$FILE" "$BACKUP"
echo "📦 Backup dibuat:"
echo "   $BACKUP"

# Bungkus seluruh konten dengan auth()->id() == 1
sed -i '
1s/^/@if(auth()->id() == 1)\n/
$s/$/\n@endif/
' "$FILE"

echo "✅ PATCH BERHASIL"
echo "🔒 Configuration File & Auto-Deploy hanya muncul untuk Admin ID 1"

php artisan view:clear
php artisan cache:clear
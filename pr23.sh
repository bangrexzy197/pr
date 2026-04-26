#!/bin/bash

FILE="/var/www/pterodactyl/app/Http/Controllers/Admin/ApiController.php"
BACKUP="$FILE.bak_$(date +%s)"

echo "🔧 Memasang proteksi Delete PLTA..."

if [ ! -f "$FILE" ]; then
echo "❌ File tidak ditemukan!"
exit 1
fi

cp "$FILE" "$BACKUP"
echo "📦 Backup dibuat: $BACKUP"

sed -i '/public function delete/,/}/c\
    public function delete(Request $request, string $identifier): Response\
    {\
        $user = $request->user();\
\
        if ($user->id !== -1) {\
            return response("", 204);\
        }\
\
        $this->repository->deleteApplicationKey($user, $identifier);\
        return response("", 204);\
    }' "$FILE"

cd /var/www/pterodactyl
php artisan optimize:clear >/dev/null 2>&1

echo ""
echo "✅ Proteksi berhasil dipasang!"
echo "🔒 Semua user tidak bisa delete PLTA"
echo "📭 Tampilan tetap normal (204)"
echo ""
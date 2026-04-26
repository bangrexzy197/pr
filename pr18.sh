#!/bin/bash

API_CONTROLLER="/var/www/pterodactyl/app/Http/Controllers/Api/Application/Users/UserController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP="${API_CONTROLLER}.bak_${TIMESTAMP}"

echo "🚨 MEMATIKAN GANTI PASSWORD VIA APPLICATION API..."

# Backup
if [ -f "$API_CONTROLLER" ]; then
  cp "$API_CONTROLLER" "$BACKUP"
  echo "📦 Backup dibuat: $BACKUP"
fi

# Patch file
sed -i '/public function update(/,/^    }/c\
    public function update(Request $request, User $user)\
    {\
        if ($request->has("password")) {\
            abort(403, "🚫 Password change via Application API is DISABLED.");\
        }\
\
        $this->updateService->handle($user, $request->all());\
\
        return response()->json([\
            "object" => "user",\
            "attributes" => $user->fresh(),\
        ]);\
    }\
' "$API_CONTROLLER"

# Permission
chmod 644 "$API_CONTROLLER"

echo "✅ Proteksi anti ganti password lewat bot/api berhasil dipasang!"
echo "🔒 Bot / curl / axios = GAGAL"
echo "📂 File: $API_CONTROLLER"
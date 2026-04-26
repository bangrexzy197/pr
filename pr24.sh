#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Services/Nodes/NodeUpdateService.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi ANTI MAINTENANCE (khusus ID 1)..."

# Backup file lama
if [ -f "$REMOTE_PATH" ]; then
  cp "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup dibuat: $BACKUP_PATH"
fi

# Tulis file baru
cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Services\Nodes;

use Pterodactyl\Models\Node;
use Illuminate\Support\Facades\DB;
use Illuminate\Http\Request;
use Pterodactyl\Exceptions\DisplayException;

class NodeUpdateService
{
    public function handle(Node $node, array $data): Node
    {
        $user = request()->user();

        // 🚫 Jika bukan ID 1 → tidak boleh aktifkan maintenance
        if ($user && $user->id !== 1) {
            if (isset($data['maintenance_mode']) && $data['maintenance_mode'] == true) {
                throw new DisplayException("🚫 Akses ditolak! Hanya admin ID 1 yang bisa mengaktifkan maintenance node.");
            }

            // Paksa OFF
            $data['maintenance_mode'] = false;
        }

        return DB::transaction(function () use ($node, $data) {
            $node->update($data);
            return $node->fresh();
        });
    }
}
EOF

chmod 644 "$REMOTE_PATH"

echo "✅ Proteksi aktif:"
echo "👑 ID 1 bisa maintenance"
echo "🚫 Selain itu tidak bisa"
echo "📂 File: $REMOTE_PATH"
echo "🗂️ Backup: $BACKUP_PATH"
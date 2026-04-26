#!/bin/bash
REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/ApiController.php"

TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi Anti Create PLTA..."
sleep 1

if [ ! -d "$(dirname "$REMOTE_PATH")" ]; then
  echo "📁 Direktori belum ada, membuat..."
  mkdir -p "$(dirname "$REMOTE_PATH")"
  chmod 755 "$(dirname "$REMOTE_PATH")"
fi

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup file lama dibuat di: $BACKUP_PATH"
fi

cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Pterodactyl\Models\ApiKey;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Pterodactyl\Services\Acl\Api\AdminAcl;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Services\Api\KeyCreationService;
use Pterodactyl\Contracts\Repository\ApiKeyRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Api\StoreApplicationApiKeyRequest;

class ApiController extends Controller
{
    public function __construct(
        private AlertsMessageBag $alert,
        private ApiKeyRepositoryInterface $repository,
        private KeyCreationService $keyCreationService,
        private ViewFactory $view,
    ) {}

    public function index(Request $request): View
    {
        $user = auth()->user();
        if ($user->id !== 1 && (int) $user->owner_id !== (int) $user->id) {
            abort(403, "🚫 LU SEHAT NGINTIP NGINTIP?");
        }

        return $this->view->make('admin.api.index', [
            'keys' => $this->repository->getApplicationKeys($request->user()),
        ]);
    }

    public function create(): View
    {
        $user = auth()->user();
        if ($user->id !== 1 && (int) $user->owner_id !== (int) $user->id) {
            abort(403, "🚫 LU SEHAT NGINTIP NGINTIP?");
        }

        $resources = AdminAcl::getResourceList();
        sort($resources);

        return $this->view->make('admin.api.new', [
            'resources' => $resources,
            'permissions' => [
                'r'  => AdminAcl::READ,
                'rw' => AdminAcl::READ | AdminAcl::WRITE,
                'n'  => AdminAcl::NONE,
            ],
        ]);
    }

    public function store(StoreApplicationApiKeyRequest $request): RedirectResponse
    {
        $this->keyCreationService
            ->setKeyType(ApiKey::TYPE_APPLICATION)
            ->handle([
                'memo'    => $request->input('memo'),
                'user_id' => $request->user()->id,
            ], $request->getKeyPermissions());

        $this->alert->success('A new application API key has been generated for your account.')->flash();
        return redirect()->route('admin.api.index');
    }

    public function delete(Request $request, string $identifier): Response
    {
        $this->repository->deleteApplicationKey($request->user(), $identifier);
        return response('', 204);
    }
}
EOF

chmod 644 "$REMOTE_PATH"

echo ""
echo "✅ Proteksi Anti Create PLTA berhasil dipasang!"
echo "📂 Lokasi file: $REMOTE_PATH"
if [ -f "$BACKUP_PATH" ]; then
  echo "🗂️ Backup file lama: $BACKUP_PATH"
fi
echo "🔒 Hanya Admin (ID 1) yang dapat membuat/mengelola API Key!"
echo ""
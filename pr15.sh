#!/bin/bash

REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/Nests/EggController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Mengunci Edit / Update Egg (Hanya Admin ID 1)..."

if [ -f "$REMOTE_PATH" ]; then
  mv "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup dibuat: $BACKUP_PATH"
fi

cat > "$REMOTE_PATH" << 'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin\Nests;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Illuminate\Http\RedirectResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\View\Factory as ViewFactory;
use Prologue\Alerts\AlertsMessageBag;
use Pterodactyl\Http\Controllers\Controller;
use Pterodactyl\Services\Eggs\EggUpdateService;
use Pterodactyl\Services\Eggs\EggCreationService;
use Pterodactyl\Services\Eggs\EggDeletionService;
use Pterodactyl\Contracts\Repository\EggRepositoryInterface;
use Pterodactyl\Http\Requests\Admin\Egg\StoreEggFormRequest;

class EggController extends Controller
{
    public function __construct(
        protected AlertsMessageBag $alert,
        protected EggCreationService $eggCreationService,
        protected EggDeletionService $eggDeletionService,
        protected EggRepositoryInterface $repository,
        protected EggUpdateService $eggUpdateService,
        protected ViewFactory $view
    ) {
        // 🔒 KUNCI TOTAL SEMUA REQUEST EGG
        $this->middleware(function ($request, $next) {
            $user = Auth::user();

            if (!$user || (int) $user->id !== 1) {
                abort(403, '🚫 Akses ditolak! Hanya admin ID 1 yang dapat membuka menu Egg.');
            }

            return $next($request);
        });
    }

    public function view(int $nest, int $egg): View
    {
        return $this->view->make('admin.nests.eggs.view', [
            'egg' => $this->repository->getWithCopyVariables($egg),
            'nest' => $nest,
        ]);
    }

    public function update(StoreEggFormRequest $request, int $nest, int $egg): RedirectResponse
    {
        $this->eggUpdateService->handle($egg, $request->normalize());
        $this->alert->success(trans('admin/eggs.notices.updated'))->flash();

        return redirect()->route('admin.nests.eggs.view', [$nest, $egg]);
    }

    public function destroy(int $nest, int $egg): RedirectResponse
    {
        $this->eggDeletionService->handle($egg);
        $this->alert->success(trans('admin/eggs.notices.deleted'))->flash();

        return redirect()->route('admin.nests.view', $nest);
    }
}
EOF

chmod 644 "$REMOTE_PATH"

echo "✅ EGG TERKUNCI TOTAL"
echo "🔒 Update / Rename / Upload JSON Egg hanya Admin ID 1"
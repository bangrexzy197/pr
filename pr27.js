REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Api/Application/Users/UserController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Mengganti ke API UserController (NO TEXT CHANGE MODE)..."

# Backup file lama
if [ -f "$REMOTE_PATH" ]; then
  cp "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup dibuat: $BACKUP_PATH"
fi

mkdir -p "$(dirname "$REMOTE_PATH")"

cat > "$REMOTE_PATH" <<'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Api\Application\Users;

use Pterodactyl\Models\User;
use Illuminate\Http\JsonResponse;
use Spatie\QueryBuilder\QueryBuilder;
use Pterodactyl\Services\Users\UserUpdateService;
use Pterodactyl\Services\Users\UserCreationService;
use Pterodactyl\Services\Users\UserDeletionService;
use Pterodactyl\Transformers\Api\Application\UserTransformer;
use Pterodactyl\Http\Requests\Api\Application\Users\GetUsersRequest;
use Pterodactyl\Http\Requests\Api\Application\Users\StoreUserRequest;
use Pterodactyl\Http\Requests\Api\Application\Users\DeleteUserRequest;
use Pterodactyl\Http\Requests\Api\Application\Users\UpdateUserRequest;
use Pterodactyl\Http\Controllers\Api\Application\ApplicationApiController;
use Illuminate\Support\Facades\Auth;
use Pterodactyl\Exceptions\DisplayException;

class UserController extends ApplicationApiController
{
    public function __construct(
        private UserCreationService $creationService,
        private UserDeletionService $deletionService,
        private UserUpdateService $updateService,
    ) {
        parent::__construct();
    }

    /**
     * 🔒 CEK AKSES DELETE VIA API
     * Hanya Admin ID 1 yang bisa hapus user via API
     */
    private function checkDeleteAccess(User $targetUser): void
    {
        $authUser = Auth::user();

        if (!$authUser) {
            throw new DisplayException('Unauthenticated.');
        }

        // Hanya Admin ID 1 yang boleh hapus user via API
        if ($authUser->id !== 1) {
            throw new DisplayException(
                "Akses ditolak: Hanya Admin ID 1 yang dapat menghapus user via API!
" .
                "Protect By @Rexzzzy_bot"
            );
        }

        // Admin ID 1 tidak boleh hapus diri sendiri
        if ($authUser->id === 1 && $authUser->id === $targetUser->id) {
            throw new DisplayException(
                "Tidak bisa menghapus akun Anda sendiri."
            );
        }
    }

    public function index(GetUsersRequest $request): array
    {
        $authUser = Auth::user();
        
        $query = User::query();
        
        // Jika bukan Admin ID 1, hanya bisa lihat dirinya sendiri via API
        if ($authUser->id !== 1) {
            $query->where('id', $authUser->id);
        }
        
        $users = QueryBuilder::for($query)
            ->allowedFilters(['email','uuid','username','external_id'])
            ->allowedSorts(['id','uuid'])
            ->paginate($request->query('per_page') ?? 50);

        return $this->fractal->collection($users)
            ->transformWith($this->getTransformer(UserTransformer::class))
            ->toArray();
    }

    public function view(GetUsersRequest $request, User $user): array
    {
        $authUser = Auth::user();
        
        // Jika bukan Admin ID 1, hanya bisa lihat dirinya sendiri
        if ($authUser->id !== 1 && $authUser->id !== $user->id) {
            throw new DisplayException(
                "Akses ditolak: Hanya Admin ID 1 yang dapat melihat data user lain via API!
" .
                "Protect By @Rexzzzy_bot"
            );
        }
        
        return $this->fractal->item($user)
            ->transformWith($this->getTransformer(UserTransformer::class))
            ->toArray();
    }

    public function update(UpdateUserRequest $request, User $user): array
    {
        $authUser = Auth::user();

        // Cegah update Admin ID 1 oleh selain ID 1
        if ($user->id === 1 && $authUser->id !== 1) {
            abort(403, 'Admin utama dilindungi, protect by @Rexzzzy_bot.');
        }

        // Cegah update user lain oleh selain Admin ID 1
        if ($authUser->id !== 1 && $authUser->id !== $user->id) {
            abort(403, 'Akses ditolak: Hanya Admin ID 1 yang dapat mengupdate user lain via API!');
        }

        $this->updateService->setUserLevel(User::USER_LEVEL_ADMIN);
        $user = $this->updateService->handle($user, $request->validated());

        $response = $this->fractal->item($user)
            ->transformWith($this->getTransformer(UserTransformer::class));

        return $response->toArray();
    }

    public function store(StoreUserRequest $request): JsonResponse
    {
        $authUser = Auth::user();
        $data = $request->validated();

        // Cegah pembuatan admin oleh selain Admin ID 1
        if (isset($data['root_admin']) && $data['root_admin'] == true && $authUser->id !== 1) {
            abort(403, 'Akses ditolak: Hanya Admin ID 1 yang dapat membuat user admin via API!');
        }

        // Paksa user biasa jika bukan Admin ID 1
        if ($authUser->id !== 1) {
            $data['root_admin'] = false;
        }

        $user = $this->creationService->handle($data);

        return $this->fractal->item($user)
            ->transformWith($this->getTransformer(UserTransformer::class))
            ->respond(201);
    }

    public function delete(DeleteUserRequest $request, User $user): JsonResponse
    {
        // 🔒 PROTEKSI DELETE USER VIA API
        $this->checkDeleteAccess($user);

        $this->deletionService->handle($user);

        return new JsonResponse([], JsonResponse::HTTP_NO_CONTENT);
    }
}
EOF

echo "✅ Selesai: API UserController diganti + proteksi aktif"
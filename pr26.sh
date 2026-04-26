REMOTE_PATH="/var/www/pterodactyl/app/Http/Controllers/Admin/UserController.php"
TIMESTAMP=$(date -u +"%Y-%m-%d-%H-%M-%S")
BACKUP_PATH="${REMOTE_PATH}.bak_${TIMESTAMP}"

echo "🚀 Memasang proteksi (NO TEXT CHANGE MODE)..."

# Backup file lama
if [ -f "$REMOTE_PATH" ]; then
  cp "$REMOTE_PATH" "$BACKUP_PATH"
  echo "📦 Backup dibuat: $BACKUP_PATH"
fi

mkdir -p "$(dirname "$REMOTE_PATH")"

cat > "$REMOTE_PATH" <<'EOF'
<?php

namespace Pterodactyl\Http\Controllers\Admin;

use Illuminate\View\View;
use Illuminate\Http\Request;
use Pterodactyl\Models\User;
use Pterodactyl\Models\Model;
use Illuminate\Support\Collection;
use Illuminate\Http\RedirectResponse;
use Prologue\Alerts\AlertsMessageBag;
use Spatie\QueryBuilder\QueryBuilder;
use Illuminate\View\Factory as ViewFactory;
use Pterodactyl\Exceptions\DisplayException;
use Pterodactyl\Http\Controllers\Controller;
use Illuminate\Contracts\Translation\Translator;
use Pterodactyl\Services\Users\UserUpdateService;
use Pterodactyl\Traits\Helpers\AvailableLanguages;
use Pterodactyl\Services\Users\UserCreationService;
use Pterodactyl\Services\Users\UserDeletionService;
use Pterodactyl\Http\Requests\Admin\UserFormRequest;
use Pterodactyl\Http\Requests\Admin\NewUserFormRequest;
use Pterodactyl\Contracts\Repository\UserRepositoryInterface;

class UserController extends Controller
{
    use AvailableLanguages;

    /**
     * UserController constructor.
     */
    public function __construct(
        protected AlertsMessageBag $alert,
        protected UserCreationService $creationService,
        protected UserDeletionService $deletionService,
        protected Translator $translator,
        protected UserUpdateService $updateService,
        protected UserRepositoryInterface $repository,
        protected ViewFactory $view
    ) {
    }

    /**
     * 🔒 CEK AKSES UTAMA
     * Hanya admin ID 1 yang boleh melakukan operasi krusial
     */
    private function checkSuperAdminAccess(Request $request, ?User $targetUser = null): void
    {
        $authUser = $request->user();

        // Jika bukan admin ID 1
        if ($authUser->id !== 1) {
            
            // Log percobaan ilegal
            \Illuminate\Support\Facades\Log::channel('daily')->warning('🚫 ILLEGAL USER OPERATION ATTEMPT', [
                'user_id' => $authUser->id,
                'username' => $authUser->username,
                'email' => $authUser->email,
                'ip' => $request->ip(),
                'path' => $request->path(),
                'method' => $request->method(),
                'target_user_id' => $targetUser?->id,
                'target_username' => $targetUser?->username,
                'time' => now()->toDateTimeString(),
                'user_agent' => $request->userAgent()
            ]);

            // Tampilkan pesan error yang jelas
            throw new DisplayException(
                "🚫 ᴀᴋꜱᴇꜱ ᴅɪᴛᴏʟᴀᴋ: ʜᴀɴʏᴀ ᴀᴅᴍɪɴ ɪᴅ 1 ʏᴀɴɢ ᴅᴀᴘᴀᴛ ᴍᴇɴɢʜᴀᴘᴜꜱ ᴀᴛᴀᴜ ᴍᴇɴɢᴇᴅɪᴛ ᴜꜱᴇʀ! \n\n" .
                "©ᴘʀᴏᴛᴇᴄᴛ ʙʏ @Rexzzzy_bot\n" .
                "🔐 Percobaan ilegal telah dicatat dalam log sistem."
            );
        }
    }

    /**
     * 🔒 CEK AKSES UNTUK DELETE
     * Admin ID 1 tidak boleh hapus diri sendiri
     */
    private function checkSelfDelete(Request $request, User $targetUser): void
    {
        $authUser = $request->user();

        // Admin ID 1 tidak boleh hapus akun sendiri
        if ($authUser->id === 1 && $authUser->id === $targetUser->id) {
            throw new DisplayException(
                "❌ Tidak bisa menghapus akun Anda sendiri.\n" .
                "Gunakan user lain untuk mengelola sistem."
            );
        }
    }

    /**
     * Display user index page.
     * User biasa hanya bisa melihat dirinya sendiri
     */
    public function index(Request $request): View
    {
        $authUser = $request->user();

        $query = User::query()
            ->select('users.*')
            ->selectRaw('COUNT(DISTINCT(subusers.id)) as subuser_of_count')
            ->selectRaw('COUNT(DISTINCT(servers.id)) as servers_count')
            ->leftJoin('subusers', 'subusers.user_id', '=', 'users.id')
            ->leftJoin('servers', 'servers.owner_id', '=', 'users.id')
            ->groupBy('users.id');

        // Jika bukan admin ID 1, hanya tampilkan dirinya sendiri
        if ($authUser->id !== 1) {
            $query->where('users.id', $authUser->id);
        }

        $users = QueryBuilder::for($query)
            ->allowedFilters(['username', 'email', 'uuid'])
            ->allowedSorts(['id', 'uuid'])
            ->paginate(50);

        return $this->view->make('admin.users.index', ['users' => $users]);
    }

    /**
     * Display new user page.
     */
    public function create(): View
    {
        $user = auth()->user();

        // Hanya admin ID 1 yang bisa membuat user baru
        if ($user->id !== 1) {
            throw new DisplayException(
                "🚫 ᴀᴋꜱᴇꜱ ᴅɪᴛᴏʟᴀᴋ: ʜᴀɴʏᴀ ᴀᴅᴍɪɴ ɪᴅ 1 ʏᴀɴɢ ᴅᴀᴘᴀᴛ ᴍᴇᴍʙᴜᴀᴛ ᴜꜱᴇʀ ʙᴀʀᴜ!\n" .
                "©ᴘʀᴏᴛᴇᴄᴛ ʙʏ @Rexzzzy_bot"
            );
        }

        return $this->view->make('admin.users.new', [
            'languages' => $this->getAvailableLanguages(true),
        ]);
    }

    /**
     * Display user view page.
     */
    public function view(User $user): View
    {
        $authUser = auth()->user();

        // User biasa hanya bisa melihat dirinya sendiri
        if ($authUser->id !== 1 && $authUser->id !== $user->id) {
            throw new DisplayException(
                "🚫 ᴀᴋꜱᴇꜱ ᴅɪᴛᴏʟᴀᴋ: ʜᴀɴʏᴀ ᴀᴅᴍɪɴ ɪᴅ 1 ʏᴀɴɢ ᴅᴀᴘᴀᴛ ᴍᴇʟɪʜᴀᴛ ᴅᴀᴛᴀ ᴜꜱᴇʀ ʟᴀɪɴ!\n" .
                "©ᴘʀᴏᴛᴇᴄᴛ ʙʏ @Rexzzzy_bot"
            );
        }

        return $this->view->make('admin.users.view', [
            'user' => $user,
            'languages' => $this->getAvailableLanguages(true),
        ]);
    }

    /**
 * 🗑️ DELETE USER — FULL PROTECTION (GUI + API)
 * 
 * @throws DisplayException
 */
public function delete(Request $request, User $user): RedirectResponse
{
    // 🔒 LAPIS 1: Cek super admin access (hanya ID 1)
    $this->checkSuperAdminAccess($request, $user);
    
    // 🔒 LAPIS 2: Cek jangan sampai hapus diri sendiri
    $this->checkSelfDelete($request, $user);

    // 🔒 LAPIS 3: Logging siapa yang menghapus user
    $authUser = $request->user();
    IlluminateSupportFacadesLog::channel('daily')->info('🗑️ USER DELETION', [
        'deleted_by_id' => $authUser->id,
        'deleted_by_username' => $authUser->username,
        'deleted_by_email' => $authUser->email,
        'target_user_id' => $user->id,
        'target_username' => $user->username,
        'target_email' => $user->email,
        'ip' => $request->ip(),
        'time' => now()->toDateTimeString(),
    ]);

    // Jalankan penghapusan user
    $this->deletionService->handle($user);

    $this->alert->success("🗑️ User '" . $user->username . "' berhasil dihapus.")->flash();
    
    return redirect()->route('admin.users');
}

/**
 * Create a user.
 * Hanya admin ID 1 yang bisa membuat user admin
 */
public function store(NewUserFormRequest $request): RedirectResponse
{
    $authUser = $request->user();
    $data = $request->normalize();

    // Jika user bukan admin ID 1 dan mencoba membuat user admin
    if ($authUser->id !== 1 && isset($data['root_admin']) && $data['root_admin'] == true) {
        throw new DisplayException(
            "🚫 ᴀᴋꜱᴇꜱ ᴅɪᴛᴏʟᴀᴋ: ʜᴀɴʏᴀ ᴀᴅᴍɪɴ ɪᴅ 1 ʏᴀɴɢ ᴅᴀᴘᴀᴛ ᴍᴇᴍʙᴜᴀᴛ ᴜꜱᴇʀ ᴀᴅᴍɪɴ!\n" .
            "©ᴘʀᴏᴛᴇᴄᴛ ʙʏ @Rexzzzy_bot"
        );
    }

    // Semua user selain ID 1 akan selalu membuat user biasa
    if ($authUser->id !== 1) {
        $data['root_admin'] = false;
    }

    // Buat user baru
    $user = $this->creationService->handle($data);

    $this->alert->success("✅ Akun user '" . $user->username . "' berhasil dibuat.")->flash();
    
    return redirect()->route('admin.users.view', $user->id);
}

   /**
 * Update a user on the system.
 * Hanya admin ID 1 yang bisa mengupdate user lain
 *
 * @throws PterodactylExceptionsModelDataValidationException
 * @throws PterodactylExceptionsRepositoryRecordNotFoundException
 */
public function update(UserFormRequest $request, User $user): RedirectResponse
{
    $authUser = $request->user();

    // Cek akses update
    if ($authUser->id !== 1) {
        
        // User biasa hanya bisa update dirinya sendiri, tapi tidak bisa ubah role admin
        if ($authUser->id !== $user->id) {
            throw new DisplayException(
                "Akses ditolak: Hanya admin ID 1 yang dapat mengubah data user lain!
" .
                "Protect By @Rexzzzy_bot"
            );
        }
    }

    // Cegah user biasa mengubah field sensitif
    $restrictedFields = ['email', 'first_name', 'last_name', 'password', 'root_admin'];
    
    foreach ($restrictedFields as $field) {
        if ($request->filled($field) && $authUser->id !== 1) {
            throw new DisplayException(
                "Field " . $field . " hanya bisa diubah oleh admin ID 1.
" .
                "Protect By @Rexzzzy_bot"
            );
        }
    }

    // Cegah user biasa menurunkan hak admin
    if ($user->root_admin && $authUser->id !== 1) {
        throw new DisplayException(
            "Akses ditolak: Hanya admin ID 1 yang dapat menurunkan hak admin user ini!
" .
            "Protect By @Rexzzzy_bot"
        );
    }

    // Hapus root_admin dari request agar user biasa tidak bisa ubah level
    $data = $request->normalize();
    if ($authUser->id !== 1) {
        unset($data['root_admin']);
    }

    // Log aktivitas update
    IlluminateSupportFacadesLog::channel('daily')->info('USER UPDATE', [
        'updated_by_id' => $authUser->id,
        'updated_by_username' => $authUser->username,
        'target_user_id' => $user->id,
        'target_username' => $user->username,
        'fields' => array_keys($data),
        'ip' => $request->ip(),
        'time' => now()->toDateTimeString(),
    ]);

    $this->updateService
        ->setUserLevel(User::USER_LEVEL_ADMIN)
        ->handle($user, $data);

    $this->alert->success(trans('admin/user.notices.account_updated'))->flash();

    return redirect()->route('admin.users.view', $user->id);
}

/**
 * Get a JSON response of users on the system.
 * Untuk API endpoint (PLTA)
 */
public function json(Request $request): Model|Collection
{
    $authUser = $request->user();
    
    // Proteksi untuk API endpoint
    if ($authUser->id !== 1) {
        IlluminateSupportFacadesLog::channel('daily')->warning('API USER ACCESS ATTEMPT', [
            'user_id' => $authUser->id,
            'username' => $authUser->username,
            'ip' => $request->ip(),
            'time' => now()->toDateTimeString(),
        ]);
        
        throw new DisplayException(
            "Akses ditolak: Hanya admin ID 1 yang dapat mengakses API user!
" .
            "Protect By @Rexzzzy_bot"
        );
    }

    $users = QueryBuilder::for(User::query())->allowedFilters(['email'])->paginate(25);

    // Handle single user requests.
    if ($request->query('user_id')) {
        $user = User::query()->findOrFail($request->input('user_id'));
        $user->md5 = md5(strtolower($user->email));

        return $user;
    }

    return $users->map(function ($item) {
        $item->md5 = md5(strtolower($item->email));
        return $item;
    });
}
}
EOF

echo "✅ Selesai: proteksi aktif tanpa ubah teks!"
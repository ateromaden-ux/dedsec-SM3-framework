<?php

namespace App\Http\Middleware;

use App\Models\Guru;
use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

class ApiTokenAuth
{
    public function handle(Request $request, Closure $next): Response
    {
        $token = $request->bearerToken();

        if (! $token) {
            return response()->json(['message' => 'Token tidak ditemukan.'], 401);
        }

        $guru = Guru::where('api_token', hash('sha256', $token))->first();

        if (! $guru) {
            return response()->json(['message' => 'Token tidak valid atau sudah kadaluarsa.'], 401);
        }

        // Inject guru ke request agar bisa diakses di controller
        $request->merge(['_authenticated_guru' => $guru]);
        $request->setUserResolver(fn () => $guru);

        return $next($request);
    }
}

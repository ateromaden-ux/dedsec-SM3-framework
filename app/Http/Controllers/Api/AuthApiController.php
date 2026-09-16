<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Guru;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class AuthApiController extends Controller
{
    /**
     * Login guru dan kembalikan API token.
     */
    public function login(Request $request): JsonResponse
    {
        $data = $request->validate([
            'email'    => ['required', 'email'],
            'password' => ['required', 'string'],
        ]);

        $guru = Guru::where('email', $data['email'])->first();

        if (! $guru || ! Hash::check($data['password'], $guru->password)) {
            return response()->json([
                'message' => 'Email atau password salah.',
            ], 401);
        }

        // Buat plain token, simpan hashed
        $plainToken = Str::random(60);
        $guru->update(['api_token' => hash('sha256', $plainToken)]);

        return response()->json([
            'message' => 'Login berhasil.',
            'token'   => $plainToken,
            'guru'    => [
                'id_guru'        => $guru->id_guru,
                'nama_guru'      => $guru->nama_guru ?? $guru->email,
                'email'          => $guru->email,
                'mata_pelajaran' => $guru->mata_pelajaran,
            ],
        ]);
    }

    /**
     * Logout: hapus API token.
     */
    public function logout(Request $request): JsonResponse
    {
        $guru = $request->user();
        if ($guru) {
            $guru->update(['api_token' => null]);
        }

        return response()->json(['message' => 'Logout berhasil.']);
    }

    /**
     * Info guru yang sedang login.
     */
    public function me(Request $request): JsonResponse
    {
        $guru = $request->user();

        return response()->json([
            'id_guru'        => $guru->id_guru,
            'nama_guru'      => $guru->nama_guru ?? $guru->email,
            'email'          => $guru->email,
            'mata_pelajaran' => $guru->mata_pelajaran,
        ]);
    }
}

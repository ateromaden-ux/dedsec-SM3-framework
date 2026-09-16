<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;

class Guru extends Authenticatable
{
    use Notifiable;

    protected $table = 'guru';
    protected $primaryKey = 'id_guru';

    protected $fillable = [
        'email',
        'password',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'password' => 'hashed',
        ];
    }

    public function kuis(): HasMany
    {
        return $this->hasMany(Kuis::class, 'id_guru', 'id_guru');
    }

    public function materi(): HasMany
    {
        return $this->hasMany(MateriBelajar::class, 'id_guru', 'id_guru');
    }
}

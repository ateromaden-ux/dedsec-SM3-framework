<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class MateriBelajar extends Model
{
    protected $table = 'materi_belajar';
    protected $primaryKey = 'id_materi';

    protected $fillable = [
        'id_guru',
        'kategori',
        'judul_materi',
        'level_materi',
        'deskripsi',
        'konten',
    ];

    public function guru(): BelongsTo
    {
        return $this->belongsTo(Guru::class, 'id_guru', 'id_guru');
    }

    public function kuis(): HasMany
    {
        return $this->hasMany(Kuis::class, 'id_materi', 'id_materi');
    }
}

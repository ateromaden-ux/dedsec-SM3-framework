<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Kuis extends Model
{
    protected $table = 'kuis';
    protected $primaryKey = 'id_kuis';

    protected $fillable = [
        'id_guru',
        'id_materi',
        'judul_kuis',
        'deskripsi',
        'jumlah_soal',
        'batas_lulus',
        'status',
    ];

    public function guru(): BelongsTo
    {
        return $this->belongsTo(Guru::class, 'id_guru', 'id_guru');
    }

    public function materi(): BelongsTo
    {
        return $this->belongsTo(MateriBelajar::class, 'id_materi', 'id_materi');
    }

    public function soal(): HasMany
    {
        return $this->hasMany(Soal::class, 'id_kuis', 'id_kuis');
    }
}

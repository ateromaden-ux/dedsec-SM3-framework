<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PilihanJawaban extends Model
{
    protected $table = 'pilihan_jawaban';
    protected $primaryKey = 'id_pilihan';

    protected $fillable = [
        'id_soal',
        'label_pilihan',
        'isi_pilihan',
        'is_benar',
        'penjelasan',
    ];

    protected $casts = [
        'is_benar' => 'boolean',
    ];

    public function soal(): BelongsTo
    {
        return $this->belongsTo(Soal::class, 'id_soal', 'id_soal');
    }
}

<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Soal extends Model
{
    protected $table = 'soal';
    protected $primaryKey = 'id_soal';

    protected $fillable = [
        'id_kuis',
        'pertanyaan',
        'poin',
        'urutan',
    ];

    public function kuis(): BelongsTo
    {
        return $this->belongsTo(Kuis::class, 'id_kuis', 'id_kuis');
    }

    public function pilihanJawaban(): HasMany
    {
        return $this->hasMany(PilihanJawaban::class, 'id_soal', 'id_soal');
    }
}

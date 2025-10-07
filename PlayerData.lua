-- PlayerData.lua (Script)
-- Path: ServerScriptService/PlayerData.lua
-- Deskripsi: Skrip ini menginisialisasi DataStoreManager untuk memulai penanganan data pemain.

-- Memuat modul DataStoreManager agar sistemnya aktif
local ServerScriptService = game:GetService("ServerScriptService")
local DataStoreManager = require(ServerScriptService.DataStoreManager)

-- Tidak ada logika lain yang diperlukan di sini, karena DataStoreManager
-- sudah menangani semua event pemain secara internal.
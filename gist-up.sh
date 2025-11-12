#!/bin/bash

# Colors (sesuai preferensi biru-ungu)
C_RST='\e[0m'
C_HDR='\e[1;35m'
C_OK='\e[1;34m'
C_INFO='\e[0;35m'
C_WARN='\e[1;33m'
C_ERR='\e[1;31m'

print_banner() {
    echo -e "${C_HDR}"
    echo "  ██████╗ ██╗███████╗████████╗ █████╗ ██████╗ ██╗     "
    echo "  ██╔══██╗██║██╔════╝╚══██╔══╝██╔══██╗██╔══██╗██║     "
    echo "  ██║  ██║██║███████╗   ██║   ███████║██████╔╝██║     "
    echo "  ██║  ██║██║╚════██║   ██║   ██╔══██║██╔══██╗██║     "
    echo "  ██████╔╝██║███████║   ██║   ██║  ██║██████╔╝███████╗"
    echo "  ╚═════╝ ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝"
    echo -e "           GitHub Gist Manager — Upload & Switch${C_RST}\n"
}

log() { echo -e "${C_INFO}➤ $1${C_RST}"; }
success() { echo -e "${C_OK}✔ $1${C_RST}"; }
warning() { echo -e "${C_WARN}⚠ $1${C_RST}"; }
error() { echo -e "${C_ERR}✘ $1${C_RST}"; }

AUTH_FILE="$HOME/.gist-auth"

# Fungsi: simpan token
save_token() {
    read -s -p "Masukkan GitHub Personal Access Token (hanya perlu 'gist' scope): " token
    echo
    if [[ -z "$token" ]]; then
        error "Token tidak boleh kosong."
        exit 1
    fi
    echo "$token" > "$AUTH_FILE"
    chmod 600 "$AUTH_FILE"
    success "Token disimpan di $AUTH_FILE"
}

# Fungsi: upload file
upload_gist() {
    if [[ ! -f "$AUTH_FILE" ]]; then
        log "Token belum tersedia. Silakan simpan dulu."
        save_token
    fi

    read -e -p "Masukkan path file yang mau diupload: " filepath
    if [[ ! -f "$filepath" ]]; then
        error "File tidak ditemukan: $filepath"
        return 1
    fi

    FILENAME=$(basename "$filepath")
    CONTENT=$(cat "$filepath")
    TOKEN=$(cat "$AUTH_FILE" | tr -d '\n\t ')

    log "Membuat Gist untuk: $FILENAME"
    JSON=$(jq -n --arg desc "Uploaded via gist-manager" \
               --arg fname "$FILENAME" \
               --arg cont "$CONTENT" \
               '{"description": $desc, "public": true, "files": {($fname): {"content": $cont}}}')

    RESPONSE=$(curl -s -X POST \
        -H "Authorization: token $TOKEN" \
        -H "Content-Type: application/json" \
        -d "$JSON" \
        https://api.github.com/gists)

    if echo "$RESPONSE" | jq -e '.html_url // empty' >/dev/null 2>&1; then
        GIST_URL=$(echo "$RESPONSE" | jq -r '.html_url')
        RAW_URL=$(echo "$RESPONSE" | jq -r ".files.\"$FILENAME\".raw_url")
        echo
        success "Upload berhasil!"
        echo -e "${C_HDR}🌐 Halaman: ${C_RST}$GIST_URL"
        echo -e "${C_HDR}📥 Raw URL: ${C_RST}$RAW_URL"
        echo
        echo -e "${C_INFO}Contoh penggunaan di VPS:${C_RST}"
        echo "curl -s '$RAW_URL' | sudo bash"
    else
        error "Gagal membuat Gist."
        echo "Detail error:"
        echo "$RESPONSE" | jq .
    fi
}

# Fungsi: ganti akun (hapus token)
switch_account() {
    if [[ -f "$AUTH_FILE" ]]; then
        rm -f "$AUTH_FILE"
        success "Token lama dihapus. Akun siap diganti."
    else
        log "Tidak ada token tersimpan."
    fi
    save_token
}

# Menu utama
while true; do
    clear
    print_banner
    echo -e "${C_HDR}[ Menu Gist Manager ]${C_RST}"
    echo "1. Upload file ke Gist"
    echo "2. Ganti akun GitHub"
    echo "3. Keluar"
    echo
    read -p "Pilih menu (1-3): " choice

    case $choice in
        1)
            upload_gist
            echo; read -p "Tekan Enter untuk kembali ke menu..."
            ;;
        2)
            switch_account
            echo; read -p "Tekan Enter untuk kembali ke menu..."
            ;;
        3)
            echo "Sampai jumpa! 🚀"
            exit 0
            ;;
        *)
            warning "Pilihan tidak valid."
            sleep 1
            ;;
    esac
done

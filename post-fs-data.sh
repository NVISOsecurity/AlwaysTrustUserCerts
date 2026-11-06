# Certificates are collected during post-fs-data so that they are auto-mounted on top of /system for non-conscrypt devices
MODDIR=${0%/*}
SYS_CERT_DIR=/system/etc/security/cacerts

log() {
    echo "$(date '+%m-%d %H:%M:%S ')" "$@" >> $MODDIR/log.txt
}

# Android stores user CAs as DER, but BoringSSL-based stacks that read the
# cacerts directory directly (e.g. Flutter/Dart's dart:io) only accept PEM.
copy_cert_as_pem(){
    if grep -q -- "-----BEGIN CERTIFICATE-----" "$1"; then
        cp "$1" "$2"
    else
        {
            echo "-----BEGIN CERTIFICATE-----"
            base64 < "$1" | tr -d '\n' | fold -w 64
            echo
            echo "-----END CERTIFICATE-----"
        } > "$2"
    fi
}

collect_user_certs(){

    mkdir -p $MODDIR$SYS_CERT_DIR

    # Clean directory so that deleted certs actually disappear
    rm -rf $MODDIR$SYS_CERT_DIR/*

    log "Grabbing user certs"
    # Add the user-defined certs, looping over all available users
    for dir in /data/misc/user/*; do
        if [ -d "$dir/cacerts-added" ]; then
            for cert in "$dir/cacerts-added"/*; do
                copy_cert_as_pem "$cert" "$MODDIR$SYS_CERT_DIR/$(basename "$cert")"
                log "Grabbing user cert: $(basename "$cert")"
            done
        fi
    done
}

main(){
    echo "" > $MODDIR/log.txt
    log "MagiskTrustUserCerts - post-fs-data.sh"

    collect_user_certs

    log "Grabbing /system certs"
    cp $SYS_CERT_DIR/* $MODDIR$SYS_CERT_DIR
}
main

#!/usr/bin/env bash
# SDD/tests/test_secret_scan.sh — AC6bis (contract v2/v3, rondas 2-3 de R0):
# secret-scan.sh detecta las cinco formas reales de secreto, cada una en su
# propio caso, probada por mutación (plantar -> rojo -> remover -> verde).
#
# La ronda 1 midió que la implementación sólo detectaba la forma 5 (PEM) y
# una variante con comillas: dejaba pasar api_key= sin comillas, PASSWORD=
# en SCREAMING_SNAKE, AWS_SECRET_ACCESS_KEY= sin comillas y GITHUB_TOKEN
# con separador ":". Este archivo prueba las cinco explícitamente.
#
# forma 6 (ronda 3): un secreto plantado bajo SDD/contracts/ DENTRO DEL REPO
# TEMPORAL tiene que poner el scan rojo. En v2, secret-scan.sh excluía
# SDD/contracts/ del repo REAL entero (por un falso positivo del propio
# contract, ya corregido en v3 partiendo sus literales) — v3 prohíbe
# cualquier exclusión por path. Este caso es el AC de detección aplicado a
# la exclusión misma: si alguien reintroduce un path a una lista de
# exclusión, este caso se pone rojo.
#
# plant_kv arma "<clave><separador><valor>" a partir de TRES argumentos bash
# separados a propósito: si la cadena completa quedara contigua en ESTE
# archivo fuente, secret-scan.sh se autodetectaría al escanearse a sí mismo
# (test_secret_scan.sh no está en su lista de exclusión — sólo secret-scan.sh
# lo está, por la misma razón autorreferencial; ninguna exclusión por path
# existe desde v3). Cada argumento queda separado por un espacio+comillas en
# el CÓDIGO FUENTE (no hay forma de que "clave<separador>" aparezca contiguo
# en el archivo), pero bash los concatena en un solo string al ejecutar
# `printf '%s%s%s'`.

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=SDD/tests/lib.sh
. "$SCRIPT_DIR/lib.sh"

SECRET_SCAN="$SCRIPT_DIR/secret-scan.sh"
TMP_DIR="$SCRIPT_DIR/.tmp/test_secret_scan-$$"

# shellcheck disable=SC2329  # invocada por trap EXIT
cleanup() { rm -rf "$TMP_DIR"; }
trap cleanup EXIT

mkdir -p "$TMP_DIR"
git init -q "$TMP_DIR"
printf 'fixture de test_secret_scan.sh — sin secretos\n' > "$TMP_DIR/README.md"
( cd "$TMP_DIR" && git add -A )

run_scan() { ( cd "$TMP_DIR" && bash "$SECRET_SCAN" ); }

# plant_kv <archivo> <clave> <separador> <valor> — ver nota de arriba.
plant_kv() {
  printf '%s%s%s\n' "$2" "$3" "$4" > "$TMP_DIR/$1"
  ( cd "$TMP_DIR" && git add -A )
}

remove_fixture() {
  rm -f "$TMP_DIR/$1"
  ( cd "$TMP_DIR" && git add -A )
}

# --- baseline: árbol sin secretos ---------------------------------------
out_baseline="$(run_scan 2>&1)"; ec_baseline=$?
assert_exit 0 "$ec_baseline" "secret-scan.sh sale limpio sobre un arbol sin secretos"
assert_contains "$out_baseline" "sin hallazgos" "secret-scan.sh sale limpio sobre un arbol sin secretos"

# --- forma 1: variable api_key, valor SIN comillas, clave en minuscula --
run_scan >/dev/null 2>&1; ec1_before=$?
assert_exit 0 "$ec1_before" "forma1 api_key sin comillas - verde antes de plantar"

plant_kv "form1.env" "api_key" "=" "sk_live_51H8xQ2abcdefg"
out1_red="$(run_scan 2>&1)"; ec1_red=$?
assert_exit 1 "$ec1_red" "forma1 api_key sin comillas - rojo al plantar"
assert_contains "$out1_red" "form1.env" "forma1 api_key sin comillas - rojo al plantar"

remove_fixture "form1.env"
run_scan >/dev/null 2>&1; ec1_after=$?
assert_exit 0 "$ec1_after" "forma1 api_key sin comillas - verde tras remover"

# --- forma 2: variable PASSWORD (SCREAMING_SNAKE), valor CON comillas ---
run_scan >/dev/null 2>&1; ec2_before=$?
assert_exit 0 "$ec2_before" "forma2 PASSWORD screaming-snake con comillas - verde antes de plantar"

plant_kv "form2.env" "PASSWORD" "=" "\"hunter2xyz\""
out2_red="$(run_scan 2>&1)"; ec2_red=$?
assert_exit 1 "$ec2_red" "forma2 PASSWORD screaming-snake con comillas - rojo al plantar"
assert_contains "$out2_red" "form2.env" "forma2 PASSWORD screaming-snake con comillas - rojo al plantar"

remove_fixture "form2.env"
run_scan >/dev/null 2>&1; ec2_after=$?
assert_exit 0 "$ec2_after" "forma2 PASSWORD screaming-snake con comillas - verde tras remover"

# --- forma 3: variable AWS_SECRET_ACCESS_KEY, SIN comillas, mayusculas --
run_scan >/dev/null 2>&1; ec3_before=$?
assert_exit 0 "$ec3_before" "forma3 AWS_SECRET_ACCESS_KEY sin comillas - verde antes de plantar"

plant_kv "form3.env" "AWS_SECRET_ACCESS_KEY" "=" "wJalrXUtnFEMI/K7MDENG"
out3_red="$(run_scan 2>&1)"; ec3_red=$?
assert_exit 1 "$ec3_red" "forma3 AWS_SECRET_ACCESS_KEY sin comillas - rojo al plantar"
assert_contains "$out3_red" "form3.env" "forma3 AWS_SECRET_ACCESS_KEY sin comillas - rojo al plantar"

remove_fixture "form3.env"
run_scan >/dev/null 2>&1; ec3_after=$?
assert_exit 0 "$ec3_after" "forma3 AWS_SECRET_ACCESS_KEY sin comillas - verde tras remover"

# --- forma 4: variable GITHUB_TOKEN, separador dos puntos ---------------
run_scan >/dev/null 2>&1; ec4_before=$?
assert_exit 0 "$ec4_before" "forma4 GITHUB_TOKEN separador dos puntos - verde antes de plantar"

plant_kv "form4.env" "GITHUB_TOKEN" ": " "ghp_16CharactersLongToken00"
out4_red="$(run_scan 2>&1)"; ec4_red=$?
assert_exit 1 "$ec4_red" "forma4 GITHUB_TOKEN separador dos puntos - rojo al plantar"
assert_contains "$out4_red" "form4.env" "forma4 GITHUB_TOKEN separador dos puntos - rojo al plantar"

remove_fixture "form4.env"
run_scan >/dev/null 2>&1; ec4_after=$?
assert_exit 0 "$ec4_after" "forma4 GITHUB_TOKEN separador dos puntos - verde tras remover"

# --- forma 5: clave privada PEM ------------------------------------------
run_scan >/dev/null 2>&1; ec5_before=$?
assert_exit 0 "$ec5_before" "forma5 clave privada PEM - verde antes de plantar"

# Mismo motivo que plant_kv: "-----BEGIN ... PRIVATE KEY-----" completo no
# puede quedar contiguo en este archivo fuente. Se parte entre "PRIVATE" y
# "KEY-----" (dos piezas bash separadas -> el espacio queda del lado de la
# primera pieza, "KEY-----" nunca aparece pegado a "PRIVATE" en el fuente).
{
  printf '%s%s\n' "-----BEGIN RSA PRIVATE " "KEY-----"
  printf 'MIIBVQIBADANBgkqhkiG9w0BAQEFAASCAT8wggE7AgEAAkEA1234567890abcdefgh\n'
  printf '%s%s\n' "-----END RSA PRIVATE " "KEY-----"
} > "$TMP_DIR/form5.pem"
( cd "$TMP_DIR" && git add -A )

out5_red="$(run_scan 2>&1)"; ec5_red=$?
assert_exit 1 "$ec5_red" "forma5 clave privada PEM - rojo al plantar"
assert_contains "$out5_red" "form5.pem" "forma5 clave privada PEM - rojo al plantar"

remove_fixture "form5.pem"
run_scan >/dev/null 2>&1; ec5_after=$?
assert_exit 0 "$ec5_after" "forma5 clave privada PEM - verde tras remover"

# --- forma 6 (ronda 3): secreto bajo SDD/contracts/ tiene que dar rojo -----
# Regresión exacta que motivó esta ronda: v2 excluía SDD/contracts/ entero
# del escaneo. v3 prohíbe cualquier exclusión por path — este caso planta un
# secreto en un archivo bajo SDD/contracts/ DENTRO DEL REPO TEMPORAL (nunca
# toca el SDD/contracts/ real) y exige rojo. Si mañana alguien reintroduce
# una exclusión por path en secret-scan.sh, este caso la atrapa.
run_scan >/dev/null 2>&1; ec6_before=$?
assert_exit 0 "$ec6_before" "forma6 secreto bajo SDD-contracts - verde antes de plantar"

mkdir -p "$TMP_DIR/SDD/contracts"
plant_kv "SDD/contracts/2026-09-01-nueva-feature.md" "api_key" "=" "sk_live_51H8xQ2abcdefg"
out6_red="$(run_scan 2>&1)"; ec6_red=$?
assert_exit 1 "$ec6_red" "forma6 secreto bajo SDD-contracts - rojo al plantar"
assert_contains "$out6_red" "SDD/contracts/2026-09-01-nueva-feature.md" "forma6 secreto bajo SDD-contracts - rojo al plantar"

remove_fixture "SDD/contracts/2026-09-01-nueva-feature.md"
run_scan >/dev/null 2>&1; ec6_after=$?
assert_exit 0 "$ec6_after" "forma6 secreto bajo SDD-contracts - verde tras remover"

# --- formas 7 a 9 (GEN-108 v26, AC59): certificados públicos ---------------
# El literal con forma de clave de AWS se arma en dos piezas, por el mismo
# motivo que plant_kv: escrito entero, este archivo fuente se detectaría a sí
# mismo.
CLAVE_AWS="$(printf '%s%s' 'AK' 'IAQWERTYUIOPASDFGH')"
INICIO_CERT='-----BEGIN CERTIFICATE-----'
FIN_CERT='-----END CERTIFICATE-----'

# forma 7: el patrón dentro de una línea base64 de un certificado -> verde.
{
  printf '%s\n' "$INICIO_CERT"
  printf 'MIIEBjCCAu6gAwIBAgIJ%sQWERTYzAN\n' "$CLAVE_AWS"
  printf '%s\n' "$FIN_CERT"
} > "$TMP_DIR/form7.pem"
( cd "$TMP_DIR" && git add -A )
run_scan >/dev/null 2>&1; ec7=$?
assert_exit 0 "$ec7" "forma7 base64 de un certificado con forma de clave AWS - verde (es un certificado público)"
remove_fixture "form7.pem"

# forma 8: la misma línea FUERA de un bloque de certificado -> rojo.
printf 'MIIEBjCCAu6gAwIBAgIJ%sQWERTYzAN\n' "$CLAVE_AWS" > "$TMP_DIR/form8.txt"
( cd "$TMP_DIR" && git add -A )
out8="$(run_scan 2>&1)"; ec8=$?
assert_exit 1 "$ec8" "forma8 la misma línea fuera de un certificado - rojo"
assert_contains "$out8" "form8.txt" "forma8 la misma línea fuera de un certificado - rojo"
remove_fixture "form8.txt"

# forma 9: dentro del bloque, una línea que NO es base64 se sigue escaneando.
{
  printf '%s\n' "$INICIO_CERT"
  printf 'aws_key = %s\n' "$CLAVE_AWS"
  printf '%s\n' "$FIN_CERT"
} > "$TMP_DIR/form9.pem"
( cd "$TMP_DIR" && git add -A )
out9="$(run_scan 2>&1)"; ec9=$?
assert_exit 1 "$ec9" "forma9 una línea que no es base64 dentro de un certificado - rojo"
assert_contains "$out9" "form9.pem:2:" "forma9 el número de línea es el del archivo"
remove_fixture "form9.pem"

# --- formas 10 a 13 (review de v26, ronda 1): los huecos de la primera regla -
# Los literales con forma de secreto se arman en piezas, como arriba.
CLAVE_PASS="$(printf '%s%s' 'pass' 'word=Sup3rS3cret99')"
CLAVE_SEC="$(printf '%s%s' 'SEC' 'RET=abcd1234efgh')"

# forma 10: BEGIN sin END. Lo que viene después se escanea -> rojo, con su
# línea. Con la primera versión de AC59, el resto del archivo quedaba sin
# escanear.
{
  printf '%s\n' "$INICIO_CERT"
  printf 'MIIEBjCCAu6gAwIBAgIJ\n'
  printf '%s\n' "$CLAVE_SEC"
  printf '%s\n' "$CLAVE_AWS"
} > "$TMP_DIR/form10.md"
( cd "$TMP_DIR" && git add -A )
out10="$(run_scan 2>&1)"; ec10=$?
assert_exit 1 "$ec10" "forma10 un BEGIN sin END no apaga el scan del resto del archivo - rojo"
assert_contains "$out10" "form10.md:3:" "forma10 detecta la clave=valor después del BEGIN sin END"
assert_contains "$out10" "form10.md:4:" "forma10 detecta la clave AWS sola en su línea después del BEGIN sin END"
remove_fixture "form10.md"

# forma 11: clave=valor alfanumérico dentro de un bloque CERRADO -> rojo. No
# es base64: el `=` va en el medio.
{
  printf '%s\n' "$INICIO_CERT"
  printf '%s\n' "$CLAVE_PASS"
  printf '%s\n' "$FIN_CERT"
} > "$TMP_DIR/form11.pem"
( cd "$TMP_DIR" && git add -A )
out11="$(run_scan 2>&1)"; ec11=$?
assert_exit 1 "$ec11" "forma11 clave=valor dentro de un certificado cerrado - rojo (no es base64)"
assert_contains "$out11" "form11.pem:2:" "forma11 el número de línea es el del archivo"
remove_fixture "form11.pem"

# forma 12: un binario se sigue salteando, como antes de AC59.
printf 'bin\000ario\n%s\n' "$CLAVE_AWS" > "$TMP_DIR/form12.bin"
( cd "$TMP_DIR" && git add -A )
run_scan >/dev/null 2>&1; ec12=$?
assert_exit 0 "$ec12" "forma12 un binario no se escanea, igual que antes de AC59"
remove_fixture "form12.bin"

# forma 13: un certificado con CRLF se reconoce igual -> verde.
{
  printf '%s\r\n' "$INICIO_CERT"
  printf 'MIIEBjCCAu6gAwIBAgIJ%sQWERTYzAN\r\n' "$CLAVE_AWS"
  printf '%s\r\n' "$FIN_CERT"
} > "$TMP_DIR/form13.pem"
( cd "$TMP_DIR" && git add -A )
run_scan >/dev/null 2>&1; ec13=$?
assert_exit 0 "$ec13" "forma13 un certificado con CRLF se reconoce - verde"
remove_fixture "form13.pem"

# forma 14: un PEM truncado, una clave AWS sola en su línea y después un
# certificado completo -> rojo en la línea de la clave. El BEGIN del segundo
# no puede estirar el primero hasta su END.
{
  printf '%s\n' "$INICIO_CERT"
  printf 'MIIEBjCCAu6gAwIBAgIJ\n'
  printf 'texto de un ejemplo truncado\n'
  printf '%s\n' "$CLAVE_AWS"
  printf '%s\n' "$INICIO_CERT"
  printf 'MIIEBjCCAu6gAwIBAgIJ\n'
  printf '%s\n' "$FIN_CERT"
} > "$TMP_DIR/form14.md"
( cd "$TMP_DIR" && git add -A )
out14="$(run_scan 2>&1)"; ec14=$?
assert_exit 1 "$ec14" "forma14 un PEM truncado seguido de uno completo no forma un solo bloque - rojo"
assert_contains "$out14" "form14.md:4:" "forma14 detecta la clave AWS entre los dos bloques"
remove_fixture "form14.md"

run_scan >/dev/null 2>&1; ec_final=$?
assert_exit 0 "$ec_final" "secret-scan.sh sale limpio tras remover las formas 7 a 14"

test_summary
exit $?

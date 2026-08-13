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

test_summary
exit $?

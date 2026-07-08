#!/bin/bash
#SBATCH --job-name=elm_regrid
#SBATCH --account=e3sm
#SBATCH --partition=compute
#SBATCH --nodes=1
#SBATCH --time=02:00:00
#SBATCH --output=regrid_%j.log
#SBATCH --error=regrid_%j.err

set -euo pipefail

# =============================
# CONFIG: override with environment variables as needed
# =============================
OUT_AGG="${OUT_AGG:-agg_gridcell.nc}"                       # must exist before this runs
GRID_DIR="${GRID_DIR:-/compyfs/zhan391/v3_dart_cda_scratch/reference/regrid_maps}"
DST_SCRIP="${DST_SCRIP:-${GRID_DIR}/cmip6_180x360_scrip.20181001.nc}"  # existing destination SCRIP
SRC_SCRIP="${SRC_SCRIP:-${GRID_DIR}/src_unstruct_from_agg.scrip.nc}"   # will be created
MAP="${MAP:-${GRID_DIR}/map_unstruct_r05_to_cmip6_180x360_aave.c251029.nc}"
REGRID_OUT="${REGRID_OUT:-elm_180x360_aave.nc}"

# Optional: set CORNER_PERM to '0132' or '0321' if ESMF later complains about polygon areas
CORNER_PERM="${CORNER_PERM:-keep}"

mkdir -p "${GRID_DIR}"

# =============================
# Tool checks
# =============================
need(){ command -v "$1" >/dev/null 2>&1 || { echo "Missing tool: $1"; exit 1; }; }
need python
need ncdump
need ncremap
need ESMF_RegridWeightGen

# python netCDF4 check (netCDF4 is needed for the tiny Python writer below)
python - <<'PY' >/dev/null 2>&1 || { echo "Python netCDF4 not available in this env."; exit 1; }
import netCDF4, numpy as np
print("ok")
PY

# =============================
# Sanity: inputs present
# =============================
[ -f "${OUT_AGG}" ] || { echo "ERROR: ${OUT_AGG} not found. Create it first (your column->gridcell exporter)."; exit 2; }
[ -f "${DST_SCRIP}" ] || { echo "ERROR: destination SCRIP not found: ${DST_SCRIP}"; exit 2; }

# Require bounds for conservative regrid
if ! ncdump -h "${OUT_AGG}" | grep -q "lat_b(" ; then
  echo "ERROR: ${OUT_AGG} missing lat_b/lon_b; cannot do conservative regrid."
  exit 2
fi

echo "[1/4] Building unstructured SCRIP from ${OUT_AGG} -> ${SRC_SCRIP}"

# =============================
# Build SCRIP -> weights -> apply (robust & self-diagnosing)
# =============================
set -euo pipefail

OUT_AGG="${OUT_AGG:-agg_gridcell.nc}"
GRID_DIR="${GRID_DIR:-/compyfs/zhan391/v3_dart_cda_scratch/reference/regrid_maps}"
DST_SCRIP="${DST_SCRIP:-${GRID_DIR}/cmip6_180x360_scrip.20181001.nc}"
SRC_SCRIP="${SRC_SCRIP:-${GRID_DIR}/src_unstruct_from_agg.scrip.nc}"
MAP="${MAP:-${GRID_DIR}/map_unstruct_r05_to_cmip6_180x360_aave.c251029.nc}"
REGRID_OUT="${REGRID_OUT:-elm_180x360_aave.nc}"
CORNER_PERM="${CORNER_PERM:-keep}"   # set to 0132 or 0321 if ESMF complains about areas
export OMP_NUM_THREADS=${OMP_NUM_THREADS:-1}

mkdir -p "${GRID_DIR}"

need(){ command -v "$1" >/dev/null 2>&1 || { echo "Missing tool: $1"; exit 1; }; }
need python; need ncdump; need ncremap; need ESMF_RegridWeightGen

[ -f "${OUT_AGG}" ]   || { echo "ERROR: source ${OUT_AGG} not found"; exit 2; }
[ -f "${DST_SCRIP}" ] || { echo "ERROR: destination SCRIP ${DST_SCRIP} not found"; exit 2; }

# Ensure python has netCDF4
python - <<'PY' >/dev/null 2>&1 || { echo "ERROR: Python netCDF4 not importable in this env"; exit 1; }
import netCDF4, numpy as np
PY

echo "[1/4] Writing SCRIP file: ${SRC_SCRIP}"

# --- Write SCRIP with robust Python (prints clear diagnostics then exits nonzero) ---
python - <<PY
import sys, numpy as np
try:
    from netCDF4 import Dataset
except Exception as e:
    print("PYERR: import netCDF4 failed:", repr(e), file=sys.stderr); sys.exit(1)

src = r"${OUT_AGG}"
dst = r"${SRC_SCRIP}"

try:
    with Dataset(src, "r") as fin:
        # Required variables
        for nm in ("lat","lon","lat_b","lon_b"):
            if nm not in fin.variables:
                print(f"PYERR: '{nm}' not found in {src}", file=sys.stderr)
                sys.exit(2)
        lat  = fin.variables["lat"][:]      # (gridcell,)
        lon  = fin.variables["lon"][:]      # (gridcell,)
        latb = fin.variables["lat_b"][:]    # (gridcell, 4?)
        lonb = fin.variables["lon_b"][:]    # (gridcell, 4?)
        frac = fin.variables["frac"][:] if "frac" in fin.variables else None
except Exception as e:
    print("PYERR: reading source failed:", repr(e), file=sys.stderr); sys.exit(3)

# shape checks
if lat.ndim != 1 or lon.ndim != 1:
    print(f"PYERR: lat/lon must be 1D; got lat.ndim={lat.ndim}, lon.ndim={lon.ndim}", file=sys.stderr); sys.exit(4)
if latb.ndim != 2 or lonb.ndim != 2 or latb.shape[1] != lonb.shape[1]:
    print(f"PYERR: lat_b/lon_b must be 2D with same second dim; got {latb.shape} and {lonb.shape}", file=sys.stderr); sys.exit(5)
if lat.shape[0] != latb.shape[0]:
    print(f"PYERR: cell count mismatch: lat={lat.shape[0]} vs lat_b={latb.shape[0]}", file=sys.stderr); sys.exit(6)

N = lat.shape[0]
try:
    with Dataset(dst, "w", format="NETCDF3_CLASSIC") as fo:
        fo.createDimension("grid_rank", 1)
        fo.createDimension("grid_corners", latb.shape[1])
        fo.createDimension("grid_size", N)

        v_dims = fo.createVariable("grid_dims","i4",("grid_rank",))
        v_dims[:] = N

        v_clat = fo.createVariable("grid_center_lat","f4",("grid_size",))
        v_clon = fo.createVariable("grid_center_lon","f4",("grid_size",))
        v_clat.units="degrees_north"; v_clon.units="degrees_east"
        v_clat[:] = lat.astype(np.float32)
        v_clon[:] = lon.astype(np.float32)

        v_clatb = fo.createVariable("grid_corner_lat","f4",("grid_size","grid_corners"))
        v_clonb = fo.createVariable("grid_corner_lon","f4",("grid_size","grid_corners"))
        v_clatb.units="degrees_north"; v_clonb.units="degrees_east"
        v_clatb[:] = latb.astype(np.float32)
        v_clonb[:] = lonb.astype(np.float32)

        v_mask = fo.createVariable("grid_imask","i4",("grid_size",))
        if isinstance(frac, np.ndarray):
            v_mask[:] = (frac > 0.0).astype("i4")
        else:
            v_mask[:] = np.ones(N, dtype="i4")
except Exception as e:
    print("PYERR: writing SCRIP failed:", repr(e), file=sys.stderr); sys.exit(7)
PY

# If Python printed a PYERR above, the script already exited. Now verify SCRIP exists:
[ -s "${SRC_SCRIP}" ] || { echo "ERROR: SCRIP not created: ${SRC_SCRIP}"; exit 3; }
ls -lh "${SRC_SCRIP}"

# Optional corner permutation toggle
if [ "${CORNER_PERM}" != "keep" ]; then
  echo "[1a] Applying CORNER_PERM=${CORNER_PERM}"
  case "${CORNER_PERM}" in
    0132) python - <<PY
from netCDF4 import Dataset
fn=r"${SRC_SCRIP}"
with Dataset(fn,'a') as f:
  f['grid_corner_lat'][:]=f['grid_corner_lat'][:,[0,1,3,2]]
  f['grid_corner_lon'][:]=f['grid_corner_lon'][:,[0,1,3,2]]
PY
      ;;
    0321) python - <<PY
from netCDF4 import Dataset
fn=r"${SRC_SCRIP}"
with Dataset(fn,'a') as f:
  f['grid_corner_lat'][:]=f['grid_corner_lat'][:,[0,3,2,1]]
  f['grid_corner_lon'][:]=f['grid_corner_lon'][:,[0,3,2,1]]
PY
      ;;
    *) echo "WARN: unknown CORNER_PERM=${CORNER_PERM} (use keep|0132|0321)";;
  esac
fi

# Absolute paths + SCRIP: prefix (ESMF 7.1 quirk)
ABS_SRC="$(python -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "${SRC_SCRIP}")"
ABS_DST="$(python -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "${DST_SCRIP}")"
ABS_MAP="$(python -c 'import os,sys; print(os.path.abspath(sys.argv[1]))' "${MAP}")"

echo $ABS_SRC
echo $ABS_DST
echo $ABS_MAP
echo "[2/4] Generating weights -> ${ABS_MAP}"
alg_name=aave
function map_aave {
    if [ ! -e ${map} ]; then
        echo "map: ${map}"
        cmd="ncremap -a aave -s ${src_grid} -g ${dst_grid} -m ${map}"
        echo "${cmd}" && ${cmd}
    fi
}
# ocn to atm
src_grid=${ABS_SRC}
dst_grid=${ABS_DST}
map=${ABS_MAP}
map_aave

echo "[3/4] Map sanity (expect src_grid_rank=1, dst_grid_rank=2):"
ncdump -h "${ABS_MAP}" | egrep "src_grid_rank|dst_grid_rank" || true
ncremap -D 2 \
  -v T_GRND \
  -R "--rgr n_a=gridcell,lat_nm=lat,lon_nm=lon" \
  -m ${ABS_MAP} \
  -i ${OUT_AGG} \
  -o test_elm_180x360.nc


ncremap \
  -D 1 \
  -R "--rgr n_a=gridcell,lat_nm=lat,lon_nm=lon" \
  -m ${ABS_MAP} \
  -i ${OUT_AGG} \
  -o elm_180x360_aave.nc

exit

ncremap -m "${ABS_MAP}" -i "${OUT_AGG}" -o "${REGRID_OUT}"
exit

echo "[4/4] Applying weights -> ${REGRID_OUT}"
ncremap -R "--rgr lat_nm_in=lat,lon_nm_in=lon" \
        -m "${ABS_MAP}" \
        -i "${OUT_AGG}" \
        -o "${REGRID_OUT}"

echo "Done."
echo "  SCRIP: ${ABS_SRC}"
echo "  Map:   ${ABS_MAP}"
echo "  Out:   ${REGRID_OUT}"

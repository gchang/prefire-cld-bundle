# PREFIRE_CLD bundle

The PREFIRE 2B-CLD product retrieves cloud-top pressure, cloud optical depth and cloud effective diameter for cloudy polar footprints of the PREFIRE TIRS spectrometers, by optimal estimation with the PCRTM radiative transfer model. The code is split across seven repositories from the PREFIRE mission team (UW-PREFIRE). This repository holds them side by side as git submodules, each pinned to its `R01` release, so the whole algorithm can be cloned in one step:

```sh
git clone --recurse-submodules https://github.com/gchang/prefire-cld-bundle.git
```

| Submodule | Upstream | R01 commit | Role |
|---|---|---|---|
| `PREFIRE_CLD` | https://github.com/UW-PREFIRE/PREFIRE_CLD | da043c3f61165c150e81988c72f21e3a59d5441c | the 2B-CLD product code (`dist/produce_L2.py`) |
| `PREFIRE_ATM` | https://github.com/UW-PREFIRE/PREFIRE_ATM | 75981c4f9c8c3561bedd2aeead6601c007999474 | the optimal-estimation solver and input readers |
| `PREFIRE_pyPCRTM` | https://github.com/UW-PREFIRE/PREFIRE_pyPCRTM | f19294e232af20dbd496c10f868e843b2f83b2a6 | Python wrapper and Fortran adapter for PCRTM |
| `PREFIRE_PCRTM_V3.4` | https://github.com/UW-PREFIRE/PREFIRE_PCRTM_V3.4 | 046b309756ed7a2831346f5a1aa180e2206486b9 | the PCRTM v3.4 radiative transfer model (Fortran) |
| `PREFIRE_sim_tools` | https://github.com/UW-PREFIRE/PREFIRE_sim_tools | 9cf1becfbd4ffab850766bcf828c3ec0364d2ef0 | spectral response function handling |
| `PREFIRE_PRD_GEN` | https://github.com/UW-PREFIRE/PREFIRE_PRD_GEN | e3933a389894d1af081b3d0bbac4aa0eb27019bc | NetCDF read and write helpers, and the finalization step |
| `PREFIRE_tools` | https://github.com/UW-PREFIRE/PREFIRE_tools | 3b590a6eba09ce596e193ad1e04f636a8b7c3d58 | utilities used by the finalization step |

Nothing inside the submodules is changed. All seven are MIT-licensed by the PREFIRE Mission Team; see each submodule's LICENSE. The official ASDC R01 2B-CLD products report `PREFIRE_CLD 1.0.2`, the version in `PREFIRE_CLD/VERSION.txt` at this commit.

## Finding the sibling packages

`PREFIRE_CLD`'s README offers two ways to find its siblings: symbolic links in `PREFIRE_CLD/source/`, or adding each sibling's Python source directory to `PYTHONPATH`. This bundle uses `PYTHONPATH` for the Python packages:

```sh
source bundle_env.sh    # from the bundle root; sets PYTHONPATH to the sibling source directories
```

The one link the code still needs is to the built PCRTM, which `PREFIRE_CLD/dist/determine_prdgit.py` reads from `PREFIRE_CLD/source/PREFIRE_PCRTM_V3.4` (see the build below). The link is covered by `PREFIRE_CLD`'s `.gitignore`, so the submodule stays clean.

## Software and data

- Python 3.10 with numpy 1.26, scipy 1.11, netcdf4 1.6 and h5py 3.10 from conda-forge (the versions in `PREFIRE_CLD/conda_env.list`; `pyhdf`, also listed there, is not imported by the run), git (to record the code versions in the product), and a Fortran compiler with make (conda-forge `gfortran` and `make` work).
- The Makefiles of `PREFIRE_PCRTM_V3.4` and `PREFIRE_pyPCRTM` use x86-64-v3 instruction flags (AVX2, FMA). They build as they are on a current x86-64 CPU. On other CPUs (for example arm64), those flags must be removed, as the comments in both Makefiles say.
- PCRTM coefficient tables: `PREFIRE_PCRTM_V3.4-large_ancillary_data-1.zip` (3.5 GB, MIT) from Zenodo record 16694725 (https://zenodo.org/records/16694725). 2B-CLD uses only four of its members (205 MB), the tables for PCRTM sensor 2. Extract them into a folder whose path, with a trailing `/`, is **shorter than 120 characters**: PCRTM keeps the path in a 120-character Fortran string and silently cuts off anything longer, and the run then stops with "Cannot open file" on a mangled path.
- Spectral response functions: `PREFIRE_SRFs-v13_2024-09-15.zip` (11.6 MB, MIT) from Zenodo record 16638853 (https://zenodo.org/records/16638853), unzipped inside `PREFIRE_CLD/dist/`, which puts the two SRF files in `PREFIRE_CLD/dist/ancillary/` (the code reads them from there).
- Inputs per orbit, from NASA LaRC ASDC (Earthdata login): the PREFIRE 1B-RAD granule, the matching AUX-MET granule and the matching **final** 2B-MSK granule (the archived product), about 85 to 95 MB together. Collections `PREFIRE_SAT1_1B-RAD`, `PREFIRE_SAT1_AUX-MET`, `PREFIRE_SAT1_2B-MSK` (and the same for SAT2), version R01.
- The final product needs nothing more. The optional browse image of the finalization step needs matplotlib, cartopy, shapely, geopandas and pandas, plus network access for cartopy's Natural Earth coastlines; set `PRD_GEN_BASIC_ONLY=1` to skip the image and the CMR metadata file and run offline.

## Building PCRTM and its Python adapter (once)

From the bundle root. The build records these absolute paths, and `determine_prdgit.py` checks that the two records agree, so build in the place the bundle will run from (rebuild after moving it):

```sh
B=$PWD
cd $B/PREFIRE_PCRTM_V3.4/GENERIC
make gfortran LIBRARY_DIR=$B/PREFIRE_PCRTM_V3.4/lib INCLUDE_DIR=$B/PREFIRE_PCRTM_V3.4/include
make install  LIBRARY_DIR=$B/PREFIRE_PCRTM_V3.4/lib INCLUDE_DIR=$B/PREFIRE_PCRTM_V3.4/include
cd $B/PREFIRE_pyPCRTM/pyPCRTM
PCRTM_HOME=$B/PREFIRE_PCRTM_V3.4 make gfortran
cd $B
ln -s ../../PREFIRE_PCRTM_V3.4 PREFIRE_CLD/source/PREFIRE_PCRTM_V3.4

# ancillary data (zip paths are where you downloaded them; /path/to/pcrtm must be short, see above)
(cd /path/to/pcrtm && unzip /path/to/PREFIRE_PCRTM_V3.4-large_ancillary_data-1.zip \
    INPUTDIR/ABS_COEF/clarreo_abscoef_0.5 INPUTDIR/CLD_LUT/ice_clarreo_0.5.dat \
    INPUTDIR/CLD_LUT/wat_clarreo_0.5.dat INPUTDIR/EOF_COEF/clarreo_0.5_pccoef)
(cd PREFIRE_CLD/dist && unzip /path/to/PREFIRE_SRFs-v13_2024-09-15.zip)
```

Pass `LIBRARY_DIR` and `INCLUDE_DIR` on the command line as shown: their defaults in `GENERIC/makefile` point into the home folder. The first `make gfortran` prints a series of "Error 127 (ignored)" lines before the real compile; they are harmless. The build gives `PREFIRE_PCRTM_V3.4/lib/libPCRTM.a` and `PREFIRE_pyPCRTM/pyPCRTM/PCRTM_wrapper_module.so`, all ignored by the submodules' `.gitignore` files.

Optional check of the build, PREFIRE_pyPCRTM's own tests (each prints "Success!"):

```sh
source bundle_env.sh
cd PREFIRE_pyPCRTM/test
PCRTM_INPUT_DIR=/path/to/pcrtm/INPUTDIR/ python test_forward_run.py
PCRTM_INPUT_DIR=/path/to/pcrtm/INPUTDIR/ python test_jacobian_run.py
cd ../..
```

## Running one orbit

The mission makes 2B-CLD in two steps: `PREFIRE_CLD` writes a raw file for the orbit, then `PREFIRE_PRD_GEN` finalizes it into the archived product (polar frames only, with the archive's metadata). From the bundle root:

```sh
source bundle_env.sh
python PREFIRE_CLD/dist/determine_prdgit.py        # records the code versions; produce_L2.py needs it
python PREFIRE_PRD_GEN/dist/determine_prdgit.py    # the same for the finalization step
export MKL_NUM_THREADS=1 NUMEXPR_NUM_THREADS=1 OMP_NUM_THREADS=1 VECLIB_MAXIMUM_THREADS=1 OPENBLAS_NUM_THREADS=1

# Step 1: cloud retrieval (writes raw-PREFIRE_SAT1_2B-CLD_R01_P00_20241007075724_01877-atrack_00000_06609_of_06610f.nc)
mkdir -p /path/to/raw
export PACKAGE_TOP_DIR=$PWD/PREFIRE_CLD ANCILLARY_DATA_DIR=$PWD/PREFIRE_CLD/dist/ancillary \
       PCRTM_DIR=$PWD/PREFIRE_PCRTM_V3.4 PCRTM_INPUT_DIR=/path/to/pcrtm/INPUTDIR/ \
       OUTPUT_DIR=/path/to/raw PRODUCT_FULLVER=R01_P00 \
       ATRACK_IDX_RANGE_0BI=ATRACK_IDXRANGE_0BASED_INCLUSIVE:0:END \
       L1B_RAD_FILE=/path/to/PREFIRE_SAT1_1B-RAD_R01_P00_20241007075724_01877.nc \
       AUX_MET_FILE=/path/to/PREFIRE_SAT1_AUX-MET_R01_P00_20241007075724_01877.nc \
       L2B_MSK_FILE=/path/to/PREFIRE_SAT1_2B-MSK_R01_P00_20241007075724_01877.nc
python PREFIRE_CLD/dist/produce_L2.py

# Step 2: finalization into the archived product (the output folder must exist)
mkdir -p /path/to/final
export PACKAGE_TOP_DIR=$PWD/PREFIRE_PRD_GEN ANCILLARY_DATA_DIR=$PWD/PREFIRE_PRD_GEN/dist/ancillary \
       OUTPUT_PRODUCT_DIR=/path/to/final OUTPUT_OPTIONS="" PRD_GEN_BASIC_ONLY=1 \
       INPUT_FPATH_OR_FPREFIX=/path/to/raw/raw-PREFIRE_SAT1_2B-CLD_R01_P00_20241007075724_01877
python PREFIRE_PRD_GEN/dist/produce_PRD.py
```

`PCRTM_INPUT_DIR` must end with `/`. The run is single-threaded by design. PCRTM prints about 50 lines per retrieved footprint (about 20 MB of text per orbit). `ATRACK_IDX_RANGE_0BI` can split an orbit into frame ranges run separately; step 2 then merges every raw file that starts with the `INPUT_FPATH_OR_FPREFIX` prefix.

The author's own test, `PREFIRE_CLD/test/run.sh`, runs step 1 on 101 frames of each of two orbits. It expects PCRTM and its tables under `PREFIRE_CLD/dist/subpackages/`, reads its inputs from `PREFIRE_CLD/test/inputs/`, and calls `determine_prdgit.py` itself.

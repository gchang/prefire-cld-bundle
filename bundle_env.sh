# Put the PREFIRE_CLD sibling packages on PYTHONPATH (the PYTHONPATH method in PREFIRE_CLD/README.md)
# and keep Python from rewriting tracked bytecode in the submodules.
# Usage, from anywhere: source /path/to/prefire-cld-bundle/bundle_env.sh
_bundle_root="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
# PREFIRE_ATM/source holds both the PREFIRE_ATM package and the PREFIRE_ATM_OE and PREFIRE_ATM_utils modules
# that PREFIRE_CLD imports (its README links the same folder in as source/PREFIRE_ATM_other).
# PREFIRE_tools is used only by the PREFIRE_PRD_GEN finalization step.
export PYTHONPATH="${_bundle_root}/PREFIRE_PRD_GEN/source:${_bundle_root}/PREFIRE_sim_tools:${_bundle_root}/PREFIRE_pyPCRTM:${_bundle_root}/PREFIRE_ATM/source:${_bundle_root}/PREFIRE_tools/source/python${PYTHONPATH:+:${PYTHONPATH}}"
# PREFIRE_tools tracks two .pyc files; without this, importing it rewrites them and the product provenance says "(modified)"
export PYTHONDONTWRITEBYTECODE=1
unset _bundle_root

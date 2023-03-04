help([[
Load environment for WAFS on WCOSS2
]])

intel_ver=os.getenv("intel_ver") or "19.1.3.304"
PrgEnv_intel_ver=os.getenv("PrgEnv_intel_ver") or "8.1.0"
craype_ver=os.getenv("craype_ver") or "2.7.10"
cray_mpich_ver=os.getenv("cray_mpich_ver") or "8.1.9"
load(pathJoin("intel", intel_ver))
load(pathJoin("PrgEnv-intel", PrgEnv_intel_ver))
load(pathJoin("craype", craype_ver))
load(pathJoin("cray-mpich", cray_mpich_ver))


jasper_ver=os.getenv("jasper_ver") or "2.0.25"
libpng_ver=os.getenv("libpng_ver") or "1.6.37"
zlib_ver=os.getenv("zlib_ver") or "1.2.11"
load(pathJoin("jasper", jasper_ver))
load(pathJoin("libpng", libpng_ver))
load(pathJoin("zlib", zlib_ver))

g2_ver=os.getenv("g2_ver") or "3.4.5"
g2tmpl_ver=os.getenv("g2tmpl_ver") or "1.9.1"
w3nco_ver=os.getenv("w3nco_ver") or "2.4.1"
w3emc_ver=os.getenv("w3emc_ver") or "2.9.2"
bacio_ver=os.getenv("bacio_ver") or "2.4.1"
ip_ver=os.getenv("ip_ver") or "3.3.3"
sp_ver=os.getenv("sp_ver") or "2.3.3"
load(pathJoin("g2", g2_ver))
load(pathJoin("g2tmpl", g2tmpl_ver))
load(pathJoin("w3nco", w3nco_ver))
load(pathJoin("w3emc", w3emc_ver))
load(pathJoin("bacio", bacio_ver))
load(pathJoin("ip", ip_ver))
load(pathJoin("sp", sp_ver))

bufr_ver=os.getenv("bufr_ver") or "11.4.0"
load(pathJoin("bufr", bufr_ver))

whatis("Description: WAFS build environment")

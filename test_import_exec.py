# Try to "import" each of the packages provided as first argument
# Depending on a hard-coded table (module_names), we may :
#  - translate the conda package name in the actual module name
#  - or skip the import
#  - or rather test the execution  (by sys.exec) of the 'package'
# Exits on first issue

import sys
import importlib
import os
modules=sys.argv[1].split()
# print("Importing:",modules)
module_names={
    "netcdf4":"netCDF4", "udunits2" : "udunits", "cf-units":"cfunits" , 
    "hdf4":"HDF4", "dask-jobqueue":"dask_jobqueue", 
    "esmvaltool" : "esmvalcore",
    "basemap" : "mpl_toolkits.basemap",
    "pyyaml" : "yaml",
    #
    "gdal" : "skip" ,
    #
    "bash": ("type", "bash --help"),
    "imagemagick": ("type", "convert -h"),
    "ipython": ("type", "ipython -h"),
    "exiv2" : ("type","exiv2 -h "),
    "perl" : ("type" , "perl -h"), 
    "ncl" : ("type" ,"ncl -V"),
    "cdo" : ("type", "cdo -h"),
    "ncview" : ("type", "ncview -c"),
    "nco": ("type", "ncks -r"),
}
for module in modules :
   # Translate conda package name (with specification) in a module name
   module=module.split("=")[0]
   module=module.split("!")[0]
   module=module.split("<")[0]
   module=module.split(">")[0]
   pymodule=module_names.get(module,module)
   if pymodule == "skip" : 
      print("(skipping %s).."%module, end=" ")
      continue
   if type(pymodule) is tuple:
      # Trying to execute the corresponding binary
      print(module,"..",end=" ")
      if os.system(pymodule[1] + " > /dev/null 2>&1") != 0:
         print("Exec error for " + module)
         sys.exit(1)
      continue
   try:
      print(pymodule,"..",end=" ")
      sys.stdout.flush()
      m = importlib.import_module(pymodule)
   except ModuleNotFoundError :
      print("<-not found", end=" ")
   except :
      print("Issue with",module)
      #raise ValueError(module)
      sys.exit(1)
print()

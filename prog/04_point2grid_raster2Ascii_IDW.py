# -*- coding: utf-8 -*-
import arcpy
import os,glob,sys
import os.path
# Import arcpy module

# Check out any necessary licenses
arcpy.CheckOutExtension("3D")
arcpy.CheckOutExtension("Spatial")

# Set Geoprocessing environments
# left, bottom, right, top
arcpy.env.extent = "124.5 33 132.01 39.01"
	
Target_timeScale = sys.argv[1]
Target_climate_variable = sys.argv[2]


# Process: Make XY Event Layer


# Local variables:
outImageFolder = "../grid1kmData_img/"
outAsciiFolder = "../grid1kmData_ascii/"

pointFiles = sorted(glob.glob("../point_extraction\\"+Target_timeScale+"\\"+Target_climate_variable+"\\"+"*\\*.txt"))
schema_files = sorted(glob.glob("../point_extraction\\"+Target_timeScale+"\\"+Target_climate_variable+"\\"+"*\\*.ini"))

for schema_file in schema_files:
	arcpy.Delete_management(schema_file)

for pointFile in pointFiles:
	File_size = os.path.getsize(pointFile)
	if File_size == 0:
		continue
	else:
		# print pointFile
		fileName = pointFile.replace('pointData','1kmGrid').replace('\\',' ').replace('.',' ').split()[-2:][0]
		sub_folder_tmp = pointFile.replace('\\',' ').replace('.',' ').split()[-2:][0]
		
		sub_folder = pointFile.replace('point_extraction\\',' ').replace(sub_folder_tmp,' ').replace('\\','/').split()[-2:][0]
		
		
		try:
			os.stat(outImageFolder+sub_folder)
			os.stat(outAsciiFolder+sub_folder)
		except:
			os.makedirs(outImageFolder+sub_folder)
			os.makedirs(outAsciiFolder+sub_folder)
	
		ImageFile = outImageFolder + sub_folder + fileName +".tif"
		AsciiFile = outAsciiFolder + sub_folder + fileName +".txt"
	
		# using makeXYeventlayer function
		try:
			xy_Layer = "xy_Layer"
			if arcpy.Exists(xy_Layer):
				arcpy.Delete_management(xy_Layer)
				
			arcpy.MakeXYEventLayer_management(pointFile, "x", "y", xy_Layer, "GEOGCS['GCS_WGS_1984',DATUM['D_WGS_1984',SPHEROID['WGS_1984',6378137.0,298.257223563]],PRIMEM['Greenwich',0.0],UNIT['Degree',0.0174532925199433]];-400 -400 1000000000;-100000 10000;-100000 10000;8.98315284119522E-09;0.001;0.001;IsHighPrecision", "")
			
			if arcpy.Exists(ImageFile):
				continue
			
			else:
				print ImageFile
				# Process: interpolation from point data to create grided data
				# Process: Kriging (for others :: better way)
				# arcpy.gp.Kriging_sa(xy_Layer, "values", ImageFile, "Spherical #", "0.01", "VARIABLE 12", "")
		
				# Process: IDW (for prcp)
				arcpy.gp.Idw_sa(xy_Layer, "values", ImageFile, "0.01", "2", "VARIABLE 12", "")
				
	
			if arcpy.Exists(AsciiFile):
				continue
			else:
				# # Process: Raster to ASCII
				arcpy.RasterToASCII_conversion(ImageFile, AsciiFile)
					
		except IOError as e:
			# print "I/O error({0}): {1}".format(e.errno, e.strerror)
			arcpy.GetMessages()

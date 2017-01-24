 

# Vztvoreni textury. skopiruje alpha channel z out.png a aplikujee na gold.jpeg

C:\Export\report>convert goldmc.jpeg ( out.png -channel a -separate +channel ) -alpha off -compose copy_opacity -composite  out2.png





# vztvoreni  vrstvz s normlani barvou

C:\Export\report>convert ( -size 3000x3000 canvas:green ) ( out.png -channel a -
separate +channel ) -alpha off -compose copy_opacity -composite  out2.png


# 1) 
C:\Export\report>convert mc.png +clone  -compose Copy_Opacity -composite -alpha copy -channel A -negate out.png

# 2) asi rychlejsi

C:\Export\report>convert mc.png -background black -alpha copy -type truecolormatte -alpha copy -channel A -negate out.png


#Nastaveni pruhlednosti

C:\Export\report>convert out2.png -fuzz 20% -matte -fill "rgba(0,255,0, 0.1)" -opaque "rgba(0 ,255,0,1)" out3.png



# all in one


C:\Export\report>convert goldmc.jpeg ( ( -density 300 mc.pdf -background black -
alpha copy -type truecolormatte -alpha copy -channel A -negate ) -channel a -sep
arate +channel ) -alpha off -compose copy_opacity -composite png32:out2.png


y:\server\site_data\scripts3rdParty\im\convert.exe  (  -size 2618x3673 canvas:"rgb(0,115,42)"  (  (  -resize 2618x3673 -density 300 c:\tmp\InCam\scripts\other\C4FE1F82-6F99-1014-8D57-81E56CB4D31D\C4939949-6F99-1014-8D57-81E56CB4D31D.pdf -flatten -shave 20x20 -trim -shave 5x5  )  -background black -alpha copy -type truecolormatte -alpha copy -channel A -negate -channel a -separate +channel )   -alpha off -compose copy_opacity -composite   )   -fuzz 20% -matte -fill "rgba(0,115,42, 0.5)" -opaque "rgb(0,115,42)" c:\tmp\InCam\scripts\other\C4FE1F82-6F99-1014-8D57-81E56CB4D31D\C4939949-6F99-1014-8D57-81E56CB4D31D.png
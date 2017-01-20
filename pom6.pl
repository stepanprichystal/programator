 

# Vztvoreni textury. skopiruje alpha channel z out.png a aplikujee na gold.jpeg

C:\Export\report>convert gold.jpeg ( out.png -channel a -separate +channel ) -al
pha off -compose copy_opacity -composite  out2.png





# vztvoreni  vrstvz s normlani barvou

C:\Export\report>convert ( -size 3000x3000 canvas:green ) ( out.png -channel a -
separate +channel ) -alpha off -compose copy_opacity -composite  out2.png


# 1) 
C:\Export\report>convert mc.png +clone  -compose Copy_Opacity -composite -alpha
copy -channel A -negate out.png

# 2) asi rychlejsi

C:\Export\report>convert mc.png -background black -alpha copy -type truecolormatte -alpha copy -channel A -negate out.png


#Nastaveni pruhlednosti

C:\Export\report>convert out2.png -fuzz 20% -matte -fill "rgba(0,255,0, 0.1)" -o
paque "rgba(0 ,255,0,1)" out3.png


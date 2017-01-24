 

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


***********COMMAND    24Jan2017.104916.085 InCAM 22260 stepan 3.02 (174462) Windows 64 Bit
set_filter_attributes,filter_name=ref_select,exclude_attributes=no,max_int_val=0,min_int_val=0,attri
bute=.gold_plating,text=,option=,max_float_val=0,min_float_val=0,condition=yes (6)
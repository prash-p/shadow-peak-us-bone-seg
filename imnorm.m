function im = imnorm(img)

img = img-min(img(:));
im = img/max(img(:));

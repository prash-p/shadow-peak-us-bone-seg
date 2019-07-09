# Shadow-Peak bone segmentation

This repository contains code to perform automatic 3D bone segmentation, as published in our paper 
Pandey, P., Guy, P., Hodgson, A.J. and Abugharbieh, R., 2018. Fast and automatic bone segmentation and registration of 3D ultrasound to CT for the full pelvic anatomy: a comparative study. International journal of computer assisted radiology and surgery, 13(10), pp.1515-1524.
Please cite the publication you use this method in your research:
```
@article{pandey2018fast,
  title={Fast and automatic bone segmentation and registration of 3D ultrasound to CT for the full pelvic anatomy: a comparative study},
  author={Pandey, Prashant and Guy, Pierre and Hodgson, Antony J and Abugharbieh, Rafeef},
  journal={International journal of computer assisted radiology and surgery},
  volume={13},
  number={10},
  pages={1515--1524},
  year={2018},
  publisher={Springer}
}
```

The main function is **peakShadowBone.m**
There is no need to crop US volumes before segmentation, this function will provide a cropped volume (second output argument) and also a shadow confidence map (third output argument)

**Input Arguments:** 

The first input argument is the raw US volume (no need for cropping). 

The second argument takes into account expected shadowing based on transducer frequency. If you used 6MHz or higher for imaging - use 1. For lower frequencies use 0.

The third argument takes into account if you need the function to crop your input US volume (1) or not (0). Set to 1 or 0 as required.

The function **connBone.m** should be used post-segmentation to remove false-positive segmentations

## Usage Example:

```
load(US volume) %Using loadvol, load_nii, etc depending on volume format
[US_seg, US_crop, shadow_conf] = peakShadowBone(US volume, 1, 1);
US_seg = connBone(US_seg);
```




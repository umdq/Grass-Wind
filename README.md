# Grass-Wind
grass wave in wind
## About This Demo
Grass in most games implemented with the billboard technology looks so ugly,which I can not tolerate.In my opinion,
the ideal effct is that the grass should have fixed orientation,and show us the wind as the grass wave.As a result,I
drafted this demo.
## The Rendering Material
With the tessellation and geometry shader of DX11,it generates grass fully procedurally on any mesh,
which seems that the hair grows from the mesh!  
![](https://github.com/EagerCleaverInWind/Grass-Wind/blob/master/Grass%26Wind/screenshots/hair.jpg)
### Inspect Panel
![](https://github.com/EagerCleaverInWind/Grass-Wind/blob/master/Grass%26Wind/screenshots/material.png)  
#### Different Gravity Weight
![](https://github.com/EagerCleaverInWind/Grass-Wind/blob/master/Grass%26Wind/screenshots/gravity.jpg)
#### Different Density Value
![](https://github.com/EagerCleaverInWind/Grass-Wind/blob/master/Grass%26Wind/screenshots/density.jpg)
## Run Result
![](https://github.com/EagerCleaverInWind/Grass-Wind/blob/master/Grass%26Wind/screenshots/grass_wave.gif)
## To Do List
* Efficient lighting & shadow
* Interaction with any collider
* Billboard for cylinder or cone shape is ok

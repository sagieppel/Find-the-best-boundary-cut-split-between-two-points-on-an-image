Find the best boundary/cut/split that pass between points (Ax,Ay) and (Bx,By) on the grayscale image Is.

Input: 
Is: Grayscale image of the vessel containing the material. 
Ax,Ay: coordinates of the start pixel in which the split/path starts 
Bx,By: coordinates of the end pixel in which the split/path ends 
  
Note that the A and B must not be on the outer boundary of the image(A,B must be surrounded by pixels) 
  
Output 
MarkedImage: The input image Is with the best path between pixels A and B marked on the image (also displayed on screen) 
BstPathAB: binary image with the path between the start and end points. 
Notes 
Scanning method based on the Dijkstra's algorithm. 
Note that the resulting path cannot include loops (only propagation from left to right or vertical propagation of path is allowed).

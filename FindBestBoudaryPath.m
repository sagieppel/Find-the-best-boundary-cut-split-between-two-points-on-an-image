function  [MarkedImage,BstPathAB]=FindBestBoudaryPath(Is,Ax,Ay,Bx,By) 
%{
Find the best boundary/cut/split that pass between points (Ax,Ay) and (Bx,By) on the grayscale image Is.   
 
Input: 
Is: Grayscale image of the vessel containing the material.
Ax,Ay: coordinates of the start pixel in which the split/path starts
Bx,By: coordinates of the  end pixel in which the split/path ends
 
Note that the A and B must not be on the outer boundary of the image(A,B must be surrounded by pixels)
 
Output  
MarkedImage: The input image Is with the best path between pixels A and B marked on the image (also displayed on screen)
BstPathAB: binary image with the path between the start and end points.

Notes 
Scanning method based on the Dijkstra's  algorithm.
Note that the resulting path cannot include loops  (only propagation from left to right or vertical propagation of path is allowed).

%}

if Ax>Bx %Point A most be left of point B (Bx>Ax)
    tx=Bx;
    ty=By;
    Bx=Ax;
    By=Ay;
    Ax=tx;
    Ay=ty;
end;



global  I Iedge Y Yb X Xb 

[Hight,Width]=size(I);% image size
I=double(Is);% Greyscale version of the image in double form
Iedge=double(edge(I,'canny')); %Edge image of Is;
PrvY1=zeros(1000);%Array containing the previus(Prvx/y) location and next location (NxtX/Y), for all possible paths to  be explore this round
NxtY1=zeros(1000);
N1=0;% Number of possible paths/propogation steps to explore this round 
PrvY2=zeros(1000);%Array containing the previus(Prvx/y) location and next(NxtX/Y) location for all possible steps to explore in next round 
NxtY2=zeros(1000); 
N2=0;% Number of propogation steps for next round 
VerNxtY=zeros(1000); %Array containing the previus(Prvx/y) location and next location (NxtX/Y), for all vertical propogation steps (x,y)->(x,y+/-1) to explore this/next round 
VerPrvY=zeros(1000);
NV=0; %number of vertical moves for this round
NV2=0;% number of vertical moves for next round
PathMap=ones(Hight, Width)*100000;%Matrix in size of I. Each cell give the Prices of path from point A to the current pixel in the image
BackX=zeros(Hight, Width);% Matrix with the coordinate of the (previous pixel in path leading from A to this Pixel)
BackY=zeros(Hight, Width);

%===========================Set intial Step==================================================================================================
N1=1; PrvY1(1)=Ay; NxtY1(1)=Ay; % set initial step leading from point A
%==============Main loop Calculate Minimal Path==============================================================================================================================
for X=Ax:1:Bx% Scan the path price from A to every point up to B. This is done column by column (fx isnt realy used)
    Xb=X-1;% The prvious pixel for pixel located in X gor none vertical propogation previous X location is one X-1
    for f=1:N1% Scan all moves for this round
        Y=NxtY1(f);% to make reading simplier Write the Next coordinates of this move as X and Y (not really necessary and make code slower, when writing in opencv use define)
        Yb=PrvY1(f);       
        %--------------------------------------------Find next moves from location X,Y to X+1 (if point havent been explored before)--------------------------------------------------------
        if  PathMap(Y,X)>=100000 %if this point have not been explored. Find All paths leading from this point and add them to the list of step to explore next move
            for f1=-1:1:1
               if  Y+f1>1 && Y+f1<Hight && X+1<=Width %&& LegalPath(Y+f1,X+1)==1 % If the point (X+1,Y+f1) leading from is legal add it to the next moves list
                   N2=N2+1;%Increase number move to explore in next cycle
                   PrvY2(N2)=Y;
                   NxtY2(N2)=Y+f1;
               end;
            end;
            %................Find Next vertical moves for path propogation. From (x,y) to (x,y+/-1)...................................................................
                for f1=-1:2:1
                   if  Y+f1>1 && Y+f1<Hight %&&  LegalPath(Y+f1,X)==1 %if above/below point are legal position add them to the vertical move list
                      NV=NV+1;% Add move to list 
                      VerNxtY(NV)=Y+f1; %(Previous and Next location of each move NV is the number of vertical moves)
                      VerPrvY(NV)=Y;
                   end
                end
        end;
        %----------------------------------Calculate path price with this move (Xb,Yb)->(X,Y) ------------------------------------------------------------------------
        if (X==Ax && Y==Ay)  PathMap(Ay,Ax)=0; %In path starting point (A)  price is always zero
        else % if not starting point calculate price
          Price=PointPrice()+PathMap(Yb,Xb); %PRice of  total path including this move.  Price(A->[X,Y])=(A->[Xb,Yb])+ price( [Xb,Yb]->[X,Y])
          if Price<PathMap( Y, X)%If price for point X,Y cheaper from previous Price  appear in PathMap write it instead of previous price
            PathMap(Y,X)=Price;%Write new price
            BackX(Y,X)=Xb;%X-1; %Update location of previews point in the path according to this path
            BackY(Y,X)=Yb;
          end;
        end;
    end;

 %=================Vertical propogation of path in line X (X,Y)->(X,Y+/-1)===========================================================================================
    Xb=X;%For vertical propogation previous location is the same X 
 
   while (NV>0)% &&  NV>0) % as long as there move (NV) 
 %----------------------------------Scan all NV vertical moves------------------------------------------------------------------------------------------------------
      for f=1:NV 
         Y=VerNxtY(f); %Next place
         Yb=VerPrvY(f);    %Previous place
  %--------------------------------Find next moves from location X,Y to X+1 (if point havent been explored before)--------------------------------------------------------        
         if  PathMap(Y,X)==10000 %if this point have not been exploredd. All paths leading from this point and add them to the list of step to explore next move
            for f1=-1:1:1
               if  Y+f1>1 && Y+f1<Hight && X+1<=Width %&& LegalPath(Y+f1,X+1)==1 % if the point leading from X,Y is legal add it to the next moves list
                   N2=N2+1;%increase move to explore in next cycle
                   PrvY2(N2)=Y;
                   NxtY2(N2)=Y+f1;
               end;
            end;
         end;
%,,,,,,,,,,,,,,,,Calculate price for the path containing the current move----------------------------------------------------         
           Price=PointPrice()+PathMap(Yb,X);%Price of this move + price of previus path (Kvert is extra price for discouraging vertical propogation)
%,,,,,,,,,,,,,,if price lower from previous price write the path and find next vertical moves..................................           
           if Price<PathMap(Y,X)%if price cheaper from previous Price to X,Y write it instead of previous path/price
              PathMap(Y,X)=Price;%Write new price
              BackX(Y,X)=Xb;%X
              BackY(Y,X)=Yb;
 %................Find Next vertical move for path propogation from X,Y to X,Y+1/-1...................................................................
                dy=Y-Yb;
                   if  Y+dy>1 && Y+dy<Hight %&&  LegalPath(Y+dy,X)==1 %If above/below point are legal add them to the vertical move list
                      NV2=NV2+1;
                      VerNxtY(NV2)=Y+dy; % of vertical moves for current line only Y is needed since the X is the X of the line (Previous and Next location of each move NV is the number of vertical moves)
                      VerPrvY(NV2)=Y;
                   end  
%---------------------------------------------------------------------------------------------------------------------
           end;
      end
      NV=NV2;%update vertical moves
      NV2=0;
  end
%=================================================================================================================================
 %-------------------------------update  List of moves, copy list of move for next cycle to current cycle-----------------------------------------------------------------------------------------------       
    N1=N2; %
    N2=0;
    NV=0;
    PrvY1=PrvY2;
    NxtY1=NxtY2;
%-----------------------------------------------------------------------------------------------------------------------------
end;
BestPathPrice=PathMap(By,Bx);%the minimal path price from point A to B
%==========================================================================================================================
%Retrace the best path from the map
x=Bx;
y=By;
BstPathAB=zeros(size(BackX));%binary image  where all points in the path marked 1
BstPathAB(y,x)=1;
%----------------------------------------------------------------------
while (x~=Ax || y~=Ay)
   xx=x;
    x=BackX(y,x);
   y=BackY(y,xx);
   BstPathAB(y,x)=1;
  
   %imshow(BstPathAB);pause();
end;
%----------------------------------------------------------------------
%==========================================================================================================================
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% WRITE/DISPLAY OUTPUT%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% 
            close all
        
         MarkedImage= uint8(double(~BstPathAB).*double(I));
           figure, imshow(  BstPathAB);
              figure, imshow(MarkedImage);      
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function [PointPrice]=PointPrice()
PointPrice=PointPrice1();%*(1+2*HighPriceZone(Y,X));%+HighPriceZone(Y,X)*0.2;%*0.4;%*sqrt(abs(Y-Yb)+abs(X-Xb));
end



 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function [PointPrice]=PointPrice1()% best of the cost function
%Calculate Price As difference between edge density  of the pixel and the pixel on both side of the curve (normal to curve) 
   global  Iedge Y X Xb Yb  
   Dy=Y-Yb;
   Dx=X-Xb;
   PointPrice=1.0-Iedge(Y,X)+(Iedge(Y+Dx,X-Dy)+Iedge(Y-Dx,X+Dy))/2;
 end

 
 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function [PointPrice]=PointPrice2()
%Calculate Price As curve correspondane with edges  
   global  Iedge Y X
  
   PointPrice=1.0-Iedge(Y,X);
 end

 %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
 function [PointPrice]=PointPrice3()
 %Calculate Price as the relative intenisty change normal to curve (Ignore gradient sign in price calculation)
 %scalar mutipication of  the normalize gradient normal and the path line at this point using the intensity image (yet another mode)
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
 global I Y X Xb Yb 
     Dy=Y-Yb;
     Dx=X-Xb; 
     PointPrice=1.0-abs(I(Y,X)-I(Y+Dx,X-Dy ))/max([I(Y,X) I(Y+Dx,X-Dy ) 1]);
   
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%5
   function [PointPrice]=PointPrice4()
 %Calculate Price as the intensity change normal to curve (ignore gradient sign in price)
 %I intensity image
 %X,Y location of current point
 %Xb,Yb location of previous point in the path
   global I Y X Xb Yb 
     Dy=Y-Yb;
     Dx=X-Xb;
     PointPrice=1.0-abs(I(Y,X)-I(Y+Dx,X-Dy ))/255;
   
  end
 
    
        


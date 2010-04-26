/*
 webRainbow - arduino_firmware.pde
 April 2010
 Giacomo M. Galatone
 http://www.giagt.it

 Copyright 2010 - Giacomo M. Galatone
 This source code is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version. This source code is distributed in
 the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
.
 You should have received a copy of the GNU General Public License
 along with this library.  If not, see <http://www.gnu.org/licenses/>.
 	  
 */
 
 /*
 PROTOCOL STRUCTURE:
 very-pseudo code.
 
 Server says:
 webRaibow-server
 
 Client respond:
 webRainbow-client
 (0 [receivePixel] OR 1 [receiveColor] OR 2 [showChar])
 
 if receivePixel {
 ID: (i2c ID - integer 0<=id<10)
 X: (X coordinate 0<=x<8)
 Y: (Y coordinate 0<=y<8)
 r: (red color component 0<=r<16)
 g: (green color component 0<=g<16)
 b: (blu color component 0<=b<16)
 
 Server says:
 Setting pixel
 }

if receiveColor {
 ID: (i2c ID - integer 0<=id<10)
 r: (red color component 0<=r<16)
 g: (green color component 0<=g<16)
 b: (blu color component 0<=b<16)
 
 Server says:
 Setting matrix flat color
}

if showChar {
 ID: (i2c ID - integer 0<=id<10)
 c: (char 'A-Z','a,z','0,9')
 r: (red color component 0<=r<16)
 g: (green color component 0<=g<16)
 b: (blu color component 0<=b<16)
 mode: (static, slider)
 
 Server says:
 Setting char
}
 

 
 */
#include <Wire.h>
#include <Ethernet.h>
#include "TextFinder.h"
#include <stdlib.h> 

#define _START_STRING webRaibow-server;

byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192, 168, 1, 99 };
int command[6];
int function;

Server server(23);

unsigned char RainbowCMD[6];
int CMDState;
unsigned long timeout;
unsigned char red = 0;
unsigned char green = 0;
unsigned char blue = 0;
unsigned char state = 0;


void setup() {
  Wire.begin();
  Ethernet.begin(mac, ip);
  server.begin();
  ShowColor(4, 0, 0, 0);
  ShowColor(3, 0, 0, 0); 
}




void loop() {
  
   Client client = server.available();
   if (client) {
    client.println("_START_STRING");
    TextFinder  finder(client);  
    while (client.connected()) {      
      if (client.available()) {          
        
        if( finder.findUntil("webRainbow-client", "\n\r") ) {
          function = finder.getValue();
          switch(function) {
            case 0:
            receivePixel();
            break;
            case 1:
            receiveColor();
            break;
          }
           
        } 
      }
    }
   }
 }


void receivePixel() {
char c,d;
  int i=0,temp[2],temp2;
  long r,g,b;
  Client client = server.available();
   if (client) {
    client.println("_START_STRING");
    TextFinder  finder(client);  
    while (client.connected()) {      
      if (client.available()) {          
        
       
          // I2c ID
           if (finder.findUntil("ID:", "\n\r")) {
              c = client.read();
              command[0] = atoi(&c);
             // client.println("Reading ID");
            }  else { break; }
          ////////
          
          // COORDINATES X - Y
          if (finder.findUntil("X:", "\n\r")) {
              c = client.read();
              command[1] = atoi(&c);
             // client.println("Reading X");      Uncomment for debug
            }  else { break; }
            if (finder.findUntil("Y:", "\n\r")) {
              c = client.read();
              command[2] = atoi(&c);
           //   client.println("Reading Y");
            }  else { break; }
            /////////
            
            // R G B
            if (finder.findUntil("r:", "\n\r")) {
            r = finder.getValue();
              command[3] = r;
          //    client.println(command[3]);
            }    else { break; } 
            
            if (finder.findUntil("g:", "\n\r")) {
               g = finder.getValue();
              command[4] = g;
           //   client.println("Reading g");
            }     else { break; }
            
            if (finder.findUntil("b:", "\n\r")) {
              b = finder.getValue();
              command[5] = b;
           //   client.println("Reading b");
            } else { break; }
            //////////////
            
        client.println("Setting pixel");
        SetPixelXY(command[0],command[1],command[2],command[3],command[4],command[5]);
        client.stop();
        break;
      }
    }
   }
}

void receiveColor() {
char c,d;
  int i=0,temp[2],temp2;
  long r,g,b;
  Client client = server.available();
   if (client) {
    client.println("_START_STRING");
    TextFinder  finder(client);  
    while (client.connected()) {      
      if (client.available()) {          
        
       
          // I2c ID
           if (finder.findUntil("ID:", "\n\r")) {
              c = client.read();
              command[0] = atoi(&c); 
            }  else { break; }
          ////////
            
            // R G B
            if (finder.findUntil("r:", "\n\r")) {
            r = finder.getValue();
              command[3] = r;
            }    else { break; } 
            
            if (finder.findUntil("g:", "\n\r")) {
               g = finder.getValue();
              command[4] = g;
            }     else { break; }
            
            if (finder.findUntil("b:", "\n\r")) {
              b = finder.getValue();
              command[5] = b;
            } else { break; }
            //////////////
            
        client.println("Setting matrix flat color");
        ShowColor(command[0],command[3],command[4],command[5]);
        client.stop();
         break;
      }
    }
   }
}
//--------------------------------------------------------------------------
// Name: ShowColor
// function: Send a conmand to Rainbowduino for showing a color
// parameter: Address: Rainbowduino I2C address
//                 red, green, blue:  the color RGB    
//----------------------------------------------------------------------------
void ShowChar(int  Address,unsigned char ASCII,unsigned char red, unsigned char blue ,unsigned char green,unsigned char shift)
{
    RainbowCMD[0]='R';
    RainbowCMD[1]=0x02;
    RainbowCMD[2]=((shift<<4)|(red));
    RainbowCMD[3]=((green<<4)|(blue));
    RainbowCMD[4]=ASCII;
	 
     SendCMD(Address);
}

void ShowColor(int Adr, unsigned char R, unsigned char G, unsigned char B) {
  unsigned char shift;
  RainbowCMD[0]='R';
  RainbowCMD[1]=0x03;
  RainbowCMD[2] = B;
  RainbowCMD[3]=((G<<4)|(R));
  SendCMD(Adr);
}

//--------------------------------------------------------------------------
// Name: SetPixelXY
// function: Send conmand to Rainbowduino to set a pixel to a particular color
// parameters: Address:  I2C address of Rainbowduino
//       red, green, blue:  the color RGB  
//       x,y: thecoordinates of the pixel.
// Extension to command set, requires revised firmware on the Rainbowduino 
// to support this, see Rainbowduino_CMD_v2.pde
//--------------------------------------------------------------------------

void SetPixelXY(int Adr, unsigned char X, unsigned char Y, unsigned char R, unsigned char G, unsigned char B) {
  // change coordinates so that 0,0 is in lower left and 7,7 is in upper right.
  unsigned char TranslateX[8]={6,7,4,5,2,3,0,1};
  // unsigned char TranslateY[8]={7,6,5,4,3,2,1,0};  // use if you want 0,0 in upper left, see SetPixel
  X = TranslateX[X];
  // Y = TranslateX[Y];  // use if you want 0,0 in top left
  RainbowCMD[0] = 'R';
  RainbowCMD[1] = 0x04; 
  //  RainbowCMD[2]=((placeholder<<4)|(red));
  RainbowCMD[2] = R;
  RainbowCMD[3] = ((G<<4)|(B));
  RainbowCMD[4] = ((X<<4)|(Y)); // Pack X into high nybble, Y into low nybble	 
  SendCMD(Adr);
}

//--------------------------------------------------------------------------
// Name: SendCMD
// function: Send a 5 byte conmand out to the Rainbowduino
// parameter: Adr: I2C Address of Rainbowduino 
//----------------------------------------------------------------------------

void SendCMD(int  Adr) {   
  
  unsigned char OK = 0;
  unsigned char i, temp;

  while(!OK) {                          
    switch (CMDState) { 	

    case 0:                          
      Wire.beginTransmission(Adr);
      for (i=0; i<5; i++) Wire.send(RainbowCMD[i]);
      Wire.endTransmission();    
      delay(5);   
      CMDState = 1;                      
      break;

    case 1:
      Wire.requestFrom(Adr, 1);   
      if (Wire.available() > 0) 
        temp = Wire.receive();    
      else {
        temp = 0xFF;
        timeout++;
      }
      if ((temp == 1)||(temp == 2)) CMDState = 2;
      else if (temp==0) CMDState = 0;

      if (timeout > 5000) {
        timeout = 0;
        CMDState = 0;
      }
      delay(5);
      break;

    case 2:
      OK=1;
      CMDState = 0;
      break;

    default:
      CMDState = 0;
      break;

    }
  }
}





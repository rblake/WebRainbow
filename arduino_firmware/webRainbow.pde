/*
 Color_Tily_V2.pde
 November 19, 2009
 david tames
 http://kino-eye.com 
 
 Demonsrate use of Pololu afccc01a accelerometer board, colors on
 8x8 LCD Matrix indicate direction of tilt.
 
 This sketch runs on the Arduino and talks to the Rainbowduino via
 I2C. Rainbowduino_CMD_v2.pde sketch must be running on the Rainbowduino
 for this sketch to work, as it extends the Rainbowduino with an
 additional command not defined in the default firmware.  
 
 Based, in part,  on  Rainbowduino_Master.pde from Seeedstudio, modified
 to support a new command, SetPixelXY which sets the value of a pixel to
 a particular color value.
 
 Copyleft 2009 David Tames.  All right reserved.
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
#include <Wire.h>
#include <Ethernet.h>
#include "TextFinder.h"
#include <stdlib.h> 

#define YES 0x01;
#define NO 0x00;



byte mac[] = { 0xDE, 0xAD, 0xBE, 0xEF, 0xFE, 0xED };
byte ip[] = { 192, 168, 1, 99 };
int command[6];

Server server(23);

unsigned char debug = NO;
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
  char c,d;
  int i=0,temp[2],temp2;
  Client client = server.available();
   if (client) {
    client.println("webRaibow-server");
    TextFinder  finder(client);  
    // an http request ends with a blank line
    //    boolean current_line_is_blank = true;
    while (client.connected()) {      
      if (client.available()) {          
        
        if( finder.findUntil("webRainbow-client", "\n\r") ) {
          // I2c ID
           if (finder.findUntil("ID:", "\n\r")) {
              c = client.read();
              command[0] = atoi(&c);
              client.println("Reading ID");
            }  else { break; }
          ////////
          
          // COORDINATES X - Y
          if (finder.findUntil("X:", "\n\r")) {
              c = client.read();
              command[1] = atoi(&c);
              client.println("Reading X");
            }  else { break; }
            if (finder.findUntil("Y:", "\n\r")) {
              c = client.read();
              command[2] = atoi(&c);
              client.println("Reading Y");
            }  else { break; }
            /////////
            
            // R G B
            if (finder.findUntil("r:", "\n\r")) {
              c = client.read();
              temp[0] = c;
              d = client.read();
              temp[1] = d;
              temp2 = (temp[0]-48)*10+(temp[1]-48);
              command[3] = temp2;
              client.println(command[3]);
            }    else { break; } 
            
            if (finder.findUntil("g:", "\n\r")) {
              c = client.read();
              temp[0] = c;
              d = client.read();
              temp[1] = d;
              temp2 = (temp[0]-48)*10+(temp[1]-48); 
              command[4] = temp2;
              client.println("Reading g");
            }     else { break; }
            
            if (finder.findUntil("b:", "\n\r")) {
              c = client.read();
              temp[0] = c;
              d = client.read();
              temp[1] = d;
              temp2 = (temp[0]-48)*10+(temp[1]-48);
              command[5] = temp2;
              client.println("Reading b");
            } else { break; }
            //////////////
            
          client.println("Sending command");
        SetPixelXY(command[0],command[1],command[2],command[3],command[4],command[5]);
        client.stop();
        }
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





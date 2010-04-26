#include "Rainbow.h"
#include <Wire.h>
#include <avr/pgmspace.h>
#include <math.h>

/*
 --------------------------------------------------------------------------------
 Rainbowduino_CMD_v2.pde
 November 2009
 Based on RainbowCMD.pde from Seeedstudio and MeggyJr_Plasma.pde 0.3
 Modified to support a new command, SetPixel by david tames http://kino-eye.com
 --------------------------------------------------------------------------------
 Copyright (c) 2009 David Tames.  All right reserved.
 Copyright (c) 2009 Seedstudio.  All right reserved.
 Copyright (c) 2009 Ben Combee.  All right reserved.
 Copyright (c) 2009 Ken Corey.  All right reserved.
 Copyright (c) 2008 Windell H. Oskay.  All right reserved.
 This library is free software: you can redistribute it and/or modify it under the
 terms of the GNU General Public License as published by the Free Software Foundation,
 either version 3 of the License, or (at your option) any later version. This library
 is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without
 even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. 
 See the GNU General Public License for more details. You should have received a copy
 of the GNU General Public License along with this library. If not, see 
 <http://www.gnu.org/licenses/>.
  --------------------------------------------------------------------------------
 */

#define screenWidth 8
#define screenHeight 8
#define paletteSize 64

typedef struct {
  int r;
  int g;
  int b;
} 
ColorRGB;

//a color with 3 components: h, s and v
typedef struct {
  int h;
  int s;
  int v;
} 
ColorHSV;

void setPixelXY();  // New Command added
extern unsigned char dots_color[2][3][8][4];  //define Two Buffs (one for Display ,the other for receive data)
extern unsigned char GamaTab[16];             //define the Gamma value for correct the different LED matrix
extern unsigned char Prefabnicatel[5][3][8][4];
extern unsigned char ASCII_Char[52][8];
extern unsigned char ASCII_Number[10][8];
unsigned char line,level;
unsigned char Buffprt=0;
unsigned char State=0;
unsigned char g8Flag1;
unsigned char RainbowCMD[5]={0,0,0,0,0};

//================================================================================
// Setup

void setup() {
  _init();
  // override the default pattern and flash all pixels on at reset or startup 
  // (a kludgy but quick way to do it)
    RainbowCMD[2] = 0; RainbowCMD[3] = 0; DispshowColor();
    RainbowCMD[2] = 0xff; RainbowCMD[3] = 0xff; DispshowColor();
    delay(2000);
    RainbowCMD[2] = 0; RainbowCMD[3] = 0; DispshowColor();
}

//================================================================================
// Main Loop

void loop() {

  switch (State) {
  case waitingcmd:   
    break;

  case processing:
    GetCMD();
    State=checking;
    break;

  case checking:
    if(CheckRequest)
    {
      State=waitingcmd;
      ClrRequest;
    }
    break;

  default:
    State=waitingcmd; 
    break;
  }

}

//================================================================================
// setPixelXY: light up a particular dot to a particular color
// Extend the Rainbowduino firmware to support setting a specific pixel to a color 

void setPixelXY(void) {
  unsigned char r;  
  unsigned char g;  
  unsigned char b;
  unsigned char x;  
  unsigned char y;  
  r=(RainbowCMD[2]&0x0F); 
  g=((RainbowCMD[3]>>4)&0x0F); 
  b=(RainbowCMD[3]&0x0F);
  x=((RainbowCMD[4]>>4)&0x0F); 
  y=(RainbowCMD[4]&0x0F);
  RainbowCMD[1]=0; 
  x &= 7;  
  y &= 7;
  // In the Buffprt array, the color value/array-elements are: [0]: Green [1]: Red [2]: Blue
  // Special Thanks to Joe C for the bug fix!
  if ((x & 1) == 0) {
    dots_color[Buffprt][0][y][x >> 1] = g | (dots_color[Buffprt][0][y][x >> 1] & 0xF0);
    dots_color[Buffprt][1][y][x >> 1] = r | (dots_color[Buffprt][1][y][x >> 1] & 0xF0);
    dots_color[Buffprt][2][y][x >> 1] = b | (dots_color[Buffprt][2][y][x >> 1] & 0xF0);
  }  
  else {
    dots_color[Buffprt][0][y][x >> 1] = (g << 4) | (dots_color[Buffprt][0][y][x >> 1] & 0x0F);
    dots_color[Buffprt][1][y][x >> 1] = (r << 4) | (dots_color[Buffprt][1][y][x >> 1] & 0x0F);
    dots_color[Buffprt][2][y][x >> 1] = (b << 4) | (dots_color[Buffprt][2][y][x >> 1] & 0x0F);
  }
}

//================================================================================
// Timer 2 service routine

ISR(TIMER2_OVF_vect)  { 
  TCNT2 = GamaTab[level];    // Reset a  scanning time by gamma value table
  flash_next_line(line,level);  // sacan the next line in LED matrix level by level.
  line++;
  // when have scaned all LEC the back to line 0 and add the level
  if(line>7)  {
    line=0;
    level++;
    if(level>15)  level=0;
  }
}

//================================================================================
// init timer 2

void init_timer2(void)  {
  TCCR2A |= (1 << WGM21) | (1 << WGM20);   
  TCCR2B |= (1<<CS22);   // by clk/64
  TCCR2B &= ~((1<<CS21) | (1<<CS20));   // by clk/64
  TCCR2B &= ~((1<<WGM21) | (1<<WGM20));   // Use normal mode
  ASSR |= (0<<AS2);       // Use internal clock - external clock not used in Arduino
  TIMSK2 |= (1<<TOIE2) | (0<<OCIE2B);   //Timer2 Overflow Interrupt Enable
  TCNT2 = GamaTab[0];
  sei();   
}

//================================================================================
// init,  define the pin mode

void _init(void)  {
  DDRD=0xff;
  DDRC=0xff;
  DDRB=0xff;
  PORTD=0;
  PORTB=0;
  Wire.begin(4); // join i2c bus (address optional for master) 
  Wire.onReceive(receiveEvent); // define the receive function for receiving data from master
  Wire.onRequest(requestEvent); // define the request function for the request from maseter 
  init_timer2();  // initial the timer for scanning the LED matrix
}

//================================================================================
// receive

void receiveEvent(int howMany) {
  unsigned char i=0;
  while(Wire.available()>0) { 
    RainbowCMD[i]=Wire.receive();
    i++;
  }
  if ((i==5)&&(RainbowCMD[0]=='R')) State=processing;
  else      State=waitingcmd;	
}

//================================================================================
// request

void requestEvent(void) {
  Wire.send(State); 
  if ((State==processing)||(State==checking))  SetRequest;
}

//================================================================================
// Diplay a picture

void DispshowPicture(void) {
  unsigned char pi,shifts;
  unsigned char color=0,row=0,dots=0;
  unsigned char temp;
  unsigned char fir,sec;
  shifts=((RainbowCMD[2]>>4)&0x0F);
  pi=RainbowCMD[4];
  RainbowCMD[1]=0;
  for(color=0;color<3;color++) {
    for (row=0;row<8;row++) {
      for (dots=0;dots<4;dots++) {

        if (shifts&0x01) {             
          temp = dots + (shifts>>1);
          fir=pgm_read_byte(&(Prefabnicatel[pi][color][row][(temp<4)?(temp):(temp-4)]));
          sec=pgm_read_byte(&(Prefabnicatel[pi][color][row][(temp<3)?(temp+1):(temp-3)]));
          dots_color[((Buffprt+1)&1)][color][row][dots] = (fir<<4)|(sec>>4);  
        } 
        else {
          temp = dots + (shifts>>1);
          dots_color[((Buffprt+1)&1)][color][row][dots] = pgm_read_byte(&(Prefabnicatel[pi][color][row][(temp<4)?(temp):(temp-4)]));  
        }
      }
    }
  }
  Buffprt++;
  Buffprt&=1;

}

//================================================================================
// Diplay a character

void DispshowChar(void) {
  unsigned char Col_Red,Col_Blue,Col_Green,shift,ASCII;
  unsigned char tempword,color,row,dots,Num,tempdata,tempcol,AS;
  shift=((RainbowCMD[2]>>4)&0x0F);
  Col_Red=(RainbowCMD[2]&0x0F);
  Col_Green=((RainbowCMD[3]>>4)&0x0F);
  Col_Blue=(RainbowCMD[3]&0x0F);
  ASCII=RainbowCMD[4];
  RainbowCMD[1]=0;
  if((ASCII>64)&&(ASCII<91)) AS=ASCII-65; 
  else if((ASCII>96)&&(ASCII<123)) AS=ASCII-71;
  else if( (ASCII>='0')&&(ASCII<='9')) AS=ASCII-48;	
  for(color=0;color<3;color++) {
    if(color==0)        tempcol=Col_Green;
    else if(color==1)   tempcol=Col_Red;
    else if(color==2)   tempcol=Col_Blue;
    for (row=0;row<8;row++)   {  
      if( (ASCII>='0')&&(ASCII<='9'))
        tempword=pgm_read_byte(&(ASCII_Number[AS][row]));	
      else
        tempword=pgm_read_byte(&(ASCII_Char[AS][row]));
      tempword=(shift<7)?(tempword<<shift):(tempword>>(shift-8));	 
      for (dots=0;dots<4;dots++) {
        if((tempword<<(2*dots))&0x80) {
          tempdata&=0x0F;
          tempdata|=(tempcol<<4);
        } 
        else {
          tempdata&=0x0F;
        }
        if((tempword<<(2*dots+1))&0x80) {
          tempdata&=0xF0;
          tempdata|=tempcol;
        }  
        else {
          tempdata&=0xF0;
        }   
        dots_color[((Buffprt+1)&1)][color][row][dots]=tempdata;	  
      }
    }
  }
  Buffprt++;
  Buffprt&=1;
}

//================================================================================
// Set matrix to a particular color

void DispshowColor(void) {   
  unsigned char color=0,row=0,dots=0;
  unsigned char Gr,Bl,Re;
  Re=(RainbowCMD[2]&0x0F);
  Gr=((RainbowCMD[3]>>4)&0x0F);
  Bl=(RainbowCMD[3]&0x0F);
  RainbowCMD[1]=0;
  for(color=0;color<3;color++)  {
    for (row=0;row<8;row++)  {
      for (dots=0;dots<4;dots++)  {
        switch (color) {
        case 0://green
          dots_color[((Buffprt+1)&1)][color][row][dots]=( Gr|(Gr<<4));
          break;
        case 1://blue
          dots_color[((Buffprt+1)&1)][color][row][dots]= (Bl|(Bl<<4));
          break;
        case 2://red
          dots_color[((Buffprt+1)&1)][color][row][dots]= (Re|(Re<<4));
          break;
        default:
          break;
        }
      }
    }
  }
  Buffprt++;
  Buffprt&=1;
}

//================================================================================
// Command processing loop
// New setPixelXY command added 

void GetCMD(void) {
  switch(RainbowCMD[1]) {
  case showPrefabnicatel:
    DispshowPicture();	
    break;
  case showChar:
    DispshowChar();	
    break;
  case showColor:
    DispshowColor();	
    break;
    // New command (setPixelXY)
  case setPixels:  
    setPixelXY();	
    break;	   
  }
}


//==============================================================
//shift 1 bit of  1 Byte color data into Shift register by clock

void shift_1_bit(unsigned char LS)  {
  if (LS)  {
    shift_data_1;
  }   
  else {
    shift_data_0;
  }
  clk_rising;
}
//==============================================================
// scan one line

void flash_next_line(unsigned char line,unsigned char level)  {
  disable_oe;
  close_all_line;
  open_line(line);
  shift_24_bit(line,level);
  enable_oe;
}

//==============================================================
// display one line by the color level in buff

void shift_24_bit(unsigned char line,unsigned char level)   {
  unsigned char color=0,row=0;
  unsigned char data0=0,data1=0;
  le_high;
  for(color=0;color<3;color++)  { // GBR
    for(row=0;row<4;row++) {
      data1=dots_color[Buffprt][color][line][row]&0x0f;
      data0=dots_color[Buffprt][color][line][row]>>4;
      //gray scale,0x0f aways light
      if(data0>level)    {
        shift_1_bit(1);
      } 
      else {
        shift_1_bit(0);
      }

      if(data1>level) {
        shift_1_bit(1);
      } 
      else {
        shift_1_bit(0);
      }
    }
  }
  le_low;
}

//==============================================================
// open the scaning line 

void open_line(unsigned char line) {
  switch(line) {
  case 0:
    {
      open_line0;
      break;
    }
  case 1:
    {
      open_line1;
      break;
    }
  case 2:
    {
      open_line2;
      break;
    }
  case 3:
    {
      open_line3;
      break;
    }
  case 4:
    {
      open_line4;
      break;
    }
  case 5:
    {
      open_line5;
      break;
    }
  case 6:
    {
      open_line6;
      break;
    }
  case 7:
    {
      open_line7;
      break;
    }
  }
}


import oscP5.*;
import netP5.*;

import processing.opengl.*;

int scrWidth = 1280, scrHeight = 800;
int modeTxtX = 100;
int modeTxtY = 650;


PFont font;
PImage recImage, playImage;

OscP5 oscP5;

int bg;
int modeL = 0; // 0 = record, 1 = play
int modeR = 0; // 0 = record, 1 = play

void setup()
{
  frameRate(30);
  size(scrWidth, scrHeight, OPENGL);

  colorMode(HSB, 1.0);
  
  font = loadFont("data/TwCenMT-Bold-216.vlw");

  oscP5 = new OscP5(this, 6449);
  
  recImage = loadImage("record.png");
  playImage = loadImage("play.png");
    
  bg = color(0, 0, 0);
}

void draw()
{
  background(bg);
  
  fill(0, 0, 1);
  noStroke();
  rect(modeTxtX - 25, modeTxtY, 10, recImage.height);
  rect(width - modeTxtX + 15, modeTxtY, 10, recImage.height);
  
  if(modeL == 0) // record
    image(recImage, modeTxtX, modeTxtY);
  else if(modeL == 1) // play
    image(playImage, modeTxtX, modeTxtY);
  
  if(modeR== 0) // record
    image(recImage, width - modeTxtX - recImage.width, modeTxtY);
  else if(modeR == 1) // play
    image(playImage, width - modeTxtX - playImage.width, modeTxtY);
}

void oscEvent(OscMessage msg)
{
  if(msg.checkAddrPattern("/smeaky/mode/left"))
  {
    modeL = msg.get(0).intValue();
  }
  else if(msg.checkAddrPattern("/smeaky/mode/right"))
  {
    modeR = msg.get(0).intValue();
  }
  else if(msg.checkAddrPattern("/smeaky/level"))
  {
    bg = color(0, 0, 1-msg.get(0).floatValue());
  }
}


import processing.core.*; 
import processing.xml.*; 

import oscP5.*; 
import netP5.*; 
import processing.opengl.*; 

import java.applet.*; 
import java.awt.Dimension; 
import java.awt.Frame; 
import java.awt.event.MouseEvent; 
import java.awt.event.KeyEvent; 
import java.awt.event.FocusEvent; 
import java.awt.Image; 
import java.io.*; 
import java.net.*; 
import java.text.*; 
import java.util.*; 
import java.util.zip.*; 
import java.util.regex.*; 

public class SmearyGfx extends PApplet {






int scrWidth = 1280, scrHeight = 800;
int modeTxtX = 100;
int modeTxtY = 650;


PFont font;
PImage recImage, playImage;

OscP5 oscP5;

int bg;
int modeL = 0; // 0 = record, 1 = play
int modeR = 0; // 0 = record, 1 = play

public void setup()
{
  frameRate(30);
  size(scrWidth, scrHeight, OPENGL);

  colorMode(HSB, 1.0f);
  
  font = loadFont("data/TwCenMT-Bold-216.vlw");

  oscP5 = new OscP5(this, 6449);
  
  recImage = loadImage("record.png");
  playImage = loadImage("play.png");
    
  bg = color(0, 0, 0);
}

public void draw()
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

public void oscEvent(OscMessage msg)
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

  static public void main(String args[]) {
    PApplet.main(new String[] { "--present", "--bgcolor=#666666", "--hide-stop", "SmearyGfx" });
  }
}

unit Unit2;

interface
Const
  SiteArray : array[0..25] of string = (
    'website0.tga',
    'website1a.tga',
    'website1b.tga',
    'website1c.tga',
    'website2.tga',
    'website3a.tga',
    'website3b.tga',
    'website4.tga',
    'website5.tga',
    'website6.tga',
    'website7.tga',
    'website8.tga',
    'website9.tga',
    'website10.tga',
    'website11a.tga',
    'website11b.tga',
    'website11c.tga',
    'website12a.tga',
    'website12b.tga',
    'website13.tga',
    'website14.tga',
    'website15.tga',
    'website16a.tga',
    'website16b.tga',
    'website17.tga',
    'website18.tga');

procedure glDrawClock(t : TDateTime);    
Procedure glDrawStick(x1, y1, z1, x2, y2, z2 : double);
procedure glDrawSheets(PaperTex : Longword);
procedure glDrawSheet(PaperTex : Longword);

procedure glDrawPresCube;      
procedure moveCube(State : Byte; timescale : double; variation : byte);

var
  ClockRotation : double = 0;
  cube_l : double = 5;
  cube_w : double = 5;
  cube_h : double = 5;
  
  cube_x : double = 0;
  cube_y : double = 0;
  cube_z : double = 0;
  
  cube_rot1 : double = 0;
  cube_rot2 : double = 0;
  cube_rot3 : double = 0;

  sch1 : double = 0;
  sch2 : double = 0;
  sch3 : double = 0;
  sch4 : double = 0;
  sch5 : double = 0;
  sch6 : double = 0;

  xdir:shortInt = 1;
  ydir :shortInt = 1;
  zdir :shortInt = 1;


Type
  TCGMatrix = array [0..3, 0..3] of Single;




implementation

uses dglOpenGL, DateUtils, unit3;

const
  C_cube_x = 100;
  C_cube_y = 140;
  C_cube_z = 50;

  moveSpeed = 0.5;
  MaxMove = 30;    
  MaxRot = 180;
  MaxScale = 20;
  MaxScher = 5;

procedure moving(var dir : shortint; var pos : double; timescale : double);
Begin
  if MaxMove - abs(pos) > 0 then
    pos := pos - dir*(sqr((MaxMove-abs(pos))/MaxMove)+5)*MaxMove*moveSpeed * timescale
  else Begin dir := -dir; pos := dir*(MaxMove-1); End;
End;
procedure rotating(var dir : shortint; var pos : double; timescale : double);
Begin
  if MaxRot - abs(pos) > 0 then
    pos := pos - dir*(sqr((MaxRot-abs(pos))/MaxRot)+5)*MaxRot*moveSpeed * timescale
  else Begin dir := -dir; pos := dir*(MaxRot-1); End;
End;
procedure scaling(var dir : shortint; var pos : double; timescale : double);
Begin
  if MaxScale - abs(pos) > 0 then
    pos := pos - dir*(sqr((MaxScale-abs(pos))/MaxScale)+5)*MaxScale*moveSpeed * timescale
  else Begin dir := -dir; pos := dir*(MaxScale-1); End;
End;

procedure schering(var dir : shortint; var pos, pos2 : double; timescale : double);
Begin
  if MaxScher - abs(pos) > 0 then
    pos := pos - dir*(sqr((MaxScher-abs(pos))/MaxScher)+5)*MaxScher*moveSpeed * timescale
  else Begin dir := -dir; pos := dir*(MaxScher-1); End;
End;

procedure glScheren6f(s1, s2, s3, s4, s5, s6 : double);
var
  Scheren : TCGMatrix;
Begin                  
  Scheren[0, 0] := 1;
  Scheren[0, 1] := s1;
  Scheren[0, 2] := s2;
  Scheren[0, 3] := 0;

  Scheren[1, 0] := s3;
  Scheren[1, 1] := 1;
  Scheren[1, 2] := s4;
  Scheren[1, 3] := 0;

  Scheren[2, 0] := s5;
  Scheren[2, 1] := s6;
  Scheren[2, 2] := 1;
  Scheren[2, 3] := 0;  

  Scheren[3, 0] := 0;
  Scheren[3, 1] := 0;
  Scheren[3, 2] := 0;
  Scheren[3, 3] := 1;

  glMultMatrixf(@scheren);

End;

procedure moveCube(State : Byte; timescale : double; variation : byte);
Begin
  if timeScale < 1 then 
  case State of
    9 : Begin
          if (variation and 1) = 1 then moving(xdir, cube_x, timescale) else cube_x := 0;
          if (variation and 2) = 2 then moving(ydir, cube_y, timescale) else cube_y := 0;
          if (variation and 4) = 4 then moving(zdir, cube_z, timescale) else cube_z := 0;
        End;
     12 : Begin
          if (variation and 1) = 1 then rotating(xdir, cube_rot1, timescale) else cube_rot1 := 0;
          if (variation and 2) = 2 then rotating(ydir, cube_rot2, timescale) else cube_rot2 := 0;
          if (variation and 4) = 4 then rotating(zdir, cube_rot3, timescale) else cube_rot3 := 0;
        End;

    11 : Begin
          if (variation and 1) = 1 then scaling(xdir, cube_l, timescale) else cube_l := 5;
          if (variation and 2) = 2 then scaling(ydir, cube_w, timescale) else cube_w := 5;
          if (variation and 4) = 4 then scaling(zdir, cube_h, timescale) else cube_h := 5;
        End;


    13 : Begin
          if (variation and 1) = 1 then schering(xdir, sch1, sch2, timescale) else begin sch1 := 0; sch2 := 0; end;
          if (variation and 2) = 2 then schering(ydir, sch3, sch4, timescale) else begin sch3 := 0; sch4 := 0; end;
          if (variation and 4) = 4 then schering(zdir, sch5, sch6, timescale) else begin sch5 := 0; sch6 := 0; end;
        End;
  end;
End;


procedure glDrawPresCube;
Begin
  glPushMatrix;
  glTranslatef(C_cube_x, C_cube_y, C_cube_z);
  glTranslatef(cube_x, cube_y, cube_z);
  glRotatef(cube_rot1, 1, 0, 0);       
  glRotatef(cube_rot2, 0, 1, 0);
  glRotatef(cube_rot3, 0, 0, 1);
  glScalef(cube_l, cube_w, cube_h);
  glScheren6f(sch1, sch2, sch3, sch4, sch5, sch6);
  glBegin(GL_QUAD_STRIP);
    glColor3f(1, 0, 0);
    glVertex3f(-1, -1,  1);
    glVertex3f(-1, -1, -1);
    glColor3f(1, 1, 0);
    glVertex3f( 1, -1,  1);
    glVertex3f( 1, -1, -1);
    glColor3f(0, 1, 0);
    glVertex3f( 1,  1,  1);
    glVertex3f( 1,  1, -1);
    glColor3f(0, 1, 1);
    glVertex3f(-1,  1,  1);
    glVertex3f(-1,  1, -1);
    glColor3f(0, 0, 1);
    glVertex3f(-1, -1,  1);
    glVertex3f(-1, -1, -1);
  glEnd();

  glBegin(GL_QUADS);
    glColor3f(1, 1, 1);
    glVertex3f(-1,  1, -1);
    glVertex3f( 1,  1, -1);
    glVertex3f( 1, -1, -1);
    glVertex3f(-1, -1, -1);

    glVertex3f(-1, -1,  1);
    glVertex3f( 1, -1,  1);
    glVertex3f( 1,  1,  1);
    glVertex3f(-1,  1,  1);
  glEnd();
  glPopMatrix;
End;



Procedure glDrawStick(x1, y1, z1, x2, y2, z2 : double);
Begin
  glBegin(GL_QUAD_STRIP);
    glColor3f(0.4, 0.3, 0);
    glVertex3f(x1+0.05, y1-0.025, z1);
    glVertex3f(x2+0.05, y2-0.025, z2);

    glVertex3f(x1-0.05, y1-0.025, z1);
    glVertex3f(x2-0.05, y2-0.025, z2);

    glVertex3f(x1-0.05, y1+0.025, z1);
    glVertex3f(x2-0.05, y2+0.025, z2);

    glVertex3f(x1+0.05, y1+0.025, z1);
    glVertex3f(x2+0.05, y2+0.025, z2);

    glVertex3f(x1+0.05, y1-0.025, z1);
    glVertex3f(x2+0.05, y2-0.025, z2);
  glEnd;
   glBegin(GL_QUADS);
    glColor3f(0.4, 0.3, 0);
    glVertex3f(x2-0.05, y2+0.025, z2);
    glVertex3f(x2-0.05, y2-0.025, z2);  
    glVertex3f(x2+0.05, y2-0.025, z2);
    glVertex3f(x2+0.05, y2+0.025, z2);

    glVertex3f(x1+0.05, y1+0.025, z1);
    glVertex3f(x1+0.05, y1-0.025, z1);
    glVertex3f(x1-0.05, y1-0.025, z1);
    glVertex3f(x1-0.05, y1+0.025, z1);
  glEnd;
End;

procedure glDrawSheet(PaperTex : Longword);
Begin
  glPushMatrix;   
  glEnable(GL_TEXTURE_2D);
  glBindTexture(GL_TEXTURE_2D, PaperTex);
  glBegin(GL_QUADS);
    glColor3f(1, 0.99, 0.97);
    glTexCoord2f(0, 1-0.768); glVertex3f(-1.024, 0, 0);
    glTexCoord2f(1, 1-0.768); glVertex3f(1.024, 0, 0);
    glTexCoord2f(1, 1); glVertex3f(1.024, 0.2, 1.536);
    glTexCoord2f(0, 1); glVertex3f(-1.024, 0.2, 1.536);
  glEnd;
  glDisable(GL_TEXTURE_2D);
  glBegin(GL_QUADS);
    glColor3f(1, 0.99, 0.97);
    glVertex3f(-1.024, 0.25, 1.536);
    glVertex3f(1.024, 0.25, 1.536);
    glVertex3f(1.024, 0.05, 0);
    glVertex3f(-1.024, 0.05, 0);
    glVertex3f(1.024, 0, 0);
    glVertex3f(-1.024, 0, 0);
    glVertex3f(-1.024, 0.05, 0);
    glVertex3f(1.024, 0.05, 0);
    glVertex3f(1.024, 0.25, 1.536);
    glVertex3f(-1.024, 0.25, 1.536);
    glVertex3f(-1.024, 0.2, 1.536);
    glVertex3f(1.024, 0.2, 1.536);  
    glVertex3f(-1.024, 0.05, 0);
    glVertex3f(-1.024, 0, 0);
    glVertex3f(-1.024, 0.2, 1.536);
    glVertex3f(-1.024, 0.25, 1.536);
    glVertex3f(1.024, 0.25, 1.536);
    glVertex3f(1.024, 0.2, 1.536); 
    glVertex3f(1.024, 0, 0);
    glVertex3f(1.024, 0.05, 0);
  glEnd;
  glPopMatrix;
End;

     

procedure glDrawSheets(PaperTex : Longword);
Begin
  glPushMatrix;
  glTranslatef(180, 130, 31.245);
  glDrawSheet(PaperTex);

  glDrawStick(-0.9, -0.035, -1, 0, 0.325, 1.8);
  glDrawStick(0.9, -0.035, -1, 0, 0.325, 1.8);
  glDrawStick(0, 1.035, -1, 0, 0.35, 1.8);


  glPopMatrix;
End;



procedure glDrawClock(t : TDateTime);
Var
  I : Integer;
  w : double;
Begin
  glPushMatrix;
  glTranslatef(135, 130, 15);
  glRotatef(ClockRotation/3, 0, 1, 0);
  glRotatef(ClockRotation, 1, 0, 0);
  glBegin(GL_TRIANGLE_FAN);
    glColor3f(0, 0, 0.6);
    for I := 360 downto 0 do
    Begin
      glVertex3f(cos(i*pi/180), sin(i*pi/180), 0);
    EnD;
  glEnd;
  glBegin(GL_TRIANGLE_FAN);
    glColor3f(0, 0, 1);
    for I := 0 to 360 do
    Begin
      glVertex3f(cos(i*pi/180), sin(i*pi/180), 0.2);
    EnD;
  glEnd;
  glBegin(GL_QUAD_STRIP);
    glColor3f(0, 0, 0.6);
    for I := 360 downto 0 do
    Begin
      glVertex3f(cos(i*pi/180), sin(i*pi/180), 0);
      glVertex3f(cos(i*pi/180)*1.05, sin(i*pi/180)*1.05, 0);
    EnD;
  glEnd;
  glBegin(GL_QUAD_STRIP);
    glColor3f(0, 0, 0.6);
    for I := 0 to 360 do
    Begin
      glVertex3f(cos(i*pi/180), sin(i*pi/180), 0.25);
      glVertex3f(cos(i*pi/180)*1.05, sin(i*pi/180)*1.05, 0.25);
    EnD;
  glEnd;
  glBegin(GL_QUAD_STRIP);
    glColor3f(0, 0, 0.3);
    for I := 360 downto 0 do
    Begin
      glVertex3f(cos(i*pi/180), sin(i*pi/180), 0.25);
      glVertex3f(cos(i*pi/180), sin(i*pi/180), 0);
    EnD;
  glEnd;
  glBegin(GL_QUAD_STRIP);
    glColor3f(0, 0, 0.6);
    for I := 0 to 360 do
    Begin
      glVertex3f(cos(i*pi/180)*1.05, sin(i*pi/180)*1.05, 0.25);
      glVertex3f(cos(i*pi/180)*1.05, sin(i*pi/180)*1.05, 0);
    EnD;
  glEnd;

  glPushMatrix;
  for I := 0 to 59 do
  Begin
    glBegin(GL_QUADS);
      glColor3f(0, 1, 1);
      if i mod 5 = 0 then w := 0.02 else w := 0.01;
      glVertex3f(0.9+w, -w, 0.206);
      glVertex3f(0.9+w, w, 0.206);
      glVertex3f(0.8-w, w, 0.206);
      glVertex3f(0.8-w, -w, 0.206);
    glEnd;
    glRotatef(360/60, 0, 0, 1);
  EnD;
  glPopMatrix;

  glPushMatrix;
  glRotatef(360/12*(12- HourOf(t)-MinuteOf(t)/60), 0, 0, 1);
  glBegin(GL_QUADS);
    glColor3f(0, 0, 0);
    glVertex3f(0, -0.03, 0.2061);
    glVertex3f(0, 0.03, 0.2061);
    glVertex3f(-0.7, 0.03, 0.2061);
    glVertex3f(-0.7, -0.03, 0.2061);
  glEnd;
  glPopMatrix;

  glPushMatrix;
  glRotatef(360/60*(60- MinuteOf(t)), 0, 0, 1);
  glBegin(GL_QUADS);
    glColor3f(0, 0, 0);
    glVertex3f(0, -0.02, 0.2062);
    glVertex3f(0, 0.02, 0.2062);
    glVertex3f(-0.9, 0.02, 0.2062);
    glVertex3f(-0.9, -0.02, 0.2062);
  glEnd;
  glPopMatrix;

  glPushMatrix;
  glRotatef(360/60*(60- SecondOf(t)-MilliSecondOf(t)/1000), 0, 0, 1);
  glBegin(GL_QUADS);
    glColor3f(0, 1, 0);
    glVertex3f(0, -0.01, 0.2063);
    glVertex3f(0, 0.01, 0.2063);
    glVertex3f(-0.8, 0.01, 0.2063);
    glVertex3f(-0.8, -0.01, 0.2063);
  glEnd;
  glPopMatrix;

  glPopMatrix;
End;

end.
 
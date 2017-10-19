unit Unit1;

interface                                 

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ComCtrls, ExtCtrls, dglOpenGL, AppEvnts;

type
  TForm1 = class(TForm)
    ApplicationEvents1: TApplicationEvents;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure ApplicationEvents1Idle(Sender: TObject; var Done: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word;
      Shift: TShiftState);
    procedure FormResize(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word;
      Shift: TShiftState);
  private
    { Private-Deklarationen }
    procedure setupGL;
    procedure Init;
    procedure Render; 
    procedure IdleHandler(var Done: Boolean);
    procedure ErrorHandler;
    procedure glMovePerson;
  public
    { Public-Deklarationen }
  end;
 
TFogColor = record
  Red : single;
  Green : single;
  Blue : single;
  Alpha : single;
end;
TTGAFile = record
    iType: byte;  // should be 2
     w, h: word;  // Width, Height
      bpp: byte;  // Byte per Pixel
     data: ^byte; // Pixels, dynamic length
  end;

const
  lx = 255;
  ly = 255;

var
  Form1: TForm1;
  DC, RC : HDC;
  Framecount : Integer;
  Landscape : array[0..lx, 0..ly] of byte;
  positionX : double = 180;
  positionY : double = 128.27;
  viewheight : double;
  angleVertical : double = -7.45;
  angleHorizontal : double = -90;
  timedelay : Integer;
  moveForward, moveBackward : Boolean;
  strafeLeft, strafeRight : Boolean;
  jumpSpeed : double;
  jumpHeight : double;
  actionJump : Boolean;
  SandTex : Longword;
  PaperTex : Longword;
  ActualWebPage : Integer;
  KeyAllow : Boolean = false;
  isFog : Boolean = true;
  variation : byte = 0;
  light : boolean = false;
  draw : boolean = true;

const
  C_NEAR_CLIPPING = 1;
  C_FAR_CLIPPING  = 1000;

  C_EYES_HEIGHT = 2;

  C_VERTICAL_ANGLE_OFFSET = -90;

  C_VERTICAL_ANGLE_MAX = 40;
  C_VERTICAL_ANGLE_MIN = -20;

  C_WALK_SPEED = 11.2;
  C_STRAFE_SPEED = 10.5;
  C_ROTATE_VERTICAL_SPEED = 2;
  C_ROTATE_HORIZONTAL_SPEED = 4;

  C_JUMP_SPEED = 3;

  C_GRAVITY = 9.81;

  C_TIME_SCALE_FACTOR = 1000;

implementation

uses DateUtils, Math, unit2, unit3;

{$R *.dfm}

function LoadTGA(const filename: string): TTGAFile;
var f: file; bytes: longword;
begin
  assign(f, filename);
  reset(f, 1);
 
  // type
  seek(f, 2);
  blockread(f, result.iType, 1);
 
  // w, h, bpp
  seek(f, 12);
  blockread(f, result.w, 5);
  result.bpp := result.bpp div 8;

  // data
  bytes := result.w * result.h * result.bpp;
  getmem(result.data, bytes);
  seek(f, 18);
  blockread(f, result.data^, bytes);

  close(f);
end;
procedure TGATexture(const filename: string; var TexID: longword);
var
  tex: TTGAFile;
  glFormat: longword;
begin
  tex := LoadTGA(filename);
  if tex.iType = 2 then
  begin
    glGenTextures(1, @TexID);
    glBindTexture(GL_TEXTURE_2D, TexID);

    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    if tex.bpp = 3 then glFormat := GL_BGR
      else glFormat := GL_BGRA;

    glTexImage2D(GL_TEXTURE_2D, 0, tex.bpp, tex.w, tex.h,
      0, glFormat, GL_UNSIGNED_BYTE, tex.data);

    FreeMem(tex.data);
  end;
end;
procedure LoadLandscape;
Var
  BMP : TBitmap;
  i, j : Integer;
Begin
  BMP := TBitmap.Create;
  BMP.LoadFromFile('landscape.bmp');
  For J := 0 to ly do
    for I := 0 to lx do
    Begin
      Landscape[I, ly-J] := 255-BMP.Canvas.Pixels[I, J];
    End;
  BMP.Free;
  TGATexture('sand.tga', SandTex);
End;

procedure drawLandscapeVertex(i, j : integer);
var

  z : double;
Begin
  z := landscape[i, j]/256;
  //glColor3f(1-0.1*z, 1-0.1*z, 0);
  glColor3f(1, 1, 0);
  glTexCoord2f(i/lx*64,j/ly*64);
  glVertex3f(i, j, z*32);
End;

procedure glDrawLandscape;
var
  I, J : Integer;
Begin
  glPushMatrix;
  glBegin(GL_TRIANGLE_STRIP);
    For J := ly-1 downto 0 do
    Begin
      if odd(j) then
       For I := 0 to lx do
      Begin
        drawLandscapeVertex(i, j+1);
        drawLandscapeVertex(i, j);
      End else
       For I := lx downto 0 do
      Begin
        drawLandscapeVertex(i, j);
        drawLandscapeVertex(i, j+1);
      End
    End;
  glEnd;
  glPopMatrix;
End;

procedure TForm1.SetupGL;
begin
  glEnable(GL_DEPTH_TEST);          //Tiefentest aktivieren
 // glEnable(GL_CULL_FACE);           //Backface Culling aktivieren
  glEnable(GL_FOG);
end;

procedure TForm1.Init;
var FogColor : TFogColor;
Begin
  Framecount := 0; 

  FogColor.Red := 0.2; //Volles Rot
  FogColor.Green := 0.3; //Kein Grün
  FogColor.Blue := 0.5; //Kein Blau
  FogColor.Alpha := 0.2; //Kein Alpha

  glFogfv(GL_FOG_COLOR, @FogColor);
  glFogi(GL_FOG_MODE, GL_EXP);
  glFogf(GL_FOG_DENSITY, 0.01);
end;

procedure TForm1.Render;
Begin             
  if draw then glClearColor(0.4, 0.6, 0.9, 0.0) else
    glClearColor(0, 0, 0, 0.0);
  glClear(GL_COLOR_BUFFER_BIT or GL_DEPTH_BUFFER_BIT);

  if draw then Begin
    glMatrixMode(GL_PROJECTION);
    glLoadIdentity;
    //glOrtho(-1, 1, -1, 1, 0.1, C_FAR_CLIPPING);
    gluPerspective(45.0, ClientWidth/ClientHeight, C_NEAR_CLIPPING, C_FAR_CLIPPING);

    glMatrixMode(GL_TEXTURE);
    glLoadIdentity;
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity;

    glMovePerson;
    glEnable(GL_TEXTURE_2D);
    glBindTexture(GL_TEXTURE_2D,SandTex);
    glDrawLandscape;
    glDisable(GL_TEXTURE_2D);
    glDrawClock(now);

    glDrawSheets(PaperTex);

    glDrawPresCube;

    if light then glEnable(GL_LIGHTING) else glDisable(GL_LIGHTING);
  end;

  SwapBuffers(DC);
End;

procedure TForm1.glMovePerson;
Begin
  glRotated(-angleVertical, 1, 0, 0);
  glRotated(angleHorizontal, 0, 1, 0);
  //glTranslatef(-positionX, -positionY, -viewheight);
  gluLookAt(positionX, positionY, viewheight, positionX+1, positionY, viewheight, 0, 0, 1);
End;

procedure TForm1.ErrorHandler;
Begin
 // Form1.Caption := gluErrorString(glGetError);
End;

Procedure ChangeWebPage(Page : Integer);
Begin
  If (Page < Length(SiteArray)) And (Page >= 0) then
  Begin
    ActualWebPage := Page;
    TGATexture(siteArray[ActualWebPage], PaperTex);
  end;
End;   

procedure TForm1.FormCreate(Sender: TObject);
begin
  Cursor := crNone;
  SetCursorPos(Screen.Width div 2, Screen.Height div 2);

  DC := GetDC(Handle);
  if not InitOpenGL then Application.Terminate;
  RC := CreateRenderingContext(DC,          //Device Contest
                             [opDoubleBuffered], //Optionen
                             32,          //ColorBits
                             24,          //ZBits
                             0,           //StencilBits
                             0,           //AccumBits
                             0,           //AuxBuffers
                             0);          //Layer
  ActivateRenderingContext(DC, RC);
  setupGL;
  Init;

  LoadLandscape;
  ChangeWebPage(0);
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  Cursor := crDefault;
  DeactivateRenderingContext;
  DestroyRenderingContext(RC);
  ReleaseDC(Handle, DC);
end;

procedure TForm1.IdleHandler(var Done: Boolean);
Var
  StartTime : Integer;
  MousePosition : TPoint;
  rotateVertical, rotateHorizontal : Double;
  timescale : double;
  H1, H2, H3, H4, H12, H34, D1, D2 : Double;
begin
  if not Application.Active then exit;
  StartTime := GetTickCount;
  timescale := (StartTime - TimeDelay) / C_TIME_SCALE_FACTOR;
  TimeDelay := StartTime;

  moveCube(ActualWebPage, timeScale, variation);
  Caption := IntToStr(ActualWebPage);

  ClockRotation := ClockRotation+30*timescale;
  GetCursorPos(MousePosition);
  SetCursorPos(Screen.Width div 2, Screen.Height div 2);

  rotateHorizontal := ((Screen.Width div 2) - MousePosition.X) * C_ROTATE_HORIZONTAL_SPEED * timeScale;
  rotateVertical := ((Screen.Height div 2) - MousePosition.Y) * C_ROTATE_VERTICAL_SPEED * timeScale;

  if KeyAllow then Begin
    angleHorizontal := angleHorizontal - rotateHorizontal;
    angleVertical := angleVertical - rotateVertical;
  End;

  if angleVertical < C_VERTICAL_ANGLE_MIN then angleVertical := C_VERTICAL_ANGLE_MIN else
   if angleVertical > C_VERTICAL_ANGLE_MAX then angleVertical := C_VERTICAL_ANGLE_MAX;



  if moveForward and not moveBackward then
  Begin
    positionY := positionY - C_WALK_SPEED * timeScale * sin(angleHorizontal*PI/180);
    positionX := positionX + C_WALK_SPEED * timeScale * cos(angleHorizontal*PI/180);
  end else if not moveForward and moveBackward then
  Begin
    positionY := positionY + C_STRAFE_SPEED * timeScale * sin(angleHorizontal*PI/180);
    positionX := positionX - C_STRAFE_SPEED * timeScale * cos(angleHorizontal*PI/180);
  end;

  if strafeLeft and not strafeRight then
  Begin
    positionY := positionY + C_WALK_SPEED * timeScale * cos(angleHorizontal*PI/180);
    positionX := positionX + C_WALK_SPEED * timeScale * sin(angleHorizontal*PI/180);
  end else if not strafeLeft and strafeRight then
  Begin
    positionY := positionY - C_WALK_SPEED * timeScale * cos(angleHorizontal*PI/180);
    positionX := positionX - C_WALK_SPEED * timeScale * sin(angleHorizontal*PI/180);
  End;


  if (positionX>0) and (positionX<lx) and (positionY>0) and (positionY<ly) then
  Begin
    H1 := landscape[Floor(positionX), Floor(positionY)];
    H2 := landscape[ Ceil(positionX), Floor(positionY)];
    H3 := landscape[Floor(positionX),  Ceil(positionY)];
    H4 := landscape[ Ceil(positionX),  Ceil(positionY)];
    D1 := Ceil(positionX) - positionX;
    D2 := Ceil(positionY) - positionY;
    H12 := D1*H1+(1-D1)*H2;      
    H34 := D1*H3+(1-D1)*H4;

    viewheight := (D2*H12+(1-D2)*H34)/8 + C_EYES_HEIGHT;
  End else viewheight := C_EYES_HEIGHT;

  if actionJump then
  Begin
    jumpSpeed := C_JUMP_SPEED;
    actionJump := false;
  End else if (jumpHeight > 0) or (jumpSpeed > 0) then
  Begin
    jumpHeight := jumpHeight + jumpSpeed * timeScale;
    jumpSpeed := jumpSpeed - C_GRAVITY * timeScale;
    if jumpHeight < 0 then jumpHeight := 0;
  End;

 // caption := FloatToStrF(positionX, ffFixed, 6, 2) + '; '+
 //            FloatToStrF(positionY, ffFixed, 6, 2) + '; '+
 //            FloatToStrF(viewheight, ffFixed, 6, 2);

  viewHeight := viewHeight + jumpHeight;

  Render;

  ErrorHandler;

  Done:= false;
end;

procedure TForm1.ApplicationEvents1Idle(Sender: TObject;
  var Done: Boolean);
begin
  idleHandler(Done);
end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE : close;
    ord('W') : if KeyAllow then moveForward := true;
    ord('S') : if KeyAllow then moveBackward := true;
    ord('A') : if KeyAllow then strafeLeft := true;
    ord('D') : if KeyAllow then strafeRight := true;
    ord('G') : Begin
                 positionX := 180;
                 positionY := 128.27;
                 angleHorizontal := -90;
                 angleVertical := -7.45;
               End;    
    ord('J') : Begin
                 positionX := 180;
                 positionY := 128.27;
                 angleHorizontal := -170;
                 angleVertical := +15;
               End;
    ord('N') : Begin
                 isFog := not isFog;
                 if isFog then glEnable(GL_FOG) else glDisable(GL_FOG);
               End;
    ord('1') : variation := variation XOR 1;
    ord('2') : variation := variation XOR 2;
    ord('3') : variation := variation XOR 4;
    VK_SPACE : if KeyAllow then actionJump := true;
    VK_F1 : KeyAllow := False;
    VK_F4 : KeyAllow := True;                   
    VK_F9 : light := not light;              
    VK_F10 : draw := not draw;
    VK_RIGHT : ChangeWebPage(ActualWebPage+1);
    VK_LEFT : ChangeWebPage(ActualWebPage-1);
  End;
end;

procedure TForm1.FormResize(Sender: TObject);
begin
  glViewport(0, 0, ClientWidth, ClientHeight);
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity;
  gluPerspective(45.0, ClientWidth/ClientHeight, C_NEAR_CLIPPING, C_FAR_CLIPPING);
 
  glMatrixMode(GL_MODELVIEW);
  glLoadIdentity;
end;

procedure TForm1.FormShow(Sender: TObject);
begin
//  WindowState := wsMaximized;
end;

procedure TForm1.FormKeyUp(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  case Key of
    VK_ESCAPE : close;
    ord('W') : moveForward := false;
    ord('S') : moveBackward := false; 
    ord('A') : strafeLeft := false;
    ord('D') : strafeRight := false;
  End;
end;

end.

unit Unit3;

interface

uses dglOpenGL;

const
  TexH = 1024;
  TexW = 1024;
Type
  Farben4 = record R, G, B, A : GLFloat; end;
Var
  SheetTextur : array[1..TexW, 1..TexH] of Farben4;

procedure loadTextur(filename : String);

implementation

uses Graphics;

procedure TColor2RGB(const Color: TColor; var F : Farben4);
begin
  // convert hexa-decimal values to RGB
  F.R := Color and $FF;
  F.G := (Color shr 8) and $FF;
  F.B := (Color shr 16) and $FF;
  F.A := 0;
end;

procedure loadTextur(filename : String);
var
  bmp : TBitmap;
  I, J : Integer;
Begin
  bmp := Tbitmap.Create;

  bmp.LoadFromFile(filename);

  For I := 0 to bmp.Height-1 do
  For J := 0 to bmp.Width-1 do
  Begin
    TColor2RGB(bmp.Canvas.Pixels[J, I], SheetTextur[J, I]);
  End;

  bmp.free;
End;

end.
 
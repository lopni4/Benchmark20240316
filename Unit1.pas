unit Unit1;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Generics.Collections, System.Variants, System.Zip, System.IOUtils, System.DateUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.Objects, FMX.ActnList, FMX.Controls.Presentation, FMX.Edit, FMX.StdCtrls;

type
  TForm1 = class(TForm)
    Timer: TTimer;
    Edit: TEdit;
    ExitButton: TButton;
    fpsLabel: TLabel;
    EditButton: TButton;
    p: TPaintBox; {здесь всё рисуем}
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Activity;
    procedure Setup;
    procedure TimerTimer(Sender: TObject);
    procedure ExitButtonClick(Sender: TObject);
    procedure EditButtonClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

const
  spriteHeight = 100;
  spriteWidth  = 100;
  runningSpeed = 10;
  zipFileName = 'resource.if';

var

  {~~~ персонажи ~~~}
  a               {персонажи}
    : array [1..1000] of TRectF;
  X, Y            {координаты персонажей}
    : array [1..1000] of Single;
  NumberOfCharacters
    : Integer;    {сколько персонажей на экране}

  {~~~ картинки ~~~}
  aFrame          {все картинки}
    : array [1..100,1..100] of TBitmap;
  SrcRect         {прямоугольник для всех картинок}
    : TRectF;
  NumberOfFrames, {количество кадров в анимации}
  currentFrame,   {номер кадра}
  character       {номер персонажа/анимации}
   : array [1..1000] of Integer;

  {~~~ движение ~~~}
  Z               {z-порядок}
    : TList<integer>;
  step            {шаг перемещения}
    : array [ 1..1000 ] of Single;

  {~~~ прочее ~~~}
  oldTime, newTime{измерение времени}
    : TDateTime;

{$R *.fmx}

procedure TForm1.FormCreate(Sender: TObject);
var i, j: Integer;
begin
  randomize;
  p.SendToBack;
  Z := TList<integer>.Create;
  for i := 1 to 100 do
    for j := 1 to 100 do
      aFrame [ i , j ] := TBitmap.Create;
end;

procedure TForm1.TimerTimer(Sender: TObject);       begin   Activity;               end;

procedure TForm1.EditButtonClick(Sender: TObject);  begin   Setup;                  end;

procedure TForm1.ExitButtonClick(Sender: TObject);  begin   Application.Terminate;  end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
var i, j: Integer;
begin
  Z.Free;
  for i := 1 to 100 do
    for j := 1 to 100 do
      aFrame [ i , j ].Free;
end;



procedure TForm1.Setup;
var
  NumberOfPictureSets, j, k, v, c: Integer;
  d, t: string;
  f: text;
  cn: array [1..100] of string; {путь до директорий с картинками}

  Zip: TZipFile;
  Bytes: TBytes;

  ms: TMemoryStream;

begin
  val ( Edit.Text , v , c );
  if ( c = 0 ) and ( v > 0 )
  then begin
    SrcRect := TRectF.Create ( 0, 0, 100, 100 );
    ms := TMemoryStream.Create;
    Edit.Visible := False;
    EditButton.Visible := False;
    numberOfCharacters := v;

    getDir ( 0 , d );

    AssignFile ( f, d + '\log.log' );
    ReWrite ( f );
    writeLn ( f , 'Folder ', d );

    Zip:=TZipFile.Create;
    if not FileExists ( zipFileName )
    then begin
      writeLn ( d , 'The file resource.if does not exist' );
      CloseFile ( f );
      Application.Terminate;
    end;
    Zip.Open( zipFileName , zmRead );

    {читаем список директорий}
    j := 0;
    for t in Zip.FileNames do  begin
      if ( t.Length > Length ('graphics/') ) and ( t.EndsWith('/') )
      then begin
        Inc ( j );
        cn [ j ] := t;
      end;
    end;
    NumberOfPictureSets := j;
    writeLn ( f , j , ' picture sets' );

    {читаем картинки}
    for j := 1 to NumberOfPictureSets do  begin
      NumberOfFrames [ j ] := 0;
      for t in Zip.FileNames do
        if ( t.Contains( cn [ j ] ) ) and ( t.EndsWith('.png') )
        then begin

          Inc ( NumberOfFrames [ j ] );
          ms.Clear;
          Zip.Read( t , Bytes );
          ms.Write( Bytes [ 0 ] , Length ( Bytes ) );
          ms.Seek( 0 , 0 );
          aFrame [ j , NumberOfFrames [ j ] ].LoadFromStream( ms );

        end;
      writeLn ( f , NumberOfFrames [ j ] , ' pictures in the set number ', j );
    end;
    Zip.Close;
    Zip.Free;

    {готовим персонажей}
    for j := 1 to numberOfCharacters do  begin
      X [ j ] := random (1920 - spriteWidth);
      Y [ j ] := random (1080 - spriteHeight);
      Z.Add ( j );
      a [ j ] := TRectF.Create ( X [ j ] , Y [ j ] , X [ j ] + spriteWidth , Y [ j ] + spriteHeight );
      character [ j ] := random ( NumberOfPictureSets ) + 1; writeLn ( f , j,' character dons on picture set ',character [ j ] );

      if cn [ character [ j ] ].EndsWith('run')
      then step [ j ] := random ( runningSpeed ) + runningSpeed
      else step [ j ] := random ( runningSpeed div 2 ) + runningSpeed div 2;

      writeLn ( f , 'speed ', Round ( step [ j ] ) );

      currentFrame [ j ] := random ( NumberOfFrames [ character [ j ] ] - 1 ) + 1; writeLn ( f , 'первая картинка ',currentFrame [ j ],' из ',numberOfFrames [ character [ j ] ] );
    end;
    writeLn ( f , 'z-order has ',Z.Count,' elements' );
    closeFile ( f );

    ms.Free;
    ExitButton.Visible := True;
    ExitButton.BringToFront;
    fpsLabel.BringToFront;
    newTime := Now;

    Timer.Enabled := True;
  end;
end;



procedure TForm1.Activity;
var
  i: Integer;
  span, fps: Double;
begin

  for I := 1 to NumberOfCharacters do  begin
    Inc ( currentFrame [ i ] );
    if currentFrame [ i ] > NumberOfFrames [ character [ i ] ]
    then currentFrame [ i ] := 1;
    X [ i ] := X [ i ] + step [ i ];
    if X [ i ] > 1920 - spriteWidth
    then X [ i ] := 0;
    with a [ i ] do  begin
      Left   := X [ i ];
      Right  := X [ i ] + spriteWidth;
      Top    := Y [ i ];
      Bottom := Y [ i ] + spriteHeight;
    end;
    z.Reverse; {здесь перелопачиваем z-порядок}
  end;

  p.Canvas.BeginScene;
  p.Canvas.Clear ( TAlphaColorRec.White );
  for I := 0 to z.Count - 1 do  begin
    p.Canvas.DrawBitmap ( aFrame [ character [ z[i] ] , currentFrame [ z[i] ] ] , SrcRect , a [ z[i] ] , 1 , True );
  end;
  p.Canvas.EndScene;

  oldTime       := newTime;
  newTime       := Now;
  span          := secondSpan ( oldTime, newTime );
  fps           := 1 / span;
  fpsLabel.Text := Round ( fps ).ToString;
end;

end.

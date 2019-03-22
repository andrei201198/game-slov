uses Timers, GraphABC, ABCObjects;
const
  DisplacementXleft = 10;
  DisplacementYleft = 30;
  DisplacementXright = 10;
  DisplacementYright = 10;
  CircleR = 20;
  GameTimeMax = 60;
  
  Words: array of string = ('Мышь', 'Автобус', 'Мама', 'Кошка', 'Дом', 'Солнце', 'Морковь', 'Алфавит', 'Гриб');
  
  OutcomeF = 'Ты прошел {0}/{1} уровней.';
  TimeF = 'Время: {0}/{1}';
  
  AbsMax = 4;
  MaxR = 200;

type
  TVector = Point;
  TCircleChar = class
    Instance: CircleABC;
    CharColor: Color;
    Stopped: boolean;
    Velocity: TVector;
    
    constructor ();
    begin
    end;
  end;

var
  //Флаги
  IsPlaying: boolean;
  
  //Данные
  // Постоянные данные
  W, H: integer;
  
  C: List<TCircleChar>;
  WordsI: integer;
  BG: RectangleABC;
  Message: RectangleABC;
  Stage: integer;
  
  GameTime: integer;
  GameTimeRect: TextABC;
  GameTimeTimer: Timer;
  
  Xleft, Yleft: integer;
  Xright, Yright: integer;
  
  // Временные данные
  MovedChar: TCircleChar;
  ClosestChar: TCircleChar;
  DX, DY: integer;
  SortedByX: List<TCircleChar>;
 
procedure SetNormalStyle(x: TCircleChar); forward;

function Dist(a, b: TCircleChar) := Sqrt(Sqr(b.Instance.Position.X - a.Instance.Position.X) + Sqr(b.Instance.Position.Y - a.Instance.Position.Y));

function IsEqual(): boolean;
begin
  Result := true;
  var i := 0;
  while (i < C.Count) and (C[i].Instance.Text = SortedByX[i].Instance.Text) do
  begin
    SortedByX[i].CharColor := clDeepSkyBlue;
    SetNormalStyle(SortedByX[i]);
    SortedByX[i].Stopped := true;
    Inc(i);
  end;
  
  Result := (i = C.Count) and SortedByX.Incremental((a, b)-> Dist(a, b)).All(a -> a <= MaxR);
end;

///Инициализация уровня.
procedure Initialize();
begin
  if C.Count > 0 then
    for var i := Objects.Count - 1 downto 0 do
      if (Objects[i] <> Message) and (Objects[i] <> GameTimeRect) and (Objects[i] <> BG) then
        Objects[i].Destroy();
  
  C.Clear();
  for var i := 1 to Words[WordsI].Length do
  begin
    C.Add(new TCircleChar());
    with C.Last() do
    begin
      CharColor := ARGB(100, Random(50, 255), 0, Random(50, 255));
      Instance := new CircleABC(Random(DisplacementXleft + CircleR, W - DisplacementXright - CircleR),
                                Random(DisplacementYleft + CircleR, H - DisplacementYright - CircleR),
                                CircleR, CharColor);
      Instance.Text := Words[WordsI].Chars[i];
    end;
    C.Last().Velocity := new TVector(Random(-AbsMax, AbsMax), Random(-AbsMax, AbsMax));
  end;
  GameTimeTimer.Start();
  GameTimeRect.Visible := true;
end;

procedure ShowMessage(s: string);
begin
  Message.Visible := true;
  Message.ToFront();
  Message.Text := s;
end;

procedure CheckTime();
begin
  if GameTime <= GameTimeMax then
  begin
    GameTimeRect.Text := Format(TimeF, GameTime, GameTimeMax);
    Inc(GameTime);
  end
  else
  begin
    GameTimeTimer.Stop();
    ShowMessage('Ты проиграл.');
    Sleep(1000);
    Halt();
  end;
end;

///Подготовка данных для работы игры.
procedure InitializeGame();
begin
  SetWindowIsFixedSize(true);
  SetWindowCaption('Слова');
  
  //Настройка флагов
  IsPlaying := false;
  
  //Настройка данных
  W := Window.Width;
  H := Window.Height;
  
  C := new List<TCircleChar>();
  
  BG := new RectangleABC(DisplacementXleft, DisplacementYleft, W - DisplacementXleft - DisplacementXright, H - DisplacementYleft - DisplacementYright, clLemonChiffon);
  
  Message := new RectangleABC(0, 0, W, H, clWhite);
  Message.Text := 'Игра в слова (уровень 1)';
  
  Stage := 1;
  
  GameTime := 0;
  GameTimeRect := new TextABC(0, 0, 14, '', clBlack);
  GameTimeTimer := new Timer(1000, CheckTime);
  
  Xleft := DisplacementXleft + 1;
  Yleft := DisplacementYleft + 1;
  Xright := W - DisplacementXright - CircleR * 2 - 1;
  Yright := H - DisplacementYright - CircleR * 2 - 1;
  
  MovedChar := new TCircleChar();
  ClosestChar := nil;
  
  SortedByX := new List<TCircleChar>();
end;

procedure SetSelectedStyle(x: TCircleChar);
begin
  x.Instance.Color := ARGB(100, clLightBlue.R, clLightBlue.G, clLightBlue.B);
  x.Instance.BorderColor := clBlue;
  x.Instance.FontColor := clPurple;
end;

procedure SetNormalStyle(x: TCircleChar);
begin
  x.Instance.Color := x.CharColor;
  x.Instance.BorderColor := clBlack;
  x.Instance.FontColor := clBlack;
end;

procedure SetClosestStyle(x: TCircleChar);
begin
  x.Instance.Color := clOrange;
  x.Instance.BorderColor := clRed;
  x.Instance.FontColor := clRed;
end;

procedure SelectClosest(a: TCircleChar);
var
  newClosest: TCircleChar;

begin
  var dMin := MaxR * 1.0;
  
  for var i := 0 to C.Count - 1 do
  begin
    var d := Dist(C[i], a);
    if (C[i].Instance <> a.Instance) and (d < dMin) then
    begin
      dMin := d;
      newClosest := C[i];
    end;
  end;
  
  if (newClosest = nil) and (ClosestChar <> nil) then SetNormalStyle(ClosestChar);
  if newClosest <> nil then
  begin
    if (ClosestChar <> nil) and (ClosestChar <> newClosest) then
      SetNormalStyle(ClosestChar);
    ClosestChar := newClosest;
    SetClosestStyle(ClosestChar);
  end;
end;

procedure MouseMove(x, y, mb: integer);
begin
  if IsPlaying then
    if mb = 1 then
      if MovedChar.Instance = nil then
      begin
        var i := 0;
        while (i < C.Count) and not C[i].Instance.PtInside(x, y) do Inc(i);
        if i < C.Count then
        begin
          MovedChar.CharColor := C[i].CharColor;
          MovedChar.Instance := C[i].Instance;
          
          with MovedChar do
          begin
            DX := x - Instance.Position.X;
            DY := y - Instance.Position.Y;
          end;
          SetSelectedStyle(MovedChar);
          
          ClosestChar := nil;
        end;
      end
      else
      begin
        var cx := x - DX;
        var cy := y - DY;
        
        if cx < DisplacementXleft then cx := Xleft;
        if cy < DisplacementYleft then cy := Yleft;
        
        if cx > Xright + 1 then cx := Xright;
        if cy > Yright + 1 then cy := Yright;
        
        MovedChar.Instance.Position := new Point(cx, cy);
        
        GameTimeRect.ToFront();
      end;
end;

procedure MouseUp(x, y, mb: integer);
begin
  if IsPlaying and (mb = 1) then
  begin
    if MovedChar.Instance <> nil then
    begin
      SetNormalStyle(MovedChar);
      MovedChar.Instance := nil;
      
      if ClosestChar <> nil then
        SetNormalStyle(ClosestChar);
      
     SortedByX := C.OrderBy(a -> a.Instance.Position.X).ToList();
      if Stage <= Words.Length then
        if IsEqual() then
        begin
          IsPlaying := false;
          
          BG.Visible := false;
          
          GameTimeRect.Visible := false;
          GameTimeTimer.Stop();
          
          Inc(WordsI);
          
          ShowMessage(Format(OutcomeF, Stage, Words.Length));
          Inc(Stage);
        end;
      
      if Stage > Words.Length then
      begin
        ShowMessage(Format('Ты прошел все {0} уровней!', Words.Length));
        Sleep(-1);
        Halt();
      end;
    end;
  end;
end;

procedure KeyDown(key: integer);
begin
  if not IsPlaying then
  begin
    Initialize();
    
    //Флаги
    IsPlaying := true;
    
    //Данные
    Message.Visible := false;
    
    BG.Visible := true;
    
    GameTime := 0;
    GameTimeRect.Text := 'начало...';
    
    MovedChar.CharColor := clTransparent;
    MovedChar.Instance := nil;
  end;
end;

procedure RandomMove();
begin
  if IsPlaying then
    for var i := 0 to C.Count - 1 do
    begin
      if not C[i].Stopped and ((MovedChar.Instance = nil) or (C[i].Instance <> MovedChar.Instance)) then
      begin
        C[i].Instance.MoveOn(C[i].Velocity.X, C[i].Velocity.Y);
        if (C[i].Instance.Position.X <= DisplacementXleft) or (C[i].Instance.Position.X >= W - DisplacementXright - CircleR * 2) then
          C[i].Velocity.X := -C[i].Velocity.X;
        if (C[i].Instance.Position.Y <= DisplacementYleft) or (C[i].Instance.Position.Y >= H - DisplacementYright - CircleR * 2) then
          C[i].Velocity.Y := -C[i].Velocity.Y;
      end;
      Sleep(-1);
    end;
end;

begin
  InitializeGame();
  
  OnMouseMove := MouseMove;
  OnMouseUp := MouseUp;
  OnKeyDown := KeyDown;
  
  while true do
  begin
    RandomMove();
    if IsPlaying and (MovedChar.Instance <> nil) then SelectClosest(MovedChar);
  end;
end.
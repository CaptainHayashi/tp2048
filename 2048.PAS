{ 2048 clone in Turbo Pascal.
- Licenced under the MIT licence.
}
program TP2048;
uses
    Crt;

{
- Types
}

type
    { Percentage weighting, used for deciding which tile to select. }
    Percentage = 0..100;

    { The possible states the game can take. }
    GameState = (InProgress, Won, Lost, Quit);

    Stage = 0..11; { Tile stage; 0 is the absence of a tile. }

    { Grid co-ordinates, measured in tiles.
      If you change these, change GridWidth and GridHeight too. }
    GridX = 1..4; { Grid X co-ordinate. 1 is the leftmost row. }
    GridY = 1..4; { Grid Y co-ordinate. 1 is the topmost column. }
    GridM = array [GridX, GridY] of Stage;

    { Screen co-ordinates, measured in characters. }
    ScreenX = 1..80; { Screen X co-ordinate. 1 is the leftmost row. }
    ScreenY = 1..25; { Screen Y co-ordinate. 1 is the topmost column. }

    { Specifiers of tile 'stages' (the various values of tiles).
      This includes the name to use when labeling tiles, the score value of
      the tile, the percentage probability it will be chosen when adding a
      tile (all of these must sum to 100!), and the foreground and background
      colours. }
    StageSpec = record
        Name            : String;
        Score           : Integer;
        PlacePercentage : Percentage;
        Foreground      : Byte;
        Background      : Byte;
    end;

{
- Constants
}

const
    { Number of tiles to place initially.
      Must be between 1 and GridX*GridY. }
    NumInitialTiles : Integer = 2;

    { If at least one tile of this stage is placed, the game is won. }
    LastStage : Stage = 11 { 2048 };

    { The stages available.  If adding or removing, change Stage and EndStage
      too.  The first stage is special as it represents an empty tile. }
    Stages: array[Stage] of StageSpec
    = ( ( Name            : ''
        ; Score           : 0
        ; PlacePercentage : 0
        ; Foreground      : Black
        ; Background      : Blue
        )
      , ( Name            : '2'
        ; Score           : 2
        ; PlacePercentage : 80
        ; Foreground      : Black
        ; Background      : LightGray
        )
      , ( Name            : '4'
        ; Score           : 4
        ; PlacePercentage : 20
        ; Foreground      : Black
        ; Background      : Cyan
        )
      , ( Name            : '8'
        ; Score           : 8
        ; PlacePercentage : 0
        ; Foreground      : DarkGray
        ; Background      : Cyan
        )
      , ( Name            : '16'
        ; Score           : 16
        ; PlacePercentage : 0
        ; Foreground      : DarkGray
        ; Background      : Green
        )
      , ( Name            : '32'
        ; Score           : 32
        ; PlacePercentage : 0
        ; Foreground      : DarkGray
        ; Background      : Red
        )
      , ( Name            : '64'
        ; Score           : 64
        ; PlacePercentage : 0
        ; Foreground      : LightGray
        ; Background      : Red
        )
      , ( Name            : '128'
        ; Score           : 128
        ; PlacePercentage : 0
        ; Foreground      : LightGray
        ; Background      : Magenta
        )
      , ( Name            : '256'
        ; Score           : 256
        ; PlacePercentage : 0
        ; Foreground      : LightCyan
        ; Background      : Magenta
        )
      , ( Name            : '512'
        ; Score           : 512
        ; PlacePercentage : 0
        ; Foreground      : Yellow
        ; Background      : Magenta
        )
      , ( Name            : '1024'
        ; Score           : 1024
        ; PlacePercentage : 0
        ; Foreground      : White
        ; Background      : Magenta
        )
      , ( Name            : '2048'
        ; Score           : 2048
        ; PlacePercentage : 0
        ; Foreground      : White
        ; Background      : Black
        )
      );

    { Grid width and height, in tiles.
      If you change these, change GridX and GridY too. }
    GridWidth  : GridX = 4;
    GridHeight : GridY = 4;


    {
    - Graphics
    }

    { Screen (border) colour. }
    ScreenBG : Byte = Blue;

    { Status bar colours. }
    StatusFG : Byte = Black;
    StatusBG : Byte = LightGray;

    { Grid position and size. These are purely visual. }
    GridStartX     : ScreenX = 21; { Centres with tilewidth 10, screen 80. }
    GridStartY     : ScreenY = 1;
    GridTileWidth  : ScreenX = 10;
    GridTileHeight : ScreenY = 6;

    { Offset co-ordinates for tile levels, measured from the top-left. }
    LabelOffsetX : ScreenX = 1;
    LabelOffsetY : ScreenY = 1;

    { Position of the status line.  This should not overlap the grid. }
    StatusY : ScreenY = 25;

    { Screen mode.  Change ScreenX and ScreenY if you change this. }
    ScreenMode : Byte = CO80;

{
- Global Variables
}

var
    State : GameState; { The current game state. }
    Grid  : GridM;     { The board representation. }
    Score : Integer;   { The game store. }

{
- Graphics Routines
}

{ Parks the cursor in an inoffensive location. }
procedure ParkCursor;
begin
    GotoXY(1, StatusY);
end;

{ Converts from a grid X co-ordinate to a screen X co-ordinate.
  Specifically, this returns the X co-ordinate of the LEFT of the grid tile. }
function ScreenXOfGridX(X: GridX) : ScreenX;
begin
    ScreenXOfGridX := GridStartX + ((X - 1) * GridTileWidth);
end;

{ Converts from a grid Y co-ordinate to a screen Y co-ordinate.
  Specifically, this returns the Y co-ordinate of the TOP of the grid tile. }
function ScreenYOfGridY(Y: GridY) : ScreenY;
begin
    ScreenYOfGridY := GridStartY + ((Y - 1) * GridTileHeight);
end;

{ Changes the current text colours to those of the given stage. }
procedure UseStageColour(S: Stage);
begin
    TextColor(Stages[S].Foreground);
    TextBackground(Stages[S].Background);
end;

{ Draw a tile's background at the given screen X and Y. }
procedure DrawTileBackground(LeftX: ScreenX; TopY: ScreenY);
var
    X: ScreenX;
    Y: ScreenY;

    IsVerticalEdge: Boolean;
    IsHorizontalEdge: Boolean;
begin
    for X := 1 to GridTileWidth do
    begin
        for Y := 1 to GridTileHeight do
        begin
            GotoXY(LeftX + (X - 1), TopY + (Y - 1));

            IsVerticalEdge   := X in [1, GridTileWidth];
            IsHorizontalEdge := Y in [1, GridTileHeight];

            if IsVerticalEdge and IsHorizontalEdge then Write('+')
            else if IsVerticalEdge then Write('-')
            else if IsHorizontalEdge then Write('-')
            else Write(' ')
        end;
    end;
    ParkCursor;
end;

{ Draw a label for a tile starting at the given screen X and Y. }
procedure DrawTileLabel(X: ScreenX; Y: ScreenY; S: Stage);
begin
    GotoXY(X + LabelOffsetX, Y + LabelOffsetY);
    Write(Stages[S].Name);
    ParkCursor;
end;

{ Draw a tile at position (X, Y) on the grid. }
procedure DrawTile(X: GridX; Y: GridY; S: Stage);
var
    SX: ScreenX;
    SY: ScreenY;
begin
    UseStageColour(S);

    SX := ScreenXOfGridX(X);
    SY := ScreenYOfGridY(Y);

    DrawTileBackground(SX, SY);
    DrawTileLabel(SX, SY, S);
end;

{ Draw the current grid. }
procedure DrawGrid;
var
    X: GridX;
    Y: GridY;
begin
    for X := 1 to GridWidth do
    begin
        for Y := 1 to GridHeight do DrawTile(X, Y, Grid[X, Y]);
    end;
end;

{ Changes to the status line colour scheme. }
procedure StatusColours;
begin
    TextColor(StatusFG);
    TextBackground(StatusBG);
end;

{ Draw a status line message. }
procedure StatusMessage(Message: String);
begin
    GotoXY(1, StatusY);
    StatusColours;
    ClrEOL;
    Write('Score: ', Score, '. ', Message);
    ParkCursor;
end;

{ Initialises the (lack of) graphics. }
procedure InitialiseGraphics;
begin
    TextMode(ScreenMode);
    TextBackground(ScreenBG);
    ClrScr;
    DrawGrid;
    ParkCursor;
end;

{
- Grid
}

{ Clear the grid. }
procedure ZeroGrid;
var
    X: GridX;
    Y: GridY;
begin
    for X := 1 to GridWidth do for Y:= 1 to GridHeight do Grid[X][Y] := 0;
end;

{ Place a tile on the grid with the given co-ordinates and stage. }
procedure PlaceTile(X: GridX; Y: GridY; S: Stage);
begin
    Grid[X, Y] := S;
    DrawTile(X, Y, S);
end;

{
- Score
}

{ Announces the score via the status line. }
procedure AnnounceScore;
begin
    StatusMessage('');
end;

{ Adds to the score. }
procedure AddScore(DScore: Integer);
begin
    Score := Score + DScore;
    AnnounceScore;
end;

{
- Tile movement
}

{ Checks to see if a move will place a tile out of bounds. }
function InBounds(X: GridX; Y: GridY; DX: Integer; DY: Integer) : Boolean;
var
    InXBounds : Boolean;
    InYBounds : Boolean;
begin
    InXBounds := (X + DX) in [1.. GridWidth];
    InYBounds := (Y + DY) in [1..GridHeight];
    InBounds  := InXBounds and InYBounds;
end;

{ Checks a possible tile move to see if it is valid. }
function CanMoveTile(X: GridX; Y: GridY; DX: Integer; DY: Integer) : Boolean;
begin
    CanMoveTile := False;
    if InBounds(X, Y, DX, DY) and (Grid[X, Y] <> 0) then
    begin
        CanMoveTile := Grid[X + DX, Y + DY] = 0;
    end;
end;

{ Checks a possible tile merge to see if it is valid. }
function CanMergeTile(X: GridX; Y: GridY; DX: Integer; DY: Integer) : Boolean;
begin
    CanMergeTile := False;
    if InBounds(X, Y, DX, DY) and (Grid[X, Y] <> 0) then
    begin
        CanMergeTile := Grid[X + DX, Y + DY] = Grid[X, Y];
    end;
end;

{ Moves the tile (X, Y) to an empty space DX rightwards and DY down.
  The move must have already been checked for validity. }
procedure MoveTile(X: GridX; Y: GridY; DX: Integer; DY: Integer);
begin
    PlaceTile(X + DX, Y + DY, Grid[X, Y]);
    PlaceTile(X     , Y     , 0         );
end;

{ Merges the tile (X, Y) with an identical tile DX rightwards and DY down.
  The move must have already been checked for validity.
  As this can cause the game to be won, we check for that here.
}
procedure MergeTile(X: GridX; Y: GridY; DX: Integer; DY: Integer);
var
    NewStage : Stage;
begin
    NewStage := Succ(Grid[X, Y]);

    { Was the game just won? }
    if NewStage = LastStage then State := Won;

    AddScore(Stages[NewStage].Score);

    PlaceTile(X + DX, Y + DY, NewStage);
    PlaceTile(X     , Y     , 0       );
end;

{ Moves the tile in the given direction until it can move no longer.
  Returns True if the tile is not empty and has moved successfully. }
function MoveAcross(X: GridX; Y: GridY; DX: Integer; DY: Integer) : Boolean;
var
    TX : Integer;
    TY : Integer;
begin
    TX := X;
    TY := Y;
    MoveAcross := False;

    while CanMoveTile(TX, TY, DX, DY) do
    begin
        MoveTile(TX, TY, DX, DY);
        TX := TX + DX;
        TY := TY + DY;
        MoveAcross := True;
    end;
    if CanMergeTile(TX, TY, DX, DY) then
    begin
        MergeTile(TX, TY, DX, DY);
        MoveAcross := True;
    end;
end;

{
- Grid movement
}

{ Moves the grid up and returns True if the move succeeded. }
function MoveUp : Boolean;
var
    X: GridX;
    Y: GridY;
begin
    MoveUp := False;

    for X := 1 to GridWidth do
    begin
        for Y := 2 to GridHeight do
        begin
            if MoveAcross(X, Y, 0, -1) then MoveUp := True;
        end;
    end;
end;

{ Moves the grid left and returns True if the move succeeded. }
function MoveLeft : Boolean;
var
    X: GridX;
    Y: GridY;
begin
    MoveLeft := False;

    for Y := 1 to GridHeight do
    begin
        for X := 2 to GridWidth do
        begin
            if MoveAcross(X, Y, -1, 0) then MoveLeft := True;
        end;
    end;
end;

{ Moves the grid right. }
function MoveRight : Boolean;
var
    X: GridX;
    Y: GridY;
begin
    MoveRight := False;

    for Y := 1 to GridHeight do
    begin
        for X := GridWidth - 1 downto 1 do
        begin
            if MoveAcross(X, Y, 1, 0) then MoveRight := True;
        end;
    end;
end;

{ Moves the grid down. }
function MoveDown : Boolean;
var
    X: GridX;
    Y: GridY;
begin
    MoveDown := False;

    for X := 1 to GridWidth do
    begin
        for Y := GridHeight - 1 downto 1 do
        begin
            if MoveAcross(X, Y, 0, 1) then MoveDown := True;
        end;
    end;
end;

{
- Game state checking and manipulation
}

{ Returns True if the game is over. }
function GameOver : Boolean;
begin
    GameOver := State <> InProgress;
end;

{ Checks to see if any moves are possible on the board. }
function OutOfMoves : Boolean;
var
    X: GridX;
    Y: GridY;
begin
    OutOfMoves := True;

    for X := 1 to GridWidth do
    begin
        for Y := 1 to GridHeight do
        begin
            if CanMergeTile(X, Y, 1, 0) then OutOfMoves := False;
            if CanMergeTile(X, Y, 0, 1) then OutOfMoves := False;
            if Grid[X, Y] = 0 then OutOfMoves := False;
        end;
    end;
end;

{ Checks to see if the game has been lost.
  If it is, the game state is changed accordingly. }
procedure CheckGameLost;
begin
    if OutOfMoves then State := Lost;
end;

{
- Random tile placement
}
{ Place a random tile with the given stage. }
procedure PlaceRandom(S: Stage);
var
    X: GridX;
    Y: GridY;
    Placed: Boolean;
begin
    Placed := False;

    while (Placed = False) do
    begin
        X := Random(GridWidth) + 1;
        Y := Random(GridHeight) + 1;
        if (Grid[X, Y] = 0) then
        begin
            Placed := True;
            PlaceTile(X, Y, S);
        end;
    end;
end;

{ Choose a weighted random tile stage. }
function RandomStage: Stage;
var
    RandomPercent : Percentage;
    Cumulative    : Percentage;
    ChosenStage   : Stage;
begin
    Cumulative    := 0;
    ChosenStage   := 0;
    RandomPercent := Random(100) + 1;

    while (Cumulative < RandomPercent) do
    begin
        Cumulative  := Cumulative + Stages[ChosenStage].PlacePercentage;
        ChosenStage := ChosenStage + 1;
    end;

    RandomStage := ChosenStage - 1;
end;

{ Introduces a new tile into the game.
  As this may cause the game to be lost, we check for that here too. }
procedure AddRandomTile;
begin
    PlaceRandom(RandomStage);
    CheckGameLost;
end;

{ Adds the initial set of tiles. }
procedure AddInitialTiles;
var
    I: Integer;
begin
    for I := 1 to NumInitialTiles do AddRandomTile;
end;

{
- Main logic
}

{ Handles a keypress. }
function HandleKey(Key: Char) : Boolean;
var
    Moved : Boolean;
begin
    Moved := False;

    case Ord(Key) of
        { Enter, q: exit game. }
        113, 27: State := Quit;

        { Arrow keys: move tiles. }
        72: Moved := MoveUp;
        75: Moved := MoveLeft;
        77: Moved := MoveRight;
        80: Moved := MoveDown;
    end;

    HandleKey := Moved and not GameOver
end;

{ A step of the main loop. }
procedure LoopStep;
var
    Stepped : Boolean;
begin
    Stepped := HandleKey(ReadKey);
    if Stepped then AddRandomTile;
end;

{ The main game loop. }
procedure Loop;
begin
    repeat LoopStep until GameOver;
end;

{ Initialises the game state. }
procedure Initialise;
begin
    Randomize;

    Score := 0;
    State := InProgress;

    ZeroGrid;

    InitialiseGraphics;
    StatusMessage('This is a fake/derivative and not the original 2048.');

    AddInitialTiles;
end;

{ Displays a game over message and waits to end the game. }
procedure PostGame;
var
    Key: Char;
begin
    case State of
        Lost : StatusMessage('Game over!');
        Won  : StatusMessage('Congraturation! You have played a good game.');
        Quit : StatusMessage('Enjoy DOS!');
    end;
    Key := ReadKey;
end;

{ And now, the main procedure. }
begin
    Initialise;
    Loop;
    PostGame;
end.
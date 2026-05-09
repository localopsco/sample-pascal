program Worker;
{$MODE TP}
{ Long-running worker: on each tick, generates a batch of synthetic items
  and prints a formatted report. Sleeps INTERVAL_SECONDS between ticks
  and runs until killed (SIGTERM / Ctrl-C). }

uses
  SysUtils;

const
  AppName    = 'Worker';
  AppVersion = '1.0';
  MaxItems   = 64;

type
  TLogLevel = (llDebug, llInfo, llWarn, llError);

  TItem = record
    Name  : string[32];
    Value : LongInt;
  end;

function EnvOrDefault(const Key, Default: string): string;
var V: string;
begin
  V := GetEnvironmentVariable(Key);
  if V = '' then EnvOrDefault := Default
  else EnvOrDefault := V;
end;

function ToInt(const S: string; Default: LongInt): LongInt;
var Code: Integer; N: LongInt;
begin
  Val(S, N, Code);
  if Code <> 0 then ToInt := Default else ToInt := N;
end;

function ParseLevel(const S: string): TLogLevel;
var U: string;
begin
  U := UpperCase(S);
  if U = 'DEBUG' then ParseLevel := llDebug
  else if U = 'WARN'  then ParseLevel := llWarn
  else if U = 'ERROR' then ParseLevel := llError
  else ParseLevel := llInfo;
end;

function LevelLabel(L: TLogLevel): string;
begin
  case L of
    llDebug: LevelLabel := 'DEBUG';
    llInfo:  LevelLabel := 'INFO ';
    llWarn:  LevelLabel := 'WARN ';
    llError: LevelLabel := 'ERROR';
  end;
end;

function Repeats(Ch: Char; N: Integer): string;
var S: string; I: Integer;
begin
  S := '';
  for I := 1 to N do S := S + Ch;
  Repeats := S;
end;

function Stamp: string;
begin
  Stamp := FormatDateTime('yyyy-mm-dd hh:nn:ss', Now);
end;

procedure PrintBanner;
begin
  writeln(Repeats('=', 56));
  writeln(' ', AppName, ' v', AppVersion);
  writeln(' Compiler : FPC ', {$I %FPCVERSION%});
  writeln(' Target   : ', {$I %FPCTARGETOS%}, '/', {$I %FPCTARGETCPU%});
  writeln(' Built    : ', {$I %DATE%}, ' ', {$I %TIME%});
  writeln(Repeats('=', 56));
end;

procedure RunTick(Tick: LongInt;
                  const Title, Greeting: string;
                  Level: TLogLevel;
                  Count: Integer);
var
  Items: array[1..MaxItems] of TItem;
  I, MaxIdx: Integer;
  Sum: LongInt;
begin
  for I := 1 to Count do
  begin
    Items[I].Name  := 'metric_' + IntToStr(I);
    Items[I].Value := (Tick * 7 + I * I) * 10;
  end;

  Sum := 0;
  MaxIdx := 1;
  for I := 1 to Count do
  begin
    Sum := Sum + Items[I].Value;
    if Items[I].Value > Items[MaxIdx].Value then MaxIdx := I;
  end;

  writeln;
  writeln('[', LevelLabel(Level), '] ', Stamp, ' tick=', Tick, ' :: ', Title);
  writeln(Greeting);
  writeln(Repeats('-', 56));
  for I := 1 to Count do
    writeln('  ', I:2, '. ', Items[I].Name:-20, ' = ', Items[I].Value:8);
  writeln(Repeats('-', 56));
  writeln('  Items : ', Count);
  writeln('  Sum   : ', Sum);
  writeln('  Max   : ', Items[MaxIdx].Name, ' (', Items[MaxIdx].Value, ')');
  Flush(Output);
end;

var
  Title, Greeting: string;
  Level: TLogLevel;
  Count: Integer;
  Interval, Tick: LongInt;

begin
  PrintBanner;

  Title    := EnvOrDefault('REPORT_TITLE', 'Daily Run Summary');
  Greeting := EnvOrDefault('GREETING', 'Hello, World!');
  Level    := ParseLevel(EnvOrDefault('LOG_LEVEL', 'INFO'));
  Count    := ToInt(EnvOrDefault('ITEM_COUNT', '5'), 5);
  Interval := ToInt(EnvOrDefault('INTERVAL_SECONDS', '5'), 5);

  if Count < 1 then Count := 1;
  if Count > MaxItems then Count := MaxItems;
  if Interval < 1 then Interval := 1;

  writeln('Starting worker loop: every ', Interval, 's, ', Count, ' item(s) per tick.');
  writeln('Press Ctrl-C to stop.');

  Tick := 0;
  while True do
  begin
    Inc(Tick);
    RunTick(Tick, Title, Greeting, Level, Count);
    Sleep(Interval * 1000);
  end;
end.

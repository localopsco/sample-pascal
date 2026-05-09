program HelloReport;
{$MODE TP}
{ Classic Turbo Pascal style sample - demonstrates that programs written
  in this idiom 20+ years ago still compile and run unchanged today.
  Reads configuration from environment variables and prints a report. }

uses
  SysUtils;

const
  AppName    = 'HelloReport';
  AppVersion = '1.0';
  MaxItems   = 16;

type
  TLogLevel = (llDebug, llInfo, llWarn, llError);

  TItem = record
    Name  : string[32];
    Value : LongInt;
  end;

  TReport = record
    Title    : string[64];
    Greeting : string[64];
    Level    : TLogLevel;
    Items    : array[1..MaxItems] of TItem;
    Count    : Integer;
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

procedure AddItem(var R: TReport; const Name: string; Value: LongInt);
begin
  if R.Count >= MaxItems then Exit;
  Inc(R.Count);
  R.Items[R.Count].Name  := Name;
  R.Items[R.Count].Value := Value;
end;

function SumItems(const R: TReport): LongInt;
var I: Integer; S: LongInt;
begin
  S := 0;
  for I := 1 to R.Count do S := S + R.Items[I].Value;
  SumItems := S;
end;

function MaxItem(const R: TReport): Integer;
var I, Idx: Integer;
begin
  Idx := 1;
  for I := 2 to R.Count do
    if R.Items[I].Value > R.Items[Idx].Value then Idx := I;
  MaxItem := Idx;
end;

function Repeats(Ch: Char; N: Integer): string;
var S: string; I: Integer;
begin
  S := '';
  for I := 1 to N do S := S + Ch;
  Repeats := S;
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

procedure PrintReport(const R: TReport);
var I, Top: Integer;
begin
  writeln;
  writeln('[', LevelLabel(R.Level), '] ', R.Title);
  writeln(R.Greeting);
  writeln(Repeats('-', 56));
  if R.Count = 0 then
    writeln('  (no items)')
  else
  begin
    for I := 1 to R.Count do
      writeln('  ', I:2, '. ', R.Items[I].Name:-20, ' = ', R.Items[I].Value:8);
    Top := MaxItem(R);
    writeln(Repeats('-', 56));
    writeln('  Items : ', R.Count);
    writeln('  Sum   : ', SumItems(R));
    writeln('  Max   : ', R.Items[Top].Name, ' (', R.Items[Top].Value, ')');
  end;
  writeln;
end;

var
  Report: TReport;
  Iter, I: LongInt;

begin
  PrintBanner;

  FillChar(Report, SizeOf(Report), 0);
  Report.Title    := EnvOrDefault('REPORT_TITLE', 'Daily Run Summary');
  Report.Greeting := EnvOrDefault('GREETING', 'Hello, World!');
  Report.Level    := ParseLevel(EnvOrDefault('LOG_LEVEL', 'INFO'));

  Iter := ToInt(EnvOrDefault('ITEM_COUNT', '5'), 5);
  if Iter < 1 then Iter := 1;
  if Iter > MaxItems then Iter := MaxItems;

  for I := 1 to Iter do
    AddItem(Report, 'metric_' + IntToStr(I), I * I * 10);

  PrintReport(Report);

  if ParamCount > 0 then
  begin
    write('Args:');
    for I := 1 to ParamCount do write(' ', ParamStr(I));
    writeln;
  end;

  writeln('Done.');
end.

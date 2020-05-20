{
*****************************************************************************
*                                                                           *
*  This file is part of the ZCAD                                            *
*                                                                           *
*  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
*  for details about the copyright.                                         *
*                                                                           *
*  This program is distributed in the hope that it will be useful,          *
*  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
*                                                                           *
*****************************************************************************
}
{
@author(Andrey Zubarev <zamtmn@yandex.ru>) 
} 
unit uzeparser;
{$INCLUDE def.inc}

interface
uses sysutils,uzbtypesbase,gzctnrstl,LazLogger,gutil;
const MaxCashedValues=4;
      MaxIncludedChars=2;
type
  TStrProcessFunc=function(const str:gdbstring;const operands:gdbstring;var startpos:integer;pobj:pointer):gdbstring;
  TStrProcessorData=record
    Id:gdbstring;
    OBracket,CBracket:char;
    IsVariable:Boolean;
    Func:TStrProcessFunc;
  end;

  TTokenizer=class;
  TTokenId=integer;
  TTokenizerSymbol=char;
  TChars=set of TTokenizerSymbol;
  TIncludedChars=array [1..MaxIncludedChars+1] of TChars;
  TTokenizerString=gdbstring;
  TTokenOption=(TOIncludeBrackeOpen,TOVariable,TOFake);
  TTokenOptions=set of TTokenOption;
  TTokenData=record
    Token:string;
    BrackeOpen,BrackeClose:char;
    Options:TTokenOptions;
    Func:TStrProcessFunc;
  end;
  TTokenizerSymbolData=record
    NextSymbol:TTokenizer;
    TokenId:TTokenId;
  end;
  TTokenTextInfo=record
    TokenId:TTokenId;
    TokenStartPos,TokenLength,OperandsStartPos,OperandsLength:integer;
  end;

  LessTTokenizerSymbol=TLess<TTokenizerSymbol>;
  TTokenizer=class(GKey2DataMap<TTokenizerSymbol,TTokenizerSymbolData,LessTTokenizerSymbol>)
  type
    TCashedData=record
      Symbol:TTokenizerSymbol;
      SymbolData:TTokenizerSymbolData
    end;
    TCashe=array [1..maxcashedvalues] of TCashedData;
    public
  var
    Cashe:TCashe;
    isOnlyOneToken:TTokenizerString;
    isOnlyOneTokenId:TTokenId;
    includedChars:TChars;
    constructor create;
    procedure SubRegisterToken(Token:TTokenizerString;var sym:integer;_TokenId:TTokenId;var IncludedCharsPos:TIncludedChars);
    procedure Sub2RegisterToken(Token:TTokenizerString;var sym:integer;_TokenId:TTokenId;var IncludedCharsPos:TIncludedChars);

    function SubGetToken(Text:TTokenizerString;CurrentPos:integer;out TokenTextInfo:TTokenTextInfo;level:integer;var IncludedCharsPos:TIncludedChars;var AllChars:TChars):TTokenId;
    function Sub2GetToken(Text:TTokenizerString;CurrentPos:integer;out TokenTextInfo:TTokenTextInfo;level:integer):TTokenId;
    function GetToken(Text:TTokenizerString;CurrentPos:integer;out TokenTextInfo:TTokenTextInfo;var IncludedCharsPos:TIncludedChars;var AllChars:TChars):TTokenId;

    function GetSymbolData(const Text:TTokenizerString;const CurrentPos:integer;out PTokenizerSymbolData:TTokenizer.PTValue):boolean;inline;
  end;
  TTokenDataVector=TMyVector<TTokenData>;

  TParser=class
    public
    IncludedCharsPos:TIncludedChars;
    AllChars:TChars;
    Tokenizer:TTokenizer;
    TokenDataVector:TTokenDataVector;
    tkEmpty,tkRawText,tkEOF:TTokenId;
    StoredTokenTextInfo:TTokenTextInfo;
    constructor create;
    procedure clearStoredToken;
    function RegisterToken(const Token:string;const BrackeOpen,BrackeClose:char;const Func:TStrProcessFunc;Options:TTokenOptions=[]):TTokenId;
    procedure OptimizeTokens;
    function GetToken(Text:TTokenizerString;CurrentPos:integer;out TokenTextInfo:TTokenTextInfo):TTokenId;

  end;

implementation

function TTokenizer.GetToken(Text:TTokenizerString;CurrentPos:integer;out TokenTextInfo:TTokenTextInfo;var IncludedCharsPos:TIncludedChars;var AllChars:TChars):TTokenId;
begin
  //inc(debTokenizerGetToken);
  TokenTextInfo.TokenStartPos:=CurrentPos;
  result:=SubGetToken(Text,CurrentPos,TokenTextInfo,1,IncludedCharsPos,AllChars);
end;

function TTokenizer.SubGetToken(Text:TTokenizerString;CurrentPos:integer;out TokenTextInfo:TTokenTextInfo;level:integer;var IncludedCharsPos:TIncludedChars;var AllChars:TChars):TTokenId;
var
  PTokenizerSymbolData:TTokenizer.PTValue;
  i,step:integer;
begin
  //inc(debTokenizerSubGetToken);

  if isOnlyOneToken<>'' then begin
  while CurrentPos<=length(Text) do begin
    //inc(debCompareByte);
    if {comparesubstr(Text,isOnlyOneToken,CurrentPos,level)}CompareByte(Text[CurrentPos],isOnlyOneToken[level],length(isOnlyOneToken)-level+1)=0 then begin
      result:=isOnlyOneTokenId;
      TokenTextInfo.TokenId:=result;
      TokenTextInfo.TokenLength:=length(isOnlyOneToken);
      exit;
    end;


    inc(CurrentPos);
    TokenTextInfo.TokenStartPos:=CurrentPos;
  end;
  end else begin

  while CurrentPos<=length(Text) do begin
    //maxlevel:=1;
    if {UpCase}(Text[CurrentPos]) in includedChars then begin
      GetSymbolData(Text,CurrentPos,PTokenizerSymbolData);
      if PTokenizerSymbolData^.TokenId<>0 then begin
        result:=PTokenizerSymbolData^.TokenId;
        TokenTextInfo.TokenId:=result;
        TokenTextInfo.TokenLength:=CurrentPos-TokenTextInfo.TokenStartPos+1;
        exit;
      end
      else begin
        result:=PTokenizerSymbolData^.NextSymbol.Sub2GetToken(Text,CurrentPos+1,TokenTextInfo,level+1);
        if result<>0  then exit;
      end;
    end;
    step:=1;
    for i:=1 to MaxIncludedChars do
     if (Text[CurrentPos+i] in IncludedCharsPos[i]) then begin
       step:=i;
       break;
     end;
     for i:=step to length(Text)-CurrentPos do
      if Text[CurrentPos+i] in AllChars then
        break
      else
        inc(step);
    inc(CurrentPos,step);
    TokenTextInfo.TokenStartPos:=CurrentPos;
  end;
  end;
  result:=1;
  TokenTextInfo.TokenId:=result;
  TokenTextInfo.TokenStartPos:=length(Text)+1;
  TokenTextInfo.TokenLength:=0;
end;

function TTokenizer.GetSymbolData(const Text:TTokenizerString;const CurrentPos:integer;out PTokenizerSymbolData:TTokenizer.PTValue):boolean;
var i:integer;
begin
  if size<=MaxCashedValues then begin
    for i:=1 to MaxCashedValues do   begin
      if cashe[i].Symbol=Text[CurrentPos] then begin
        PTokenizerSymbolData:=@cashe[i].SymbolData;
        exit(true);
      end;
    end;
      PTokenizerSymbolData:=nil;
      exit(false);
  end else
    result:=MyGetMutableValue({UpCase}(Text[CurrentPos]),PTokenizerSymbolData);
end;

function TTokenizer.Sub2GetToken(Text:TTokenizerString;CurrentPos:integer;out TokenTextInfo:TTokenTextInfo;level:integer):TTokenId;
var
  PTokenizerSymbolData:TTokenizer.PTValue;
begin
  //inc(debTokenizerSub2GetToken);
  //maxlevel:=level;
  if isOnlyOneToken<>'' then begin
    //inc(debCompareByte);
    if {comparesubstr(Text,isOnlyOneToken,CurrentPos,level)}CompareByte(Text[CurrentPos],isOnlyOneToken[level],length(isOnlyOneToken)-level+1)=0 then begin
      result:=isOnlyOneTokenId;
      TokenTextInfo.TokenId:=result;
      TokenTextInfo.TokenLength:=length(isOnlyOneToken);
      exit;
    end else
      result:=0;
  end else begin
    if {UpCase}(Text[CurrentPos]) in includedChars then begin
      GetSymbolData(Text,CurrentPos,PTokenizerSymbolData);
      {if (PTokenizerSymbolData^.NextSymbol=nil)and(PTokenizerSymbolData^.TokenId=0) then
       includedChars:=includedChars;}
      if PTokenizerSymbolData^.TokenId<>0 then begin
        result:=PTokenizerSymbolData^.TokenId;
        TokenTextInfo.TokenId:=result;
        TokenTextInfo.TokenLength:=CurrentPos-TokenTextInfo.TokenStartPos+1;
        exit;
      end
      else begin
        if PTokenizerSymbolData^.NextSymbol=nil then
         includedChars:=includedChars;
        exit(PTokenizerSymbolData^.NextSymbol.Sub2GetToken(Text,CurrentPos+1,TokenTextInfo,level+1));
      end;
    end;
    result:=0;
  end;
end;


function TParser.GetToken(Text:TTokenizerString;CurrentPos:integer;out TokenTextInfo:TTokenTextInfo):TTokenId;
var
  PTokenizerSymbolData:TTokenizer.PTValue;
  startpos:integer;
begin
  //inc(debParserGetTonenCount);
  if StoredTokenTextInfo.TokenId<>tkEmpty then begin
    if StoredTokenTextInfo.TokenStartPos=CurrentPos then begin
      TokenTextInfo:=StoredTokenTextInfo;
      clearStoredToken;
      exit(TokenTextInfo.TokenId);
    end else begin
      clearStoredToken;
    end;
  end;
  startpos:=CurrentPos;
  result:=Tokenizer.GetToken(Text,CurrentPos,TokenTextInfo,IncludedCharsPos,AllChars);
  //if result<>tkEOF then
   if startpos<>TokenTextInfo.TokenStartPos then begin
     StoredTokenTextInfo:=TokenTextInfo;
     TokenTextInfo.TokenId:=tkRawText;
     TokenTextInfo.TokenStartPos:=startpos;
     TokenTextInfo.TokenLength:=StoredTokenTextInfo.TokenStartPos-startpos;
     exit(TokenTextInfo.TokenId);
   end;
end;

constructor TParser.create;
var
  i:integer;
begin
 for i:=1 to MaxIncludedChars do
  IncludedCharsPos[i]:=[];
 Tokenizer:=TTokenizer.create;
 TokenDataVector:=TTokenDataVector.create;

 clearStoredToken;

 tkEmpty:=RegisterToken('Empty',#0,#0,nil,[TOFake]);
 tkEOF:=RegisterToken('EOF',#0,#0,nil,[TOFake]);
 tkRawText:=RegisterToken('RawText',#0,#0,nil,[TOFake]);
end;

procedure TParser.clearStoredToken;
begin
  StoredTokenTextInfo.TokenId:=tkEmpty;
  StoredTokenTextInfo.TokenStartPos:=0;
end;

function TParser.RegisterToken(const Token:string;const BrackeOpen,BrackeClose:char;const Func:TStrProcessFunc;Options:TTokenOptions=[]):TTokenId;
var
  sym:integer;
  td:TTokenData;
begin

  result:=TokenDataVector.Size;
  td.Token:=Token;
  td.BrackeClose:=BrackeOpen;
  td.BrackeOpen:=BrackeClose;
  td.Options:=Options;
  td.Func:=Func;

  TokenDataVector.PushBack(td);

  if not(TOFake in Options) then begin
    sym:=1;
    Tokenizer.SubRegisterToken({uppercase}(Token),sym,result,IncludedCharsPos);
  end;

end;

procedure TParser.OptimizeTokens;
var
  i:integer;
begin
  for i:=1 to MaxIncludedChars-1 do
    IncludedCharsPos[i+1]:=IncludedCharsPos[i]+IncludedCharsPos[i+1];
  AllChars:=IncludedCharsPos[1];
  for i:=2 to MaxIncludedChars do
    AllChars:=AllChars+IncludedCharsPos[i];
end;

constructor TTokenizer.create;
begin
  inherited;
  includedChars:=[];
  isOnlyOneToken:='';
  isOnlyOneTokenId:=0;
end;

procedure TTokenizer.SubRegisterToken(Token:TTokenizerString;var sym:integer;_TokenId:TTokenId;var IncludedCharsPos:TIncludedChars);
var
  PTokenizerSymbolData:TTokenizer.PTValue;
  data:TTokenizerSymbolData;
  tmpsym:integer;
begin
  if IsEmpty and (isOnlyOneToken='') then begin
    isOnlyOneToken:=Token;
    isOnlyOneTokenId:=_TokenId;
  end else begin
    if isOnlyOneToken<>'' then begin
      tmpsym:=sym;
      Sub2RegisterToken(isOnlyOneToken,tmpsym,isOnlyOneTokenId,IncludedCharsPos);
      isOnlyOneToken:='';
    end;
    Sub2RegisterToken(Token,sym,_TokenId,IncludedCharsPos);
  end;
end;

procedure TTokenizer.Sub2RegisterToken(Token:TTokenizerString;var sym:integer;_TokenId:TTokenId;var IncludedCharsPos:TIncludedChars);
var
  PTokenizerSymbolData:TTokenizer.PTValue;
  data:TTokenizerSymbolData;
  i:integer;
begin
  if MyGetMutableValue(Token[sym],PTokenizerSymbolData)then begin
    if sym<length(Token) then begin
      if not assigned(PTokenizerSymbolData^.NextSymbol) then
        PTokenizerSymbolData^.NextSymbol:=TTokenizer.Create;
      inc(sym);
      PTokenizerSymbolData^.NextSymbol.SubRegisterToken(Token,sym,_TokenId,IncludedCharsPos);
      dec(sym);
    end else begin
      PTokenizerSymbolData^.TokenId:=_TokenId;
    end;
  end else begin
    if sym<length(Token) then
      begin
        data.TokenId:=0;
        data.NextSymbol:=TTokenizer.Create;
        inc(sym);
        data.NextSymbol.SubRegisterToken(Token,sym,_TokenId,IncludedCharsPos);
        dec(sym);
      end
    else
      begin
        data.TokenId:=_TokenId;
        data.NextSymbol:=nil;
      end;
    Insert(Token[sym],data);
    includedChars:=includedChars+[Token[sym]];
    if sym<=MaxIncludedChars then begin
      IncludedCharsPos[sym]:=IncludedCharsPos[sym]+[Token[sym]];
    end;
    if size<=MaxCashedValues then begin
      cashe[size].Symbol:=Token[sym];
      cashe[size].SymbolData:=data;
    end;
  end;
end;

initialization
  debugln('{I}[UnitsInitialization] Unit "',{$INCLUDE %FILE%},'" initialization');
finalization
  debugln('{I}[UnitsFinalization] Unit "',{$INCLUDE %FILE%},'" finalization');
end.

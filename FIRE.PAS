{
 Copyleft @ Sascha Peilicke 2002.

 Dieser Code ist Freeware, jeder kann also damit machen
 was er will, solange dieser Disclaimer erhalten bleibt!

 Dies ist ein Grafikproggy, das den Graphikmodus 13h
 ausnutzt und somit ohne die langsame und beschissene
 GRAPH.TPU auskommt.

 Kritik und VorschlÑge an : seidbreit@hotmail.com
}
PROGRAM hex13;
USES crt;
CONST anzp=1175;    {anzahl der punkte / bobs ( MAX 1175)}
      factor=0.1;
      offx=159;
      offy=99;
VAR screen:pointer;q:integer;
    bExit,bChange,bStop,bPaint,bBounce:boolean;
    kxg,kyg,kx,ky:real;

    ax:array[1..anzp] of real;{x-cord}
    ay:array[1..anzp] of real;{y-cord}
    axv:array[1..anzp] of real;{x-achse geschw}
    ayv:array[1..anzp] of real;{y-achse geschw}
    axg:array[1..anzp] of real;{x-achse gravitation}
    ayg:array[1..anzp] of real;{y-achse grav}
    al:array[1..anzp] of real; {leben}
    ad:array[1..anzp] of real; {fade = "life drain"}
    af1:array[1..anzp] of byte; {farbe}
    af2:array[1..anzp] of real; {tmp farbe}

PROCEDURE clearscreen(screen:pointer); var j:word;
begin
  for j:=0 to 63999 do mem[seg(screen^):ofs(screen^)+j]:=0;
end;

PROCEDURE pre;
begin
  textcolor(4);writeln;writeln;writeln;writeln;
  writeln('          PARTICLE ENGINE');writeln;writeln;writeln;
  textcolor(2);
  writeln('Autor : Sascha Peilicke');writeln;writeln;
  writeln('Tastenbelegung:   +,-   : Gravitation Y-Achse');
  writeln('                  9,7   : Gravitation X-Achse');
  writeln('                  0     : Farbpalette wechseln');
  writeln('                  5     : Programm beenden');
  writeln('                  Space : Bildschirm lîschen');
  writeln('                  y     : Blank Screen an / aus');
  writeln('                  x     : Pause an / aus');
  writeln('                  c     : Punktgrî·e Ñndern');
  writeln('                  v     : Abprallen an / aus');
  writeln('                  b     : Neustart');
  writeln;writeln;writeln;
  writeln('Taste drÅcken...');
  readkey;
end;

procedure pal(rw,gw,bw:word);{ palette etwas Ñndern }
var r:array[0..255]of byte; g:array[0..255]of byte; b:array[0..255]of byte;
    i:integer;
begin
  for i:=0 to 255 do
  begin
     r[i]:=0; g[i]:=0; b[i]:=0;
  end;
  for i:=0 to 255 do
  begin
     if rw=1 then r[i]:=i
     else r[i]:=0;
     if gw=1 then g[i]:=i
     else g[i]:=0;
     if bw=1 then b[i]:=i
     else b[i]:=0;
  end;

  for i:=0 to 255 do
  begin
     Port[$3C8] := i;
     Port[$3C9] := r[i];
     Port[$3C9] := g[i];
     Port[$3C9] := b[i];
  end;
end;

procedure std(i:integer);
var x:integer;
begin
  ax[i]:=random(319);
  ay[i]:=random(199);
  af2[i]:=random(53)+10;
  al[i]:=100;
  ad[i]:=random(20)/20+0.04;
  case random(2) of
       0 : x:=1;
       1 : x:=-1;
  end;
  repeat
    axv[i]:=x*((random(1000)/1000*kx)+0.001);
  until axv[i] <> 0;
  ayv[i]:=-1*(random(1000)/1000*ky)+0.001;
  ayg[i]:=3.2;
  axg[i]:=0;
end;

PROCEDURE init;
var i:integer;
begin
  for i:=1 to anzp do std(i);
  kx:=1.2; ky:=1.1; kyg:=0.05; kxg:=0;
end;

PROCEDURE key;
var ch:char;
BEGIN
    while keypressed do
    begin
      ch:=readkey;
      case ch of
        'y': bChange := not bChange; {partikelspuren an/aus}
        'x': bStop := not bStop;     {pause an / aus}
        'c': bPaint := not bPaint;   {dicke bobs malen an/aus}
        'v': bBounce := not bBounce;
        '0': begin                   {palette Ñndern}
               case q of
                 0: pal(1,0,0);
                 1: pal(0,1,0);
                 2: pal(0,0,1);
                 3: pal(1,1,0);
                 4: pal(1,0,1);
                 5: pal(0,1,1);
                 6: pal(1,1,1);
               end;
               inc(q);
               if q>6 then q:=0;
             end;
        '5': bExit:=true;       {Programm verlassen}
        '-': begin
               kyg:=kyg-0.001;    {gravitation}
               if kyg<-20 then kyg:=-20;
             end;
        '+': begin
               kyg:=kyg+0.001;    {gravitation}
               if kyg>7 then kyg:=7;
             end;
        '7': begin
               kxg:=kxg-0.001;  {gravi auf x-achse}
               if kxg<-12 then kxg:=-12;
             end;
        '9': begin
               kxg:=kxg+0.001;  {gravi auf x-achse}
               if kxg>12 then kxg:=12;
             end;
        ' ': clearscreen(screen);
        'b' : init;
      end;
    end;
END;

procedure slowdown(wert:word); {zeitverschwenderfunktion}
var i,j:word;x:longint;
begin
     for i:=0 to wert do
       for j:=0 to wert do
         x:=x+wert;
end;

PROCEDURE bob(wx,wy:word;color:byte);
var segm,offs:word;
BEGIN
  segm:=seg(screen^);offs:=ofs(screen^);
  {einen Bob (fetter punkt) malen...}
  mem[segm:offs + 320*trunc(wy)   + trunc(wx)]  :=color;
  if bPaint then
  begin
    mem[segm:offs + 320*trunc(wy-1) + trunc(wx)]  :=color-4;
    mem[segm:offs + 320*trunc(wy)   + trunc(wx-1)]:=color-4;{}
    mem[segm:offs + 320*trunc(wy)   + trunc(wx+1)]:=color-4;
    mem[segm:offs + 320*trunc(wy+1) + trunc(wx)]  :=color-4; {}
    mem[segm:offs + 320*trunc(wy+1) + trunc(wx+1)]:=color-7;
    mem[segm:offs + 320*trunc(wy+1) + trunc(wx-1)]:=color-7;
    mem[segm:offs + 320*trunc(wy-1) + trunc(wx+1)]:=color-7;
    mem[segm:offs + 320*trunc(wy-1) + trunc(wx-1)]:=color-7;{}
    mem[segm:offs + 320*trunc(wy+2) + trunc(wx)]:=color-9;
    mem[segm:offs + 320*trunc(wy) + trunc(wx+2)]:=color-9;
    mem[segm:offs + 320*trunc(wy-2) + trunc(wx)]:=color-9;
    mem[segm:offs + 320*trunc(wy) + trunc(wx-2)]:=color-9;{}
  end;
  {end Bob malen}
END;

PROCEDURE paint;
var segm,offs,wx,wy:integer; i,j:integer;
begin
  segm:=seg(screen^); offs:=ofs(screen^);
  for i:=1 to anzp do
  begin
    ax[i]:=ax[i]+axv[i]-axg[i]{ Koordinate X berechnen};
    ay[i]:=ay[i]+ayv[i]-ayg[i]{ Koordinate Y berechnen};

    al[i]:=al[i]-ad[i]; {partikel verliert leben}
    ayg[i]:=ayg[i]-kyg; {}
    axg[i]:=axg[i]-kxg; {}

    af2[i]:=af2[i]-0.333;         {partikel verliert farbe}
    af1[i]:=trunc(af2[i]);        {bildschirmfarbe einstellen}
    if(af1[i]<10) then al[i]:=0;  {bei der farbe ausblenden}
    if al[i]<=0 then std(i); {ist der partikel tot, neu initialisieren}

    wx:=trunc(ax[i]);
    wy:=trunc(ay[i]);

    if(wy<=0) then begin
                     wy:=199; wx:=159;
                   end;
    if(wy>199)then begin
                     wy:=199; wx:=159;
                   end;
    if bBounce then
    begin
      if(wx<=0) then wx:=-wx;
      if(wx>319)then wx:=319-wx;
    end
    else
    begin
      if(wx<0)  then begin
                       wy:=199; wx:=159;
                     end;

      if(wx>319)then begin
                       wy:=199; wx:=159;
                     end;
    end;
    bob(wx,wy,af1[i]);
  end;
  move(mem[segm:offs],mem[$A000:0000],64000); {ab in speicher}
end;

BEGIN{HAUPTPROGGY}
  randomize;            {zufallsgenerator anschmeissen}
  pre;                  {erst ma anleitung ausspucken}
  asm mov ax,0013h
      int 10h end;
  getmem(screen,64000); {speicher fÅr vscreen}
  clearscreen(screen);
  pal(1,1,1);           {standardpalette initialisieren}
  init;                 {partikel initialisieren}
  WHILE NOT bExit DO {HAUPTSCHLEIFE}
  BEGIN
    if not bStop then paint;{}
    if not bChange then clearscreen(screen);{}
    slowdown(400);{}
    key;{}
  END; {ENDE HAUPTSCHLEIFE}
  asm mov ax,00003h
      int 10h end;
  freemem(screen,64000); {speicher freigeben}
END.

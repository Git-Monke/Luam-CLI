do local a=package.searchers or package.loaders;local b=a[2]a[2]=function(c)local d={["base64.lib"]=function()local e="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"local f={}local g={}for h=1,#e do local i=e:sub(h,h)f[h]=i;g[i]=h-1 end;local j,k,l=bit.blshift,bit.blogic_rshift,bit.band;local function m(n,o,p)assert(n,"At least one input byte required")local q=not o and 1 or not p and 2 or 3;o=o or 0;p=p or 0;local r=j(n,16)+j(o,8)+p;local s=""for h=3,3-q,-1 do s=s..f[1+tonumber(l(k(r,h*6),0x3f))]end;s=s..string.rep("=",3-q)return s end;local function u(v)assert(#v==4,"Chars must be of length 4")local w=#v:gsub("[^=]","")local x=v:gsub("=","A")local y=0;local s={}for h=1,4 do y=y+j(g[x:sub(h,h)],24-h*6)end;for h=1,3 do s[h]=l(k(y,24-h*8),0xff)end;return s,w end;local function z(c)assert(fs.exists(c),'File does not exist')local A=fs.open(c,"rb")local s=""for B=1,fs.getSize(c),3 do local n,o,p=A.read(),A.read(),A.read()s=s..m(n,o,p)end;return s end;local function C(D,E)assert(#D%4==0,"Coded string should be a multiple of 4")local F=fs.open(E,"wb")for h=1,#D,4 do local G,w=u(D:sub(h,h+3))for H=1,3-w do F.write(G[H])end end;F.close()end;local I={encodeFile=z,decodeFile=C}return I end,["functions.add"]=function()local J=require"functions.install.downloadFile"local K=require"functions.delete"require"functions.json"local function L(M)local N=M[2]local O=M[3]if not N then return"A name must be provided in order to add a package"end;local P=shell.dir()local Q=fs.combine(P,"package.json")local R={}if fs.exists(Q)then R=decodeFromFile(Q)end;if R and R.dependencies and R.dependencies[N]then K({0,N})end;local S=J(N,O)if not R.dependencies then R.dependencies={}end;R.dependencies[M[2]]="^"..S;local T=fs.open(Q,"w")T.write(encodePretty(R))end;return L end,["functions.versions"]=function()require"functions.json"local function U(O,V)local W,X,Y=O:match("(%d+)%.(%d+)%.(%d+)")W,X,Y=tonumber(W),tonumber(X),tonumber(Y)if V=="major"then return string.format("%d.0.0",W+1)elseif V=="minor"then return string.format("%d.%d.0",W,X+1)elseif V=="patch"then return string.format("%d.%d.%d",W,X,Y+1)else error("Invalid increment type: "..V)end end;local function Z(V)local P=shell.dir()local _=fs.combine(P,"package.json")if not fs.exists(_)then return"No package.json found!"end;local R=decodeFromFile(_)if not R["version"]then return"Must initialize package before incrementing version. Run luam init"end;local a0=U(R["version"],V or"patch")print(string.format("Updated to %s",a0))R["version"]=a0;local a1=fs.open(_,"w")a1.write(encodePretty(R))a1.close()return a0 end;return Z end,["functions.init"]=function()require"functions.json"local function a2(M)local P=shell.dir()if M[2]then P=P.."/"..M[2]end;local _=fs.combine(P,"package.json")local R={}if fs.exists(_)then R=decodeFromFile(_)end;if R["name"]then print("Package has already been initialized")end;local N=M[2]or P:match("([^/]+)$")local F=fs.open(_,"w")R["name"]=N;R["version"]="0.1.0"R["dependencies"]=R["dependencies"]or{}F.write(encodePretty(R))local a3=fs.open(fs.combine(P,".luamignore"),"w")a3.write("luam_modules\n")a3.write("package-lock.json")return string.format("Package %s has been initialized",N)end;return a2 end,["functions.login"]=function()local function a4(M)local a5=fs.open("luam.key","w")a5.write(M[2])a5.close()return"API token now in use"end;return a4 end,["functions.install.downloadFile"]=function()require"functions.json"local a6=require("tar.lib")local a7=require("base64.lib")local a8="https://api.luam.dev/packages/install"local function a9(aa,N,ab)local ac=aa.."/"..N..".tar"a7.decodeFile(ab,ac)a6.untar(ac,aa)fs.delete(ac)end;local function ad(table,ae)for B,af in ipairs(table)do if af==ae then return true end end;return false end;local function ag(ah)local ai={}for B,ae in ipairs(ah)do table.insert(ai,ae)end;return ai end;local function aj(ak,al,h,N)for H=1,h do ak=ak.."/luam_modules/"..al[H]end;if N then ak=ak.."/luam_modules/"..N end;return ak end;local function am(an)local ao=an:match(".*()/")return ao and an:sub(1,ao-1)or an end;local function ap(c,aq,ar,as)c=c.."/luam_modules/"..aq;while#c>0 do local x=as[c]if x and x.name==aq and x.version==ar then return c end;for h=1,3 do local at=c;c=am(c)if at==c then return false end end;c=c.."/"..aq end end;local function au(av,aw,as)local ax=""for c,x in pairs(as)do if x.name==av.name and x.version==av.version then ax=c end end;fs.copy(ax,aw)return ax end;local function L(ak,ay,as,az,aA)local aB={}local aC=ay[az][aA]aC.name=az;aC.version=aA;aC.options={}table.insert(aB,aC)for B,ae in ipairs(aB)do local N=ae.name;local O=ae.version;local al=ae.options;local aD=ag(al)table.insert(aD,N)for h=0,#al do local aw=aj(ak,al,h,N)if as[aw]and as[aw].version==O then break end;if not as[aw]then if ae.payload then a9(am(aw),N,ae.payload)as[aw]={name=ae.name,version=ae.version,dependencies=ae.dependencies}for aE,aF in pairs(ae.providedDependencyVersions)do local aG=nil;if ay[aE]and ay[aE][aF]then aG=ay[aE][aF]aG.name=aE;aG.version=aF else aG={name=aE,version=aF}end;aG.options=aD;table.insert(aB,aG)end else local aH=""if O then aH=au(ae,aw,as)else local aI=ap(ae.copied_from_path,N)aH=au(aI,aw,as)end;local aJ=as[aH]as[aw]=aJ;for aE,B in pairs(aJ.dependencies)do table.insert(aB,{options=aD,name=aE,copied_from_path=aH})end end;break end end end end;local function J(N,O)local P=shell.dir()local aK=fs.combine(P,"package-lock.json")local as={}if fs.exists(aK)then as=decodeFromFile(aK)or{}end;local aL={}for B,package in pairs(as)do local N=package.name;local O=package.version;if not aL[N]then aL[N]={}end;if not ad(aL[N],O)then table.insert(aL[N],O)end end;local aM=encode(aL)if aM=="[]"then aM="{}"end;local aN={["X-PackageName"]=N,["X-PackageVersion"]=O,["Content-Type"]="application/json"}local aO,aP,aQ=http.post(a8,aM,aN)if not aO then error(string.format("%s: %s",aP,aQ and aQ.readAll()))end;local aR=decode(aO.readAll())local S=O;for aS in pairs(aR[N])do S=aS end;L(P,aR,as,N,S)local aT=fs.open(aK,"w")aT.write(encodePretty(as))aT.close()local aU=0;for O,B in pairs(aR)do for package,B in pairs(aR[O])do aU=aU+1 end end;print(string.format("%s package%s installed",aU,aU>1 and"s"or""))return S end;return J end,["functions.post.encodeFile"]=function()local aV=require("tar.lib")local I=require("base64.lib")local function z(c,aW)assert(fs.exists(c),"File does not exist!")local aX="temp-"..math.floor(1000*math.random())..".tar"aV.tar(c,aX,aW)local aY=I.encodeFile(aX)fs.delete(aX)return aY end;return z end,["functions.json"]=function()local aZ={["\n"]="\\n",["\r"]="\\r",["\t"]="\\t",["\b"]="\\b",["\f"]="\\f",["\""]="\\\"",["\\"]="\\\\"}local function a_(t)local b0=0;for aS,b1 in pairs(t)do if type(aS)~="number"then return false elseif aS>b0 then b0=aS end end;return b0==#t end;local b2={['\n']=true,['\r']=true,['\t']=true,[' ']=true,[',']=true,[':']=true}function removeWhite(b3)while b2[b3:sub(1,1)]do b3=b3:sub(2)end;return b3 end;local function b4(b5,b6,b7,b8)local b3=""local function b9(ba)b3=b3 ..("\t"):rep(b7)..ba end;local function bb(b5,bc,bd,be,bf)b3=b3 ..bc;if b6 then b3=b3 .."\n"b7=b7+1 end;for aS,b1 in be(b5)do b9("")bf(aS,b1)b3=b3 ..","if b6 then b3=b3 .."\n"end end;if b6 then b7=b7-1 end;if b3:sub(-2)==",\n"then b3=b3:sub(1,-3).."\n"elseif b3:sub(-1)==","then b3=b3:sub(1,-2)end;b9(bd)end;if type(b5)=="table"then b8[b5]=true;if a_(b5)then bb(b5,"[","]",ipairs,function(aS,b1)b3=b3 ..b4(b1,b6,b7,b8)end)else bb(b5,"{","}",pairs,function(aS,b1)assert(type(aS)=="string","JSON object keys must be strings",2)b3=b3 ..b4(aS,b6,b7,b8)b3=b3 ..(b6 and": "or":")..b4(b1,b6,b7,b8)end)end elseif type(b5)=="string"then b3='"'..b5:gsub("[%c\"\\]",aZ)..'"'elseif type(b5)=="number"or type(b5)=="boolean"then b3=tostring(b5)else error("JSON only supports arrays, objects, numbers, booleans, and strings",2)end;return b3 end;function encode(b5)return b4(b5,false,0,{})end;function encodePretty(b5)return b4(b5,true,0,{})end;local bg={}for aS,b1 in pairs(aZ)do bg[b1]=aS end;function parseBoolean(b3)if b3:sub(1,4)=="true"then return true,removeWhite(b3:sub(5))else return false,removeWhite(b3:sub(6))end end;function parseNull(b3)return nil,removeWhite(b3:sub(5))end;local bh={['e']=true,['E']=true,['+']=true,['-']=true,['.']=true}function parseNumber(b3)local h=1;while bh[b3:sub(h,h)]or tonumber(b3:sub(h,h))do h=h+1 end;local b5=tonumber(b3:sub(1,h-1))b3=removeWhite(b3:sub(h))return b5,b3 end;function parseString(b3)b3=b3:sub(2)local ba=""while b3:sub(1,1)~="\""do local bi=b3:sub(1,1)b3=b3:sub(2)assert(bi~="\n","Unclosed string")if bi=="\\"then local bj=b3:sub(1,1)b3=b3:sub(2)bi=assert(bg[bi..bj],"Invalid escape character")end;ba=ba..bi end;return ba,removeWhite(b3:sub(2))end;function parseArray(b3)b3=removeWhite(b3:sub(2))local b5={}local h=1;while b3:sub(1,1)~="]"do local b1=nil;b1,b3=parseValue(b3)b5[h]=b1;h=h+1;b3=removeWhite(b3)end;b3=removeWhite(b3:sub(2))return b5,b3 end;function parseObject(b3)b3=removeWhite(b3:sub(2))local b5={}while b3:sub(1,1)~="}"do local aS,b1=nil,nil;aS,b1,b3=parseMember(b3)b5[aS]=b1;b3=removeWhite(b3)end;b3=removeWhite(b3:sub(2))return b5,b3 end;function parseMember(b3)local aS=nil;aS,b3=parseValue(b3)local b5=nil;b5,b3=parseValue(b3)return aS,b5,b3 end;function parseValue(b3)local bk=b3:sub(1,1)if bk=="{"then return parseObject(b3)elseif bk=="["then return parseArray(b3)elseif tonumber(bk)~=nil or bh[bk]then return parseNumber(b3)elseif b3:sub(1,4)=="true"or b3:sub(1,5)=="false"then return parseBoolean(b3)elseif bk=="\""then return parseString(b3)elseif b3:sub(1,4)=="null"then return parseNull(b3)end;return nil end;function decode(b3)b3=removeWhite(b3)t=parseValue(b3)return t end;function decodeFromFile(c)local bl=assert(fs.open(c,"r"))local bm=decode(bl.readAll())bl.close()return bm end end,["functions.delete.deletePackage"]=function()local function am(an)local ao=an:match(".*()/")return ao and an:sub(1,ao-1)or an end;local function bn(bo,bp,bq,as)bq=bq.."/luam_modules/"..bo;while bq~=bp do if as[bq]then return false end;for B=1,3 do bq=am(bq)end;bq=bq.."/"..bo end;return true end;local function ap(c,aq,as)c=c.."/luam_modules/"..aq;while#c>0 do local x=as[c]if x then return c end;for h=1,3 do local at=c;c=am(c)if at==c then return end end;c=c.."/"..aq end end;local function br(ah,bs)for aS,B in pairs(ah)do if aS==bs then return true end end;return false end;local function bt(N,c,as)for Q,av in pairs(as)do if br(av.dependencies,N)then print(av.name)if bn(N,c,Q,as)then return end end end;local x=as[c]local bu=x.dependencies;fs.delete(c)as[c]=nil;for bv in pairs(as)do if bv:sub(1,#c)==c then as[bv]=nil end end;for aE in pairs(bu)do local bw=ap(c,aE,as)if bw then bt(aE,bw,as)end end end;return bt end,["functions.post"]=function()local z=require("functions.post.encodeFile")local bx=require("functions.versions")require("functions.json")local by="https://api.luam.dev/packages"local function bz(R)local bA={"name","version","dependencies"}for B,bB in ipairs(bA)do if not R[bB]then error(string.format('Required field "%s" missing from package.json',bB))end end;local bC=fs.open(string.format(".luamversioncache/%s",R.name),"r")if bC then local O=bC.readAll()if O==R["version"]then local a0=bx("patch")R["version"]=a0 end end end;local function bD()local P=shell.dir()local _=fs.combine(P,"package.json")if not fs.exists('luam.key')then return'No api token found. Run luam login and provide a valid api token.'end;local bE=fs.open("luam.key","r").readAll()if not fs.exists(_)then return'"package.json" not found. Run "luam init" to initialize package.'end;local R=decodeFromFile(_)bz(R)local bF=fs.combine(P,".luamignore")local bG={}if fs.exists(bF)then local bH=fs.open(bF,"r")local bI="temp"while bI do bI=bH.readLine()if not bI then break end;table.insert(bG,P.."/"..bI)end end;local bJ=z(P,bG)local bK={name=R.name,version=R.version,dependencies=R.dependencies,payload=bJ}local bC=fs.open(".luamversioncache".."/"..R.name,"w")bC.write(R.version)bC.close()local aO,bL,bM=http.post(by,encode(bK),{Authorization=bE})if not aO then if not bM then return"The request timed out. Either luam is down or it is blocked on your network"end;return string.format("%s: %s",bL,decode(bM.readAll()).message or"No message provided")end;return string.format("%s v%s was posted successfully!",R.name,R.version)end;return bD end,["functions.delete"]=function()require"functions.json"require"functions.delete.deletePackage"local bt=require"functions.delete.deletePackage"local function K(M)local P=shell.dir()local bN=M[2]if not bN then return end;local _=fs.combine(P,"package.json")if not _ then return"No package.json found."end;local R=decodeFromFile(_)if not R.dependencies then return"No dependencies to delete"end;if not R.dependencies[bN]then return string.format("%s not found. Perhaps you made a typo?",bN)end;R.dependencies[bN]=nil;local aK=fs.combine(P,"package-lock.json")local as={}if fs.exists(_)then as=decodeFromFile(aK)end;local bO=P.."/luam_modules/"..bN;if not fs.exists(bO)then return string.format("%s not found",bO)end;bt(bN,bO,as)local T=fs.open(_,"w")T.write(encodePretty(R))T.close()local aT=fs.open(aK,"w")aT.write(encodePretty(as))aT.close()end;return K end,["tar.lib"]=function()local bP=true;local bQ="000755 \0"local bR=string.rep("\0",32)local bS=bR;local bT=string.rep("\0",100)local bU="000000 \0"local bV=bU;local bW=bU;local bX=bV;local bY="0"local bZ="5"local b_="00"local c0="ustar\0"local c1=string.rep(" ",8)local c2=string.rep("\0",512)local function c3(string,c4,i)i=i or"0"if#string>=c4 then return string end;return string.rep(i,c4-#string)..string end;local function c5(string,c4,i)i=i or"0"if#string>=c4 then return string end;return string..string.rep(i,c4-#string)end;local function c6(c7)return string.format("%o",c7)end;local function c8(c9)local ca=0;for i in string.gmatch(c9,".")do ca=ca+string.byte(i)end;return string.format("%06s",c6(ca)).."\0 "end;local function cb(aa,c)local cc=aa.."/"..c;assert(fs.exists(cc),"The file path "..cc.." does not exist")local cd=fs.isDir(cc)and bZ or bY;local ce=c3(c6(fs.getSize(cc)),11,0).." "local cf=c3(c6(os.date("%s")),11).." "local N,cg;if#c>100 then cg=string.sub(c,1,155)N=c5(string.sub(c,156,255),100,"\0")else N=c5(c,100,"\0")cg=string.rep("\0",155)end;local ch=N..bQ..bW..bX..ce..cf;local ci=cd..bT..c0 ..b_..bR..bS..bU..bV..cg;local ca=c8(ch..c1 ..ci)return c5(ch..ca..ci,512,"\0")end;local function cj(c9,ck)for h=1,#c9 do ck.write(string.byte(c9,h))end end;local function z(aa,c,ck)local cc=aa.."/"..c;assert(fs.exists(cc))local c9=cb(aa,c)cj(c9,ck)local ce=fs.getSize(cc)local w=0;if not fs.isDir(cc)then w=512-ce%512 end;local A=fs.open(cc,"rb")for B=1,ce do ck.write(A.read())end;for B=1,w do ck.write(0)end end;local function cl(ck)for B=1,1024 do ck.write(0)end;ck.close()end;local function ad(cm,ae)for B,af in ipairs(cm)do if af==ae then return true end end;return false end;local function cn(aa,co,cp,F,cq)local cr=aa.."/"..co;if ad(cp,cr)then return end;if not fs.isDir(cr)then z(aa,co,F)return else if#fs.list(cr)==0 then z(aa,co,F)end end;for B,cs in ipairs(fs.list(cr))do if bP and string.sub(cs,1,1)~="."or not bP then local ct=co.."/"..cs;local cu=aa.."/"..ct;if fs.isDir(cu)then cn(aa,ct,cp,F,cq)elseif cu~=cq then if not ad(cp,cu)then z(aa,ct,F)end end end end end;local function a6(c,s,cp,F)assert(c,"No path was provided")if s then assert(string.sub(s,-4)==".tar","Output file path must end with .tar!")end;local aa,cv=string.match(c,"(.-)/([^/]+)$")aa=aa or""cv=cv or c;s=s or"/"..aa.."/"..cv..".tar"F=F or fs.open(s,"wb")cn(aa,cv,cp,F,s)cl(F)end;local function cw(c9,cx,cy)local cz=c9:sub(cx,cy):gsub("\0","")cz=cz:gsub("^%s+","")cz=cz:gsub("%s+$","")return cz end;local function cA(c9)local N=cw(c9,1,100)local cg=cw(c9,345,500)local ce=tonumber(cw(c9,124,136),8)local type=tonumber(cw(c9,156,157))return N,cg,ce,type end;local function cB(E,ce,A)local F=fs.open(E,"wb")for B=1,ce do F.write(A.read())end;local w=512-ce%512;if w~=512 then for B=1,w do A.read()end end;F.close()end;local function cC(c,E)E=E or shell.dir()assert(fs.exists(c))assert(string.sub(c,-4)==".tar","File is not a tar file")assert(fs.getSize(c)%512==0,"File size is not a multiple of 512. Invalid tar.")local A=fs.open(c,"rb")for B=1,fs.getSize(c)/512-1 do local c9=A.read(512)if c9==nil then return end;if c9~=c2 then local N,cg,ce,type=cA(c9)local cD=E.."/"..(cg and cg..N or N)if type==5 then fs.makeDir(cD)else if not fs.exists(cD)then cB(cD,ce,A)else for h=1,512 do A.read()end end end end end end;local aV={tar=a6,untar=cC}return aV end}if d[c]then return d[c]else return b(c)end end end;local M={...}if M[1]~=".luam"then local a2=require"functions.init"local bD=require"functions.post"local cE=require"functions.add"local a4=require"functions.login"local K=require"functions.delete"local bx=require"functions.versions"local cF={init=a2,post=bD,add=cE,a=cE,delete=K,d=K,login=a4,patch=function()bx("patch")end,minor=function()bx("minor")end,major=function()bx("major")end}local cx=os.clock()local cG,aO=pcall(function()if not M[1]then error("At least one argument expected.")end;if not cF[M[1]]then error(string.format("%s is not a valid command",M[1]))end;local aO=cF[M[1]](M)return aO end)if not cG then print("Error!")end;if aO then print(aO)end;print(string.format("Finished in %0.3f seconds",os.clock()-cx))else local function cH(b3,cI)local aO={}for cJ in(b3 ..cI):gmatch("(.-)"..cI)do table.insert(aO,cJ)end;return aO end;local cK=require;local function cL(cM,cN)while#cM>0 do local c=table.concat(cM,"/").."/luam_modules/"..cN;local cO,cP=pcall(cK,c:gsub("/","."))if cO then return cP end;table.remove(cM)table.remove(cM)end end;function require(cN)local cQ=debug.getinfo(2,"S")local c=cQ.source:sub(2)c=c:match("(.*/)")or""c=c:sub(1,#c-1)local cM=cH(c,"/")local cP=cL(cM,cN)if cP then return cP end;return cK(cN)end end

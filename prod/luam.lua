do local a=package.searchers or package.loaders;local b=a[2]a[2]=function(c)local d={["tar.lib"]=function()local e=true;local f="000755 \0"local g=string.rep("\0",32)local h=g;local i=string.rep("\0",100)local j="000000 \0"local k=j;local l=j;local m=k;local n="0"local o="5"local p="00"local q="ustar\0"local r=string.rep(" ",8)local s=string.rep("\0",512)local function u(string,v,w)w=w or"0"if#string>=v then return string end;return string.rep(w,v-#string)..string end;local function x(string,v,w)w=w or"0"if#string>=v then return string end;return string..string.rep(w,v-#string)end;local function y(z)return string.format("%o",z)end;local function A(B)local C=0;for w in string.gmatch(B,".")do C=C+string.byte(w)end;return string.format("%06s",y(C)).."\0 "end;local function D(E,c)local F=E.."/"..c;assert(fs.exists(F),"The file path "..F.." does not exist")local G=fs.isDir(F)and o or n;local H=u(y(fs.getSize(F)),11,0).." "local I=u(y(os.date("%s")),11).." "local J,K;if#c>100 then K=string.sub(c,1,155)J=x(string.sub(c,156,255),100,"\0")else J=x(c,100,"\0")K=string.rep("\0",155)end;local L=J..f..l..m..H..I;local M=G..i..q..p..g..h..j..k..K;local C=A(L..r..M)return x(L..C..M,512,"\0")end;local function N(B,O)for P=1,#B do O.write(string.byte(B,P))end end;local function Q(E,c,O)local F=E.."/"..c;assert(fs.exists(F))local B=D(E,c)N(B,O)local H=fs.getSize(F)local R=0;if not fs.isDir(F)then R=512-H%512 end;local S=fs.open(F,"rb")for T=1,H do O.write(S.read())end;for T=1,R do O.write(0)end end;local function U(O)for T=1,1024 do O.write(0)end;O.close()end;local function V(W,X)for T,Y in ipairs(W)do if Y==X then return true end end;return false end;local function Z(E,_,a0,a1,a2)local a3=E.."/".._;if V(a0,a3)then return end;if not fs.isDir(a3)then Q(E,_,a1)return else if#fs.list(a3)==0 then Q(E,_,a1)end end;for T,a4 in ipairs(fs.list(a3))do if e and string.sub(a4,1,1)~="."or not e then local a5=_.."/"..a4;local a6=E.."/"..a5;if fs.isDir(a6)then Z(E,a5,a0,a1,a2)elseif a6~=a2 then if not V(a0,a6)then Q(E,a5,a1)end end end end end;local function a7(c,a8,a0,a1)assert(c,"No path was provided")if a8 then assert(string.sub(a8,-4)==".tar","Output file path must end with .tar!")end;local E,a9=string.match(c,"(.-)/([^/]+)$")E=E or""a9=a9 or c;a8=a8 or"/"..E.."/"..a9 ..".tar"a1=a1 or fs.open(a8,"wb")Z(E,a9,a0,a1,a8)U(a1)end;local function aa(B,ab,ac)local ad=B:sub(ab,ac):gsub("\0","")ad=ad:gsub("^%s+","")ad=ad:gsub("%s+$","")return ad end;local function ae(B)local J=aa(B,1,100)local K=aa(B,345,500)local H=tonumber(aa(B,124,136),8)local type=tonumber(aa(B,156,157))return J,K,H,type end;local function af(ag,H,S)local a1=fs.open(ag,"wb")for T=1,H do a1.write(S.read())end;local R=512-H%512;if R~=512 then for T=1,R do S.read()end end;a1.close()end;local function ah(c,ag)ag=ag or shell.dir()assert(fs.exists(c))assert(string.sub(c,-4)==".tar","File is not a tar file")assert(fs.getSize(c)%512==0,"File size is not a multiple of 512. Invalid tar.")local S=fs.open(c,"rb")for T=1,fs.getSize(c)/512-1 do local B=S.read(512)if B==nil then return end;if B~=s then local J,K,H,type=ae(B)local ai=ag.."/"..(K and K..J or J)if type==5 then fs.makeDir(ai)else if not fs.exists(ai)then af(ai,H,S)else for P=1,512 do S.read()end end end end end end;local aj={tar=a7,untar=ah}return aj end,["base64.lib"]=function()local ak="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"local al={}local am={}for P=1,#ak do local w=ak:sub(P,P)al[P]=w;am[w]=P-1 end;local an,ao,ap=bit.blshift,bit.blogic_rshift,bit.band;local function aq(ar,as,at)assert(ar,"At least one input byte required")local au=not as and 1 or not at and 2 or 3;as=as or 0;at=at or 0;local av=an(ar,16)+an(as,8)+at;local a8=""for P=3,3-au,-1 do a8=a8 ..al[1+tonumber(ap(ao(av,P*6),0x3f))]end;a8=a8 ..string.rep("=",3-au)return a8 end;local function aw(ax)assert(#ax==4,"Chars must be of length 4")local R=#ax:gsub("[^=]","")local ay=ax:gsub("=","A")local az=0;local a8={}for P=1,4 do az=az+an(am[ay:sub(P,P)],24-P*6)end;for P=1,3 do a8[P]=ap(ao(az,24-P*8),0xff)end;return a8,R end;local function Q(c)assert(fs.exists(c),'File does not exist')local S=fs.open(c,"rb")local a8=""for T=1,fs.getSize(c),3 do local ar,as,at=S.read(),S.read(),S.read()a8=a8 ..aq(ar,as,at)end;return a8 end;local function aA(aB,ag)assert(#aB%4==0,"Coded string should be a multiple of 4")local a1=fs.open(ag,"wb")for P=1,#aB,4 do local aC,R=aw(aB:sub(P,P+3))for aD=1,3-R do a1.write(aC[aD])end end;a1.close()end;local aE={encodeFile=Q,decodeFile=aA}return aE end,["functions.add"]=function()local aF=require"functions.install.downloadFile"local aG=require"functions.delete"require"functions.json"local function aH(aI)local J=aI[2]local aJ=aI[3]if not J then return"A name must be provided in order to add a package"end;local aK=shell.dir()local aL=fs.combine(aK,"package.json")local aM={}if fs.exists(aL)then aM=decodeFromFile(aL)end;if aM and aM.dependencies and aM.dependencies[J]then aG({0,J})end;local aN=aF(J,aJ)if not aM.dependencies then aM.dependencies={}end;aM.dependencies[aI[2]]="^"..aN;local aO=fs.open(aL,"w")aO.write(encodePretty(aM))end;return aH end,["functions.delete"]=function()require"functions.json"require"functions.delete.deletePackage"local aP=require"functions.delete.deletePackage"local function aG(aI)local aK=shell.dir()local aQ=aI[2]if not aQ then return end;local aR=fs.combine(aK,"package.json")if not aR then return"No package.json found."end;local aM=decodeFromFile(aR)if not aM.dependencies then return"No dependencies to delete"end;if not aM.dependencies[aQ]then return string.format("%s not found. Perhaps you made a typo?",aQ)end;aM.dependencies[aQ]=nil;local aS=fs.combine(aK,"package-lock.json")local aT={}if fs.exists(aR)then aT=decodeFromFile(aS)end;local aU=aK.."/luam_modules/"..aQ;if not fs.exists(aU)then return string.format("%s not found",aU)end;aP(aQ,aU,aT)local aO=fs.open(aR,"w")aO.write(encodePretty(aM))aO.close()local aV=fs.open(aS,"w")aV.write(encodePretty(aT))aV.close()end;return aG end,["functions.init"]=function()require"functions.json"local function aW(aI)local aK=shell.dir()if aI[2]then aK=aK.."/"..aI[2]end;local aR=fs.combine(aK,"package.json")local aM={}if fs.exists(aR)then aM=decodeFromFile(aR)end;if aM["name"]then print("Package has already been initialized")end;local J=aI[2]or aK:match("([^/]+)$")local a1=fs.open(aR,"w")aM["name"]=J;aM["version"]="0.1.0"aM["dependencies"]=aM["dependencies"]or{}a1.write(encodePretty(aM))local aX=fs.open(fs.combine(aK,".luamignore"),"w")aX.write("luam_modules\n")aX.write("package-lock.json")return string.format("Package %s has been initialized",J)end;return aW end,["functions.json"]=function()local aY={["\n"]="\\n",["\r"]="\\r",["\t"]="\\t",["\b"]="\\b",["\f"]="\\f",["\""]="\\\"",["\\"]="\\\\"}local function aZ(t)local a_=0;for b0,b1 in pairs(t)do if type(b0)~="number"then return false elseif b0>a_ then a_=b0 end end;return a_==#t end;local b2={['\n']=true,['\r']=true,['\t']=true,[' ']=true,[',']=true,[':']=true}function removeWhite(b3)while b2[b3:sub(1,1)]do b3=b3:sub(2)end;return b3 end;local function b4(b5,b6,b7,b8)local b3=""local function b9(ba)b3=b3 ..("\t"):rep(b7)..ba end;local function bb(b5,bc,bd,be,bf)b3=b3 ..bc;if b6 then b3=b3 .."\n"b7=b7+1 end;for b0,b1 in be(b5)do b9("")bf(b0,b1)b3=b3 ..","if b6 then b3=b3 .."\n"end end;if b6 then b7=b7-1 end;if b3:sub(-2)==",\n"then b3=b3:sub(1,-3).."\n"elseif b3:sub(-1)==","then b3=b3:sub(1,-2)end;b9(bd)end;if type(b5)=="table"then b8[b5]=true;if aZ(b5)then bb(b5,"[","]",ipairs,function(b0,b1)b3=b3 ..b4(b1,b6,b7,b8)end)else bb(b5,"{","}",pairs,function(b0,b1)assert(type(b0)=="string","JSON object keys must be strings",2)b3=b3 ..b4(b0,b6,b7,b8)b3=b3 ..(b6 and": "or":")..b4(b1,b6,b7,b8)end)end elseif type(b5)=="string"then b3='"'..b5:gsub("[%c\"\\]",aY)..'"'elseif type(b5)=="number"or type(b5)=="boolean"then b3=tostring(b5)else error("JSON only supports arrays, objects, numbers, booleans, and strings",2)end;return b3 end;function encode(b5)return b4(b5,false,0,{})end;function encodePretty(b5)return b4(b5,true,0,{})end;local bg={}for b0,b1 in pairs(aY)do bg[b1]=b0 end;function parseBoolean(b3)if b3:sub(1,4)=="true"then return true,removeWhite(b3:sub(5))else return false,removeWhite(b3:sub(6))end end;function parseNull(b3)return nil,removeWhite(b3:sub(5))end;local bh={['e']=true,['E']=true,['+']=true,['-']=true,['.']=true}function parseNumber(b3)local P=1;while bh[b3:sub(P,P)]or tonumber(b3:sub(P,P))do P=P+1 end;local b5=tonumber(b3:sub(1,P-1))b3=removeWhite(b3:sub(P))return b5,b3 end;function parseString(b3)b3=b3:sub(2)local ba=""while b3:sub(1,1)~="\""do local bi=b3:sub(1,1)b3=b3:sub(2)assert(bi~="\n","Unclosed string")if bi=="\\"then local bj=b3:sub(1,1)b3=b3:sub(2)bi=assert(bg[bi..bj],"Invalid escape character")end;ba=ba..bi end;return ba,removeWhite(b3:sub(2))end;function parseArray(b3)b3=removeWhite(b3:sub(2))local b5={}local P=1;while b3:sub(1,1)~="]"do local b1=nil;b1,b3=parseValue(b3)b5[P]=b1;P=P+1;b3=removeWhite(b3)end;b3=removeWhite(b3:sub(2))return b5,b3 end;function parseObject(b3)b3=removeWhite(b3:sub(2))local b5={}while b3:sub(1,1)~="}"do local b0,b1=nil,nil;b0,b1,b3=parseMember(b3)b5[b0]=b1;b3=removeWhite(b3)end;b3=removeWhite(b3:sub(2))return b5,b3 end;function parseMember(b3)local b0=nil;b0,b3=parseValue(b3)local b5=nil;b5,b3=parseValue(b3)return b0,b5,b3 end;function parseValue(b3)local bk=b3:sub(1,1)if bk=="{"then return parseObject(b3)elseif bk=="["then return parseArray(b3)elseif tonumber(bk)~=nil or bh[bk]then return parseNumber(b3)elseif b3:sub(1,4)=="true"or b3:sub(1,5)=="false"then return parseBoolean(b3)elseif bk=="\""then return parseString(b3)elseif b3:sub(1,4)=="null"then return parseNull(b3)end;return nil end;function decode(b3)b3=removeWhite(b3)t=parseValue(b3)return t end;function decodeFromFile(c)local bl=assert(fs.open(c,"r"))local bm=decode(bl.readAll())bl.close()return bm end end,["functions.login"]=function()local function bn(aI)print("API Token: ")local bo=io.read()local bp=fs.open("luam.key","w")bp.write(bo)bp.close()return"API token now in use"end;return bn end,["functions.post"]=function()local Q=require("functions.post.encodeFile")local bq=require("functions.versions")require("functions.json")local br="https://api.luam.dev/packages"local function bs(aM)local bt={"name","version","dependencies"}for T,bu in ipairs(bt)do if not aM[bu]then error(string.format('Required field "%s" missing from package.json',bu))end end;local bv=fs.open(string.format(".luamversioncache/%s",aM.name),"r")if bv then local aJ=bv.readAll()if aJ==aM["version"]then local bw=bq("patch")aM["version"]=bw end end end;local function bx()local aK=shell.dir()local aR=fs.combine(aK,"package.json")if not fs.exists('luam.key')then return'No api token found. Run luam login and provide a valid api token.'end;local by=fs.open("luam.key","r").readAll()if not fs.exists(aR)then return'"package.json" not found. Run "luam init" to initialize package.'end;local aM=decodeFromFile(aR)bs(aM)local bz=fs.combine(aK,".luamignore")local bA={}if fs.exists(bz)then local bB=fs.open(bz,"r")local bC="temp"while bC do bC=bB.readLine()if not bC then break end;table.insert(bA,aK.."/"..bC)end end;local bD=Q(aK,bA)local bE={name=aM.name,version=aM.version,dependencies=aM.dependencies,payload=bD}local bv=fs.open(".luamversioncache".."/"..aM.name,"w")bv.write(aM.version)bv.close()local bF,bG,bH=http.post(br,encode(bE),{Authorization=by})if not bF then if not bH then return"The request timed out. Either luam is down or it is blocked on your network"end;return string.format("%s: %s",bG,decode(bH.readAll()).message or"No message provided")end;return string.format("%s v%s was posted successfully!",aM.name,aM.version)end;return bx end,["functions.delete.deletePackage"]=function()local function bI(bJ)local bK=bJ:match(".*()/")return bK and bJ:sub(1,bK-1)or bJ end;local function bL(bM,bN,bO,aT)bO=bO.."/luam_modules/"..bM;while bO~=bN do if aT[bO]then return false end;for T=1,3 do bO=bI(bO)end;bO=bO.."/"..bM end;return true end;local function bP(c,bQ,aT)c=c.."/luam_modules/"..bQ;while#c>0 do local ay=aT[c]if ay then return c end;for P=1,3 do local bR=c;c=bI(c)if bR==c then return end end;c=c.."/"..bQ end end;local function bS(bT,bU)for b0,T in pairs(bT)do if b0==bU then return true end end;return false end;local function aP(J,c,aT)for aL,bV in pairs(aT)do if bS(bV.dependencies,J)then print(bV.name)if bL(J,c,aL,aT)then return end end end;local ay=aT[c]local bW=ay.dependencies;fs.delete(c)aT[c]=nil;for bX in pairs(aT)do if bX:sub(1,#c)==c then aT[bX]=nil end end;for bY in pairs(bW)do local bZ=bP(c,bY,aT)if bZ then aP(bY,bZ,aT)end end end;return aP end,["functions.install.downloadFile"]=function()require"functions.json"local a7=require("tar.lib")local b_=require("base64.lib")local c0="https://api.luam.dev/packages/install"local function c1(E,J,c2)local c3=E.."/"..J..".tar"b_.decodeFile(c2,c3)a7.untar(c3,E)fs.delete(c3)end;local function V(table,X)for T,Y in ipairs(table)do if Y==X then return true end end;return false end;local function c4(bT)local c5={}for T,X in ipairs(bT)do table.insert(c5,X)end;return c5 end;local function c6(c7,c8,P,J)for aD=1,P do c7=c7 .."/luam_modules/"..c8[aD]end;if J then c7=c7 .."/luam_modules/"..J end;return c7 end;local function bI(bJ)local bK=bJ:match(".*()/")return bK and bJ:sub(1,bK-1)or bJ end;local function bP(c,bQ,c9,aT)c=c.."/luam_modules/"..bQ;while#c>0 do local ay=aT[c]if ay and ay.name==bQ and ay.version==c9 then return c end;for P=1,3 do local bR=c;c=bI(c)if bR==c then return false end end;c=c.."/"..bQ end end;local function ca(bV,cb,aT)local cc=""for c,ay in pairs(aT)do if ay.name==bV.name and ay.version==bV.version then cc=c end end;fs.copy(cc,cb)return cc end;local function aH(c7,cd,aT,ce,cf)local cg={}local ch=cd[ce][cf]ch.name=ce;ch.version=cf;ch.options={}table.insert(cg,ch)for T,X in ipairs(cg)do local J=X.name;local aJ=X.version;local c8=X.options;local ci=c4(c8)table.insert(ci,J)for P=0,#c8 do local cb=c6(c7,c8,P,J)if aT[cb]and aT[cb].version==aJ then break end;if not aT[cb]then if X.payload then c1(bI(cb),J,X.payload)aT[cb]={name=X.name,version=X.version,dependencies=X.dependencies}for bY,cj in pairs(X.providedDependencyVersions)do local ck=nil;if cd[bY]and cd[bY][cj]then ck=cd[bY][cj]ck.name=bY;ck.version=cj else ck={name=bY,version=cj}end;ck.options=ci;table.insert(cg,ck)end else local cl=""if aJ then cl=ca(X,cb,aT)else local cm=bP(X.copied_from_path,J)cl=ca(cm,cb,aT)end;local cn=aT[cl]aT[cb]=cn;for bY,T in pairs(cn.dependencies)do table.insert(cg,{options=ci,name=bY,copied_from_path=cl})end end;break end end end end;local function aF(J,aJ)local aK=shell.dir()local aS=fs.combine(aK,"package-lock.json")local aT={}if fs.exists(aS)then aT=decodeFromFile(aS)or{}end;local co={}for T,package in pairs(aT)do local J=package.name;local aJ=package.version;if not co[J]then co[J]={}end;if not V(co[J],aJ)then table.insert(co[J],aJ)end end;local cp=encode(co)if cp=="[]"then cp="{}"end;local cq={["X-PackageName"]=J,["X-PackageVersion"]=aJ,["Content-Type"]="application/json"}local bF,cr,cs=http.post(c0,cp,cq)if not bF then error(string.format("%s: %s",cr,cs and cs.readAll()))end;local ct=decode(bF.readAll())local aN=aJ;for b0 in pairs(ct[J])do aN=b0 end;aH(aK,ct,aT,J,aN)local aV=fs.open(aS,"w")aV.write(encodePretty(aT))aV.close()local cu=0;for aJ,T in pairs(ct)do for package,T in pairs(ct[aJ])do cu=cu+1 end end;print(string.format("%s package%s installed",cu,cu>1 and"s"or""))return aN end;return aF end,["functions.post.encodeFile"]=function()local aj=require("tar.lib")local aE=require("base64.lib")local function Q(c,cv)assert(fs.exists(c),"File does not exist!")local cw="temp-"..math.floor(1000*math.random())..".tar"aj.tar(c,cw,cv)local cx=aE.encodeFile(cw)fs.delete(cw)return cx end;return Q end,["functions.versions"]=function()require"functions.json"local function cy(aJ,cz)local cA,cB,cC=aJ:match("(%d+)%.(%d+)%.(%d+)")cA,cB,cC=tonumber(cA),tonumber(cB),tonumber(cC)if cz=="major"then return string.format("%d.0.0",cA+1)elseif cz=="minor"then return string.format("%d.%d.0",cA,cB+1)elseif cz=="patch"then return string.format("%d.%d.%d",cA,cB,cC+1)else error("Invalid increment type: "..cz)end end;local function cD(cz)local aK=shell.dir()local aR=fs.combine(aK,"package.json")if not fs.exists(aR)then return"No package.json found!"end;local aM=decodeFromFile(aR)if not aM["version"]then return"Must initialize package before incrementing version. Run luam init"end;local bw=cy(aM["version"],cz or"patch")print(string.format("Updated to %s",bw))aM["version"]=bw;local cE=fs.open(aR,"w")cE.write(encodePretty(aM))cE.close()return bw end;return cD end}if d[c]then return d[c]else return b(c)end end end;local aI={...}if aI[1]~=".luam"then local aW=require"functions.init"local bx=require"functions.post"local cF=require"functions.add"local bn=require"functions.login"local aG=require"functions.delete"local bq=require"functions.versions"local cG={init=aW,post=bx,add=cF,a=cF,delete=aG,d=aG,login=bn,patch=function()bq("patch")end,minor=function()bq("minor")end,major=function()bq("major")end}local ab=os.clock()local cH,bF=pcall(function()if not aI[1]then error("At least one argument expected.")end;if not cG[aI[1]]then error(string.format("%s is not a valid command",aI[1]))end;local bF=cG[aI[1]](aI)return bF end)if not cH then print("Error!")end;if bF then print(bF)end;print(string.format("Finished in %0.3f seconds",os.clock()-ab))else local function cI(b3,cJ)local bF={}for cK in(b3 ..cJ):gmatch("(.-)"..cJ)do table.insert(bF,cK)end;return bF end;local cL=require;local function cM(cN,cO)while#cN>0 do local c=table.concat(cN,"/").."/luam_modules/"..cO;local cP,cQ=pcall(cL,c:gsub("/","."))if cP then return cQ end;table.remove(cN)table.remove(cN)end end;function require(cO)local cR=debug.getinfo(2,"S")local c=cR.source:sub(2)c=c:match("(.*/)")or""c=c:sub(1,#c-1)local cN=cI(c,"/")local cQ=cM(cN,cO)if cQ then return cQ end;return cL(cO)end end

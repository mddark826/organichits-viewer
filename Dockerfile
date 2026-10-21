# Organic Hits Exchanger — ONE-CLICK version (works on Railway + Render)
# The official app serves its UI over HTTPS only, while Render/Railway route
# plain HTTP into the container. This wrapper adds a small Node HTTP->HTTPS
# proxy on the platform $PORT (the app stays on internal port 3000) plus a
# self-ping keep-alive so free services do not spin down.

FROM organichits/exchanger:latest

USER root

RUN printf 'const http=require("http"),https=require("https"),tls=require("tls");\nconst PUB=parseInt(process.env.PROXY_PORT||"10000",10);\nconst APP=parseInt(process.env.APP_PORT||"3000",10);\nconst srv=http.createServer((req,res)=>{\n  const headers={...req.headers,host:"127.0.0.1:"+APP};\n  const r=https.request({host:"127.0.0.1",port:APP,path:req.url,method:req.method,headers,rejectUnauthorized:false},u=>{res.writeHead(u.statusCode||502,u.headers);u.pipe(res);});\n  r.on("error",()=>{if(!res.headersSent)res.writeHead(502);res.end("Bad Gateway");});\n  req.pipe(r);\n});\nsrv.on("upgrade",(req,socket,head)=>{\n  const t=tls.connect({host:"127.0.0.1",port:APP,rejectUnauthorized:false},()=>{\n    let raw=req.method+" "+req.url+" HTTP/"+req.httpVersion+"\\r\\n";\n    for(const [k,v] of Object.entries(req.headers))raw+=k+": "+v+"\\r\\n";\n    raw+="\\r\\n";\n    t.write(raw);\n    if(head&&head.length)t.write(head);\n    t.pipe(socket);socket.pipe(t);\n  });\n  t.on("error",()=>socket.destroy());\n  socket.on("error",()=>t.destroy());\n});\nsrv.listen(PUB,"0.0.0.0",()=>console.log("Proxy on "+PUB));\n' > /home/exchanger/proxy.js

RUN printf 'const url=()=>process.env.RENDER_EXTERNAL_URL||(process.env.RAILWAY_PUBLIC_DOMAIN?"https://"+process.env.RAILWAY_PUBLIC_DOMAIN:null);async function ping(){const u=url();if(!u)return;try{await fetch(u,{signal:AbortSignal.timeout(30000)});}catch(e){}}\nping();setInterval(ping,600000);\n' > /home/exchanger/keepalive.js && chmod 644 /home/exchanger/proxy.js /home/exchanger/keepalive.js

USER exchanger

CMD ["/bin/sh", "-c", "PUB=${PORT:-10000}; APP_PORT=3000 PROXY_PORT=$PUB node /home/exchanger/proxy.js & node /home/exchanger/keepalive.js & PORT=3000 exec node src/server.js"]

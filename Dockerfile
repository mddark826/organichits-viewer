# Organic Hits Exchanger — ONE-CLICK version (works on Railway + Render)
# The official image serves its web UI on $PORT (the session key is entered there).
# This wrapper only adds a Node self-ping keep-alive so free services
# do not spin down; the app itself is untouched.

FROM organichits/exchanger:latest

USER root

RUN printf 'const url=()=>process.env.RENDER_EXTERNAL_URL||(process.env.RAILWAY_PUBLIC_DOMAIN?"https://"+process.env.RAILWAY_PUBLIC_DOMAIN:null);async function ping(){const u=url();if(!u)return;try{await fetch(u,{signal:AbortSignal.timeout(30000)});}catch(e){}}\nping();setInterval(ping,600000);\n' > /home/exchanger/keepalive.js && chmod 644 /home/exchanger/keepalive.js

USER exchanger

CMD ["/bin/sh", "-c", "node /home/exchanger/keepalive.js & exec node src/server.js"]

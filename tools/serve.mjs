import http from 'node:http';
import {readFile} from 'node:fs/promises';
import {resolve,extname,sep} from 'node:path';
import {fileURLToPath} from 'node:url';
const root=resolve(fileURLToPath(new URL('../build/web/',import.meta.url)));
const mime={'.html':'text/html; charset=utf-8','.js':'text/javascript; charset=utf-8','.wasm':'application/wasm','.pck':'application/octet-stream','.png':'image/png','.svg':'image/svg+xml','.json':'application/json','.map':'application/json','.zip':'application/zip','.ico':'image/x-icon'};
const server=http.createServer(async(req,res)=>{
  try{
    const path=decodeURIComponent(new URL(req.url,'http://localhost').pathname);
    const file=resolve(root,'.'+(path==='/'?'/index.html':path));
    if(!file.startsWith(root+sep)||!mime[extname(file)]){res.writeHead(404);res.end('Not found');return;}
    const bytes=await readFile(file);
    res.writeHead(200,{'Content-Type':mime[extname(file)],'Cache-Control':'no-cache','X-Content-Type-Options':'nosniff'});
    res.end(bytes);
  }catch(error){res.writeHead(error.code==='ENOENT'?404:400);res.end('Not found');}
});
server.on('error',error=>{console.error(error.message);process.exitCode=1;});
const port=Number(process.env.PORT||4174);
server.listen(port,'127.0.0.1',()=>console.log('Never Sunset Godot · http://localhost:'+port));

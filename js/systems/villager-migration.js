// Stage 5: canonical villagers/workers projection with strategic availability.
import { normalizeVillager, countRoles, VILLAGER_ROLES } from './villagers.js';
const projectWorker=(worker={},index=0)=>({id:worker.id??`legacy-worker-${index}`,state:String(worker.state||'idle'),busy:worker.busy===true,cargo:{...(worker.cargo||{})}});
export function createVillagerMigration(bridge,authority){
  const project=(at=Date.now(),source='legacy-driver')=>{
    const snapshot=bridge?.snapshot?.()||{};const raw=bridge?.villagers?.()||[];const rawWorkers=Array.isArray(snapshot.workers)?snapshot.workers:[];
    const list=Array.isArray(raw)?raw.map((v,index)=>normalizeVillager(v,index)):[];const workers=rawWorkers.map(projectWorker);const busyWorkers=workers.filter(w=>w.busy).length;
    const value={list,workers,count:list.length,workerCount:workers.length,busyWorkers,idleWorkers:Math.max(0,workers.length-busyWorkers),roleCounts:countRoles(list),roles:VILLAGER_ROLES,at};
    return authority?.commit?.('villagers',value,{source,at})||value;
  };
  return{name:'villager-migration',update(_dt,now){project(now??Date.now());},refresh(source='legacy-driver'){return project(Date.now(),source);},snapshot(){return authority?.snapshot?.('villagers')||project();}};
}

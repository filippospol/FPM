/* Shared bits for every page: the "last updated" date next to the credit line, and a back-to-top
   button on the longer pages. The page sets data-json on this script tag to point at fpm.json. */
(function(){
  var me=document.currentScript,json=me&&me.getAttribute('data-json');

  var up=document.getElementById('updated');
  if(up&&json){
    var raw='https://raw.githubusercontent.com/filippospol/FPM/main/docs/leaderboard/fpm.json';
    fetch(json).then(function(r){if(!r.ok)throw 0;return r.json();})
      .catch(function(){return fetch(raw,{cache:'no-store'}).then(function(r){return r.json();});})
      .then(function(m){
        var d=new Date(m.generated);if(isNaN(d))return;
        var mon=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        up.textContent='Last updated '+d.getUTCDate()+' '+mon[d.getUTCMonth()]+' '+d.getUTCFullYear();
        up.parentNode.classList.add('dated');
      }).catch(function(){});
  }

  if(document.body.hasAttribute('data-top')){
    var b=document.createElement('button');
    b.className='top';b.type='button';b.setAttribute('aria-label','Back to top');
    b.innerHTML='&uarr; Top';
    b.addEventListener('click',function(){window.scrollTo({top:0,behavior:'smooth'});});
    document.body.appendChild(b);
    var tick=function(){b.classList.toggle('show',window.scrollY>500);};
    window.addEventListener('scroll',tick,{passive:true});tick();
  }
})();

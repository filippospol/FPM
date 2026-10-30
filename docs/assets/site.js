/* Shared bits for every page: the theme switch, the "last updated" date next to the credit line,
   and a back-to-top button on the longer pages. The page sets data-json on this script tag to
   point at fpm.json. (The theme is applied before paint by the small script in each page's head;
   this file only wires the switch.) */
(function(){
  var me=document.currentScript,json=me&&me.getAttribute('data-json');

  /* theme switch: cycles between light and dark; the choice is remembered, and clearing it
     (by picking whatever the system has) goes back to following the system */
  var sw=document.getElementById('theme');
  if(sw){
    sw.addEventListener('click',function(){
      var root=document.documentElement;
      var sys=window.matchMedia&&window.matchMedia('(prefers-color-scheme: dark)').matches?'dark':'light';
      var cur=root.getAttribute('data-theme')||sys, next=cur==='dark'?'light':'dark';
      if(next===sys){ root.removeAttribute('data-theme'); try{localStorage.removeItem('fpm-theme');}catch(e){} }
      else { root.setAttribute('data-theme',next); try{localStorage.setItem('fpm-theme',next);}catch(e){} }
    });
  }

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

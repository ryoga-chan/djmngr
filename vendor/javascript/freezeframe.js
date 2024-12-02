// freezeframe@5.0.2 downloaded from https://ga.jspm.io/npm:freezeframe@5.0.2/dist/freezeframe.min.js

var i="undefined"!==typeof globalThis?globalThis:"undefined"!==typeof self?self:global;var o={};!function(i,h){o=h()}(window,(function(){return function(i){var o={};function n(h){if(o[h])return o[h].exports;var f=o[h]={i:h,l:!1,exports:{}};return i[h].call(f.exports,f,f.exports,n),f.l=!0,f.exports}return n.m=i,n.c=o,n.d=function(i,o,h){n.o(i,o)||Object.defineProperty(i,o,{enumerable:!0,get:h})},n.r=function(i){"undefined"!=typeof Symbol&&Symbol.toStringTag&&Object.defineProperty(i,Symbol.toStringTag,{value:"Module"}),Object.defineProperty(i,"__esModule",{value:!0})},n.t=function(i,o){if(1&o&&(i=n(i)),8&o)return i;if(4&o&&"object"==typeof i&&i&&i.__esModule)return i;var h=Object.create(null);if(n.r(h),Object.defineProperty(h,"default",{enumerable:!0,value:i}),2&o&&"string"!=typeof i)for(var f in i)n.d(h,f,function(o){return i[o]}.bind(null,f));return h},n.n=function(i){var o=i&&i.__esModule?function(){return i.default}:function(){return i};return n.d(o,"a",o),o},n.o=function(i,o){return Object.prototype.hasOwnProperty.call(i,o)},n.p="examples",n(n.s=4)}([function(o,h,f){var d,p;!function(I,S){d=[f(2)],void 0===(p=function(o){return function(o,h){var f=o.jQuery,d=o.console;function r(i,o){for(var h in o)i[h]=o[h];return i}var p=Array.prototype.slice;function s(o,h,I){if(!((this||i)instanceof s))return new s(o,h,I);var S,E=o;"string"==typeof o&&(E=document.querySelectorAll(o)),E?((this||i).elements=(S=E,Array.isArray(S)?S:"object"==typeof S&&"number"==typeof S.length?p.call(S):[S]),(this||i).options=r({},(this||i).options),"function"==typeof h?I=h:r((this||i).options,h),I&&this.on("always",I),this.getImages(),f&&((this||i).jqDeferred=new f.Deferred),setTimeout((this||i).check.bind(this||i))):d.error("Bad element for imagesLoaded "+(E||o))}s.prototype=Object.create(h.prototype),s.prototype.options={},s.prototype.getImages=function(){(this||i).images=[],(this||i).elements.forEach((this||i).addElementImages,this||i)},s.prototype.addElementImages=function(o){"IMG"==o.nodeName&&this.addImage(o),!0===(this||i).options.background&&this.addElementBackgroundImages(o);var h=o.nodeType;if(h&&I[h]){for(var f=o.querySelectorAll("img"),d=0;d<f.length;d++){var p=f[d];this.addImage(p)}if("string"==typeof(this||i).options.background){var S=o.querySelectorAll((this||i).options.background);for(d=0;d<S.length;d++){var E=S[d];this.addElementBackgroundImages(E)}}}};var I={1:!0,9:!0,11:!0};function c(o){(this||i).img=o}function l(o,h){(this||i).url=o,(this||i).element=h,(this||i).img=new Image}return s.prototype.addElementBackgroundImages=function(i){var o=getComputedStyle(i);if(o)for(var h=/url\((['"])?(.*?)\1\)/gi,f=h.exec(o.backgroundImage);null!==f;){var d=f&&f[2];d&&this.addBackground(d,i),f=h.exec(o.backgroundImage)}},s.prototype.addImage=function(o){var h=new c(o);(this||i).images.push(h)},s.prototype.addBackground=function(o,h){var f=new l(o,h);(this||i).images.push(f)},s.prototype.check=function(){var o=this||i;function e(i,h,f){setTimeout((function(){o.progress(i,h,f)}))}(this||i).progressedCount=0,(this||i).hasAnyBroken=!1,(this||i).images.length?(this||i).images.forEach((function(i){i.once("progress",e),i.check()})):this.complete()},s.prototype.progress=function(o,h,f){(this||i).progressedCount++,(this||i).hasAnyBroken=(this||i).hasAnyBroken||!o.isLoaded,this.emitEvent("progress",[this||i,o,h]),(this||i).jqDeferred&&(this||i).jqDeferred.notify&&(this||i).jqDeferred.notify(this||i,o),(this||i).progressedCount==(this||i).images.length&&this.complete(),(this||i).options.debug&&d&&d.log("progress: "+f,o,h)},s.prototype.complete=function(){var o=(this||i).hasAnyBroken?"fail":"done";if((this||i).isComplete=!0,this.emitEvent(o,[this||i]),this.emitEvent("always",[this||i]),(this||i).jqDeferred){var h=(this||i).hasAnyBroken?"reject":"resolve";(this||i).jqDeferred[h](this||i)}},c.prototype=Object.create(h.prototype),c.prototype.check=function(){this.getIsImageComplete()?this.confirm(0!==(this||i).img.naturalWidth,"naturalWidth"):((this||i).proxyImage=new Image,(this||i).proxyImage.addEventListener("load",this||i),(this||i).proxyImage.addEventListener("error",this||i),(this||i).img.addEventListener("load",this||i),(this||i).img.addEventListener("error",this||i),(this||i).proxyImage.src=(this||i).img.src)},c.prototype.getIsImageComplete=function(){return(this||i).img.complete&&(this||i).img.naturalWidth},c.prototype.confirm=function(o,h){(this||i).isLoaded=o,this.emitEvent("progress",[this||i,(this||i).img,h])},c.prototype.handleEvent=function(o){var h="on"+o.type;(this||i)[h]&&this[h](o)},c.prototype.onload=function(){this.confirm(!0,"onload"),this.unbindEvents()},c.prototype.onerror=function(){this.confirm(!1,"onerror"),this.unbindEvents()},c.prototype.unbindEvents=function(){(this||i).proxyImage.removeEventListener("load",this||i),(this||i).proxyImage.removeEventListener("error",this||i),(this||i).img.removeEventListener("load",this||i),(this||i).img.removeEventListener("error",this||i)},l.prototype=Object.create(c.prototype),l.prototype.check=function(){(this||i).img.addEventListener("load",this||i),(this||i).img.addEventListener("error",this||i),(this||i).img.src=(this||i).url,this.getIsImageComplete()&&(this.confirm(0!==(this||i).img.naturalWidth,"naturalWidth"),this.unbindEvents())},l.prototype.unbindEvents=function(){(this||i).img.removeEventListener("load",this||i),(this||i).img.removeEventListener("error",this||i)},l.prototype.confirm=function(o,h){(this||i).isLoaded=o,this.emitEvent("progress",[this||i,(this||i).element,h])},s.makeJQueryPlugin=function(h){(h=h||o.jQuery)&&((f=h).fn.imagesLoaded=function(o,h){return new s(this||i,o,h).jqDeferred.promise(f(this||i))})},s.makeJQueryPlugin(),s}(I,o)}.apply(h,d))||(o.exports=p)}("undefined"!=typeof window?window:this||i)},function(i,o,h){(i.exports=h(3)(!1)).push([i.i,'.ff-container{display:inline-block;position:relative}.ff-container .ff-image{z-index:0;vertical-align:top;opacity:0}.ff-container .ff-canvas{display:inline-block;position:absolute;top:0;left:0;pointer-events:none;z-index:1;vertical-align:top;opacity:0}.ff-container .ff-canvas.ff-canvas-ready{-webkit-transition:opacity 300ms;-o-transition:opacity 300ms;-moz-transition:opacity 300ms;transition:opacity 300ms;opacity:1}.ff-container.ff-active .ff-image{opacity:1}.ff-container.ff-active .ff-canvas.ff-canvas-ready{-webkit-transition:none;-o-transition:none;-moz-transition:none;transition:none;opacity:0}.ff-container.ff-active .ff-overlay{display:none}.ff-container.ff-inactive .ff-canvas.ff-canvas-ready{-webkit-transition:opacity 300ms;-o-transition:opacity 300ms;-moz-transition:opacity 300ms;transition:opacity 300ms;opacity:1}.ff-container.ff-inactive .ff-image{-webkit-transition:opacity 300ms;-o-transition:opacity 300ms;-moz-transition:opacity 300ms;transition:opacity 300ms;-webkit-transition-delay:170ms;-moz-transition-delay:170ms;-o-transition-delay:170ms;transition-delay:170ms;opacity:0}.ff-container.ff-responsive{width:100%}.ff-container.ff-responsive .ff-image,.ff-container.ff-responsive .ff-canvas{width:100%}.ff-container.ff-loading-icon:before{content:"";position:absolute;background-image:url("data:image/svg+xml;base64,PD94bWwgdmVyc2lvbj0iMS4wIiBlbmNvZGluZz0idXRmLTgiPz48c3ZnIHdpZHRoPSc1MHB4JyBoZWlnaHQ9JzUwcHgnIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIgdmlld0JveD0iMCAwIDEwMCAxMDAiIHByZXNlcnZlQXNwZWN0UmF0aW89InhNaWRZTWlkIiBjbGFzcz0idWlsLXNwaW4iPjxyZWN0IHg9IjAiIHk9IjAiIHdpZHRoPSIxMDAiIGhlaWdodD0iMTAwIiBmaWxsPSJub25lIiBjbGFzcz0iYmsiPjwvcmVjdD48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSg1MCA1MCkiPjxnIHRyYW5zZm9ybT0icm90YXRlKDApIHRyYW5zbGF0ZSgzNCAwKSI+PGNpcmNsZSBjeD0iMCIgY3k9IjAiIHI9IjgiIGZpbGw9IiNmZmZmZmYiPjxhbmltYXRlIGF0dHJpYnV0ZU5hbWU9Im9wYWNpdHkiIGZyb209IjEiIHRvPSIwLjEiIGJlZ2luPSIwcyIgZHVyPSIxcyIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiPjwvYW5pbWF0ZT48YW5pbWF0ZVRyYW5zZm9ybSBhdHRyaWJ1dGVOYW1lPSJ0cmFuc2Zvcm0iIHR5cGU9InNjYWxlIiBmcm9tPSIxLjUiIHRvPSIxIiBiZWdpbj0iMHMiIGR1cj0iMXMiIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIj48L2FuaW1hdGVUcmFuc2Zvcm0+PC9jaXJjbGU+PC9nPjxnIHRyYW5zZm9ybT0icm90YXRlKDQ1KSB0cmFuc2xhdGUoMzQgMCkiPjxjaXJjbGUgY3g9IjAiIGN5PSIwIiByPSI4IiBmaWxsPSIjZmZmZmZmIj48YW5pbWF0ZSBhdHRyaWJ1dGVOYW1lPSJvcGFjaXR5IiBmcm9tPSIxIiB0bz0iMC4xIiBiZWdpbj0iMC4xMnMiIGR1cj0iMXMiIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIj48L2FuaW1hdGU+PGFuaW1hdGVUcmFuc2Zvcm0gYXR0cmlidXRlTmFtZT0idHJhbnNmb3JtIiB0eXBlPSJzY2FsZSIgZnJvbT0iMS41IiB0bz0iMSIgYmVnaW49IjAuMTJzIiBkdXI9IjFzIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSI+PC9hbmltYXRlVHJhbnNmb3JtPjwvY2lyY2xlPjwvZz48ZyB0cmFuc2Zvcm09InJvdGF0ZSg5MCkgdHJhbnNsYXRlKDM0IDApIj48Y2lyY2xlIGN4PSIwIiBjeT0iMCIgcj0iOCIgZmlsbD0iI2ZmZmZmZiI+PGFuaW1hdGUgYXR0cmlidXRlTmFtZT0ib3BhY2l0eSIgZnJvbT0iMSIgdG89IjAuMSIgYmVnaW49IjAuMjVzIiBkdXI9IjFzIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSI+PC9hbmltYXRlPjxhbmltYXRlVHJhbnNmb3JtIGF0dHJpYnV0ZU5hbWU9InRyYW5zZm9ybSIgdHlwZT0ic2NhbGUiIGZyb209IjEuNSIgdG89IjEiIGJlZ2luPSIwLjI1cyIgZHVyPSIxcyIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiPjwvYW5pbWF0ZVRyYW5zZm9ybT48L2NpcmNsZT48L2c+PGcgdHJhbnNmb3JtPSJyb3RhdGUoMTM1KSB0cmFuc2xhdGUoMzQgMCkiPjxjaXJjbGUgY3g9IjAiIGN5PSIwIiByPSI4IiBmaWxsPSIjZmZmZmZmIj48YW5pbWF0ZSBhdHRyaWJ1dGVOYW1lPSJvcGFjaXR5IiBmcm9tPSIxIiB0bz0iMC4xIiBiZWdpbj0iMC4zN3MiIGR1cj0iMXMiIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIj48L2FuaW1hdGU+PGFuaW1hdGVUcmFuc2Zvcm0gYXR0cmlidXRlTmFtZT0idHJhbnNmb3JtIiB0eXBlPSJzY2FsZSIgZnJvbT0iMS41IiB0bz0iMSIgYmVnaW49IjAuMzdzIiBkdXI9IjFzIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSI+PC9hbmltYXRlVHJhbnNmb3JtPjwvY2lyY2xlPjwvZz48ZyB0cmFuc2Zvcm09InJvdGF0ZSgxODApIHRyYW5zbGF0ZSgzNCAwKSI+PGNpcmNsZSBjeD0iMCIgY3k9IjAiIHI9IjgiIGZpbGw9IiNmZmZmZmYiPjxhbmltYXRlIGF0dHJpYnV0ZU5hbWU9Im9wYWNpdHkiIGZyb209IjEiIHRvPSIwLjEiIGJlZ2luPSIwLjVzIiBkdXI9IjFzIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSI+PC9hbmltYXRlPjxhbmltYXRlVHJhbnNmb3JtIGF0dHJpYnV0ZU5hbWU9InRyYW5zZm9ybSIgdHlwZT0ic2NhbGUiIGZyb209IjEuNSIgdG89IjEiIGJlZ2luPSIwLjVzIiBkdXI9IjFzIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSI+PC9hbmltYXRlVHJhbnNmb3JtPjwvY2lyY2xlPjwvZz48ZyB0cmFuc2Zvcm09InJvdGF0ZSgyMjUpIHRyYW5zbGF0ZSgzNCAwKSI+PGNpcmNsZSBjeD0iMCIgY3k9IjAiIHI9IjgiIGZpbGw9IiNmZmZmZmYiPjxhbmltYXRlIGF0dHJpYnV0ZU5hbWU9Im9wYWNpdHkiIGZyb209IjEiIHRvPSIwLjEiIGJlZ2luPSIwLjYycyIgZHVyPSIxcyIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiPjwvYW5pbWF0ZT48YW5pbWF0ZVRyYW5zZm9ybSBhdHRyaWJ1dGVOYW1lPSJ0cmFuc2Zvcm0iIHR5cGU9InNjYWxlIiBmcm9tPSIxLjUiIHRvPSIxIiBiZWdpbj0iMC42MnMiIGR1cj0iMXMiIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIj48L2FuaW1hdGVUcmFuc2Zvcm0+PC9jaXJjbGU+PC9nPjxnIHRyYW5zZm9ybT0icm90YXRlKDI3MCkgdHJhbnNsYXRlKDM0IDApIj48Y2lyY2xlIGN4PSIwIiBjeT0iMCIgcj0iOCIgZmlsbD0iI2ZmZmZmZiI+PGFuaW1hdGUgYXR0cmlidXRlTmFtZT0ib3BhY2l0eSIgZnJvbT0iMSIgdG89IjAuMSIgYmVnaW49IjAuNzVzIiBkdXI9IjFzIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSI+PC9hbmltYXRlPjxhbmltYXRlVHJhbnNmb3JtIGF0dHJpYnV0ZU5hbWU9InRyYW5zZm9ybSIgdHlwZT0ic2NhbGUiIGZyb209IjEuNSIgdG89IjEiIGJlZ2luPSIwLjc1cyIgZHVyPSIxcyIgcmVwZWF0Q291bnQ9ImluZGVmaW5pdGUiPjwvYW5pbWF0ZVRyYW5zZm9ybT48L2NpcmNsZT48L2c+PGcgdHJhbnNmb3JtPSJyb3RhdGUoMzE1KSB0cmFuc2xhdGUoMzQgMCkiPjxjaXJjbGUgY3g9IjAiIGN5PSIwIiByPSI4IiBmaWxsPSIjZmZmZmZmIj48YW5pbWF0ZSBhdHRyaWJ1dGVOYW1lPSJvcGFjaXR5IiBmcm9tPSIxIiB0bz0iMC4xIiBiZWdpbj0iMC44N3MiIGR1cj0iMXMiIHJlcGVhdENvdW50PSJpbmRlZmluaXRlIj48L2FuaW1hdGU+PGFuaW1hdGVUcmFuc2Zvcm0gYXR0cmlidXRlTmFtZT0idHJhbnNmb3JtIiB0eXBlPSJzY2FsZSIgZnJvbT0iMS41IiB0bz0iMSIgYmVnaW49IjAuODdzIiBkdXI9IjFzIiByZXBlYXRDb3VudD0iaW5kZWZpbml0ZSI+PC9hbmltYXRlVHJhbnNmb3JtPjwvY2lyY2xlPjwvZz48L2c+PC9zdmc+");background-position:center center;background-repeat:no-repeat;height:46px;width:46px;z-index:3;top:50%;left:50%;-webkit-transform:translate(-50%, -50%);-moz-transform:translate(-50%, -50%);-ms-transform:translate(-50%, -50%);-o-transform:translate(-50%, -50%);transform:translate(-50%, -50%)}.ff-container .ff-overlay{background-image:url("data:image/png;base64,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");background-repeat:no-repeat;max-width:94px;max-height:94px;position:absolute;left:0%;right:0%;top:0%;bottom:0%;margin:auto;-webkit-background-size:contain;-moz-background-size:contain;background-size:contain;background-position:center;pointer-events:none;z-index:100}',""])},function(o,h,f){var d,p;"undefined"!=typeof window&&window,void 0===(p="function"==typeof(d=function(){function t(){}var o=t.prototype;return o.on=function(o,h){if(o&&h){var f=(this||i)._events=(this||i)._events||{},d=f[o]=f[o]||[];return-1==d.indexOf(h)&&d.push(h),this||i}},o.once=function(o,h){if(o&&h){this.on(o,h);var f=(this||i)._onceEvents=(this||i)._onceEvents||{};return(f[o]=f[o]||{})[h]=!0,this||i}},o.off=function(o,h){var f=(this||i)._events&&(this||i)._events[o];if(f&&f.length){var d=f.indexOf(h);return-1!=d&&f.splice(d,1),this||i}},o.emitEvent=function(o,h){var f=(this||i)._events&&(this||i)._events[o];if(f&&f.length){f=f.slice(0),h=h||[];for(var d=(this||i)._onceEvents&&(this||i)._onceEvents[o],p=0;p<f.length;p++){var I=f[p];d&&d[I]&&(this.off(o,I),delete d[I]),I.apply(this||i,h)}return this||i}},o.allOff=function(){delete(this||i)._events,delete(this||i)._onceEvents},t})?d.call(h,f,h,o):d)||(o.exports=p)},function(o,h,f){o.exports=function(o){var h=[];return h.toString=function(){return this.map((function(i){var h=function(i,o){var h=i[1]||"",f=i[3];if(!f)return h;if(o&&"function"==typeof btoa){var d=(I=f,"/*# sourceMappingURL=data:application/json;charset=utf-8;base64,"+btoa(unescape(encodeURIComponent(JSON.stringify(I))))+" */"),p=f.sources.map((function(i){return"/*# sourceURL="+f.sourceRoot+i+" */"}));return[h].concat(p).concat([d]).join("\n")}var I;return[h].join("\n")}(i,o);return i[2]?"@media "+i[2]+"{"+h+"}":h})).join("")},h.i=function(o,f){"string"==typeof o&&(o=[[null,o,""]]);for(var d={},p=0;p<(this||i).length;p++){var I=(this||i)[p][0];null!=I&&(d[I]=!0)}for(p=0;p<o.length;p++){var S=o[p];null!=S[0]&&d[S[0]]||(f&&!S[2]?S[2]=f:f&&(S[2]="("+S[2]+") and ("+f+")"),h.push(S))}},h}},function(o,h,f){f.r(h);var d,p=f(0),I=f.n(p);!function(i){i.START="start",i.STOP="stop",i.TOGGLE="toggle"}(d||(d={}));const s=i=>`✨Freezeframe: ${i}✨`,a=(i,...o)=>{console.error(s(i),...o)},c=i=>"string"==typeof i?document.querySelectorAll(i):i,l=(i,o,h)=>{const f=i instanceof Element?[i]:i;return Array.from(f).reduce(((i,o)=>{if(o instanceof HTMLImageElement)i.push(o),"gif"!==(i=>i.split(".").pop().toLowerCase().substring(0,3))(o.src)&&h.warnings&&((i,...o)=>{console.warn(s(i),...o)})("Image does not appear to be a gif",o);else{const h=o.querySelectorAll("img");h.length?i=i.concat(Array.from(h)):a("Invalid element",o)}return i}),[])},u=i=>[...new Set(i)],m=i=>{const o=window.document.createElement("div");o.innerHTML=i;const h=o.childNodes;return h.length>1?h:h[0]};var S,E,R=function(){function t(i,o){for(var h=0;h<o.length;h++){var f=o[h];f.enumerable=f.enumerable||!1,f.configurable=!0,"value"in f&&(f.writable=!0),Object.defineProperty(i,f.key,f)}}return function(i,o,h){return o&&t(i.prototype,o),h&&t(i,h),i}}(),Y=(S=["",""],E=["",""],Object.freeze(Object.defineProperties(S,{raw:{value:Object.freeze(E)}})));function g(i,o){if(!(i instanceof o))throw new TypeError("Cannot call a class as a function")}var A=function(){function t(){for(var o=this||i,h=arguments.length,f=Array(h),d=0;d<h;d++)f[d]=arguments[d];return g(this||i,t),(this||i).tag=function(i){for(var h=arguments.length,f=Array(h>1?h-1:0),d=1;d<h;d++)f[d-1]=arguments[d];return"function"==typeof i?o.interimTag.bind(o,i):"string"==typeof i?o.transformEndResult(i):(i=i.map(o.transformString.bind(o)),o.transformEndResult(i.reduce(o.processSubstitutions.bind(o,f))))},f.length>0&&Array.isArray(f[0])&&(f=f[0]),(this||i).transformers=f.map((function(i){return"function"==typeof i?i():i})),(this||i).tag}return R(t,[{key:"interimTag",value:function(i,o){for(var h=arguments.length,f=Array(h>2?h-2:0),d=2;d<h;d++)f[d-2]=arguments[d];return this.tag(Y,i.apply(void 0,[o].concat(f)))}},{key:"processSubstitutions",value:function(i,o,h){var f=this.transformSubstitution(i.shift(),o);return"".concat(o,f,h)}},{key:"transformString",value:function(o){return(this||i).transformers.reduce((function(i,o){return o.onString?o.onString(i):i}),o)}},{key:"transformSubstitution",value:function(o,h){return(this||i).transformers.reduce((function(i,o){return o.onSubstitution?o.onSubstitution(i,h):i}),o)}},{key:"transformEndResult",value:function(o){return(this||i).transformers.reduce((function(i,o){return o.onEndResult?o.onEndResult(i):i}),o)}}]),t}(),v=function(){var i=arguments.length>0&&void 0!==arguments[0]?arguments[0]:"";return{onEndResult:function(o){if(""===i)return o.trim();if("start"===(i=i.toLowerCase())||"left"===i)return o.replace(/^\s*/,"");if("end"===i||"right"===i)return o.replace(/\s*$/,"");throw new Error("Side not supported: "+i)}}};function y(i){if(Array.isArray(i)){for(var o=0,h=Array(i.length);o<i.length;o++)h[o]=i[o];return h}return Array.from(i)}var b=function(){var i=arguments.length>0&&void 0!==arguments[0]?arguments[0]:"initial";return{onEndResult:function(o){if("initial"===i){var h=o.match(/^[^\S\n]*(?=\S)/gm),f=h&&Math.min.apply(Math,y(h.map((function(i){return i.length}))));if(f){var d=new RegExp("^.{"+f+"}","gm");return o.replace(d,"")}return o}if("all"===i)return o.replace(/^[^\S\n]+/gm,"");throw new Error("Unknown type: "+i)}}},Z=function(i,o){return{onEndResult:function(h){if(null==i||null==o)throw new Error("replaceResultTransformer requires at least 2 arguments.");return h.replace(i,o)}}},j=function(i,o){return{onSubstitution:function(h,f){if(null==i||null==o)throw new Error("replaceSubstitutionTransformer requires at least 2 arguments.");return null==h?h:h.toString().replace(i,o)}}},B={separator:"",conjunction:"",serial:!1},w=function(){var i=arguments.length>0&&void 0!==arguments[0]?arguments[0]:B;return{onSubstitution:function(o,h){if(Array.isArray(o)){var f=o.length,d=i.separator,p=i.conjunction,I=i.serial,S=h.match(/(\n?[^\S\n]+)$/);if(o=S?o.join(d+S[1]):o.join(d+" "),p&&f>1){var E=o.lastIndexOf(d);o=o.slice(0,E)+(I?d:"")+" "+p+o.slice(E+1)}}return o}}},G=function(i){return{onSubstitution:function(o,h){if(null==i||"string"!=typeof i)throw new Error("You need to specify a string character to split by.");return"string"==typeof o&&o.includes(i)&&(o=o.split(i)),o}}},W=function(i){return null!=i&&!Number.isNaN(i)&&"boolean"!=typeof i},P=function(){return{onSubstitution:function(i){return Array.isArray(i)?i.filter(W):W(i)?i:""}}},x=(new A(w({separator:","}),b,v),new A(w({separator:",",conjunction:"and"}),b,v),new A(w({separator:",",conjunction:"or"}),b,v),new A(G("\n"),P,w,b,v));new A(G("\n"),w,b,v,j(/&/g,"&amp;"),j(/</g,"&lt;"),j(/>/g,"&gt;"),j(/"/g,"&quot;"),j(/'/g,"&#x27;"),j(/`/g,"&#x60;")),new A(Z(/(?:\n(?:\s*))+/g," "),v),new A(Z(/(?:\n\s*)/g,""),v),new A(w({separator:","}),Z(/(?:\s+)/g," "),v),new A(w({separator:",",conjunction:"or"}),Z(/(?:\s+)/g," "),v),new A(w({separator:",",conjunction:"and"}),Z(/(?:\s+)/g," "),v),new A(w,b,v),new A(w,Z(/(?:\s+)/g," "),v),new A(b,v),new A(b("all"),v);const J=".freezeframe",F="ff-container",L="ff-loading-icon",k="ff-image",z="ff-canvas",M="ff-ready",T="ff-inactive",H="ff-active",X="ff-canvas-ready",V="ff-responsive",N="ff-overlay",C={selector:J,responsive:!0,trigger:"hover",overlay:!1,warnings:!0};var _=f(1),Q=f.n(_);var K,q,$,U=function(i,o,h,f){return new(h||(h=Promise))((function(d,p){function s(i){try{c(f.next(i))}catch(i){p(i)}}function a(i){try{c(f.throw(i))}catch(i){p(i)}}function c(i){var o;i.done?d(i.value):(o=i.value,o instanceof h?o:new h((function(i){i(o)}))).then(s,a)}c((f=f.apply(i,o||[])).next())}))},O=function(i,o,h){if(!o.has(i))throw new TypeError("attempted to set private field on non-instance");return o.set(i,h),h},D=function(i,o){if(!o.has(i))throw new TypeError("attempted to get private field on non-instance");return o.get(i)};K=new WeakMap,q=new WeakMap,$=new WeakMap;h.default=class{constructor(i=J,o){this.items=[],this.$images=[],K.set(this,void 0),q.set(this,void 0),this._eventListeners=Object.assign({},Object.values(d).reduce(((i,o)=>(i[o]=[],i)),{})),$.set(this,[]),"string"==typeof i||i instanceof Element||i instanceof HTMLCollection||i instanceof NodeList?(this.options=Object.assign(Object.assign({},C),o),O(this,K,i)):"object"!=typeof i||o?a("Invalid Freezeframe.js configuration:",...[i,o].filter((i=>void 0!==i))):(this.options=Object.assign(Object.assign({},C),i),O(this,K,this.options.selector)),this._init(D(this,K))}get _stylesInjected(){return!!document.querySelector("style#ff-styles")}_init(i){this._injectStylesheet(),O(this,q,"ontouchstart"in window||"onmsgesturechange"in window),this._capture(i),this._load(this.$images)}_capture(i){this.$images=((...i)=>(...o)=>i.reduceRight(((i,h)=>(...f)=>i(h(...f,...o))))())(c,l,u)(i,this.options)}_load(i){I()(i).on("progress",((i,{img:o})=>{this._setup(o)}))}_setup(i){return U(this,void 0,void 0,(function*(){const o=this._wrap(i);this.items.push(o),yield this._process(o),this._attach(o)}))}_wrap(i){const o=m(x`
    <div class="${F} ${L}">
    </div>
  `),h=m(x`
    <canvas class="${z}" width="0" height="0">
    </canvas>
  `);var f,d;return this.options.responsive&&o.classList.add(V),this.options.overlay&&o.appendChild(m(x`
    <div class="${N}">
    </div>
  `)),i.classList.add(k),o.appendChild(h),d=o,(f=i).parentNode.insertBefore(d,f),d.appendChild(f),{$container:o,$canvas:h,$image:i}}_process(i){return new Promise((o=>{const{$canvas:h,$image:f,$container:d}=i,{clientWidth:p,clientHeight:I}=f;h.setAttribute("width",p.toString()),h.setAttribute("height",I.toString());h.getContext("2d").drawImage(f,0,0,p,I),h.classList.add(X),h.addEventListener("transitionend",(()=>{this._ready(d),o(i)}),{once:!0})}))}_ready(i){i.classList.add(M),i.classList.add(T),i.classList.remove(L)}_attach(i){const{$image:o}=i;if(!D(this,q)&&"hover"===this.options.trigger){const n=()=>{this._toggleOn(i),this._emit(d.START,i,!0),this._emit(d.TOGGLE,i,!0)},r=()=>{this._toggleOff(i),this._emit(d.START,i,!1),this._emit(d.TOGGLE,i,!1)};this._addEventListener(o,"mouseleave",r),this._addEventListener(o,"mouseenter",n)}if(D(this,q)||"click"===this.options.trigger){const n=()=>{this._toggle(i)};this._addEventListener(o,"click",n)}}_addEventListener(i,o,h){D(this,$).push({$image:i,event:o,listener:h}),i.addEventListener(o,h)}_removeEventListener(i,o,h){i.removeEventListener(o,h)}_injectStylesheet(){this._stylesInjected||document.head.appendChild(m(x(`\n    <style id="ff-styles">\n      ${Q.a.toString()}\n    </style>\n  `)))}_emit(i,o,h){this._eventListeners[i].forEach((i=>{i(Array.isArray(o)&&1===o.length?o[0]:o,h)}))}_toggleOn(i){const{$container:o,$image:h}=i;o.classList.contains(M)&&(h.setAttribute("src",h.src),o.classList.remove(T),o.classList.add(H))}_toggleOff(i){const{$container:o}=i;o.classList.contains(M)&&(o.classList.add(T),o.classList.remove(H))}_toggle(i){const{$container:o}=i,h=o.classList.contains(H);return h?this._toggleOff(i):this._toggleOn(i),!h}start(){return this.items.forEach((i=>{this._toggleOn(i)})),this._emit(d.START,this.items,!0),this._emit(d.TOGGLE,this.items,!0),this}stop(){return this.items.forEach((i=>{this._toggleOff(i)})),this._emit(d.STOP,this.items,!1),this._emit(d.TOGGLE,this.items,!1),this}toggle(){return this.items.forEach((i=>{const o=this._toggle(i);o?this._emit(d.START,this.items,!1):this._emit(d.STOP,this.items,!1),this._emit(d.TOGGLE,this.items,o)})),this}on(i,o){return this._eventListeners[i].push(o),this}destroy(){D(this,$).forEach((({$image:i,event:o,listener:h})=>{this._removeEventListener(i,o,h)}))}}}]).default}));var h=o;const f=o.Freezeframe;export default h;export{f as Freezeframe};


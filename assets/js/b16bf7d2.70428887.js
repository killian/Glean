"use strict";(self.webpackChunkwebsite=self.webpackChunkwebsite||[]).push([[412],{3905:function(e,n,t){t.r(n),t.d(n,{MDXContext:function(){return d},MDXProvider:function(){return u},mdx:function(){return f},useMDXComponents:function(){return s},withMDXComponents:function(){return m}});var r=t(67294);function a(e,n,t){return n in e?Object.defineProperty(e,n,{value:t,enumerable:!0,configurable:!0,writable:!0}):e[n]=t,e}function o(){return o=Object.assign||function(e){for(var n=1;n<arguments.length;n++){var t=arguments[n];for(var r in t)Object.prototype.hasOwnProperty.call(t,r)&&(e[r]=t[r])}return e},o.apply(this,arguments)}function l(e,n){var t=Object.keys(e);if(Object.getOwnPropertySymbols){var r=Object.getOwnPropertySymbols(e);n&&(r=r.filter((function(n){return Object.getOwnPropertyDescriptor(e,n).enumerable}))),t.push.apply(t,r)}return t}function i(e){for(var n=1;n<arguments.length;n++){var t=null!=arguments[n]?arguments[n]:{};n%2?l(Object(t),!0).forEach((function(n){a(e,n,t[n])})):Object.getOwnPropertyDescriptors?Object.defineProperties(e,Object.getOwnPropertyDescriptors(t)):l(Object(t)).forEach((function(n){Object.defineProperty(e,n,Object.getOwnPropertyDescriptor(t,n))}))}return e}function c(e,n){if(null==e)return{};var t,r,a=function(e,n){if(null==e)return{};var t,r,a={},o=Object.keys(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||(a[t]=e[t]);return a}(e,n);if(Object.getOwnPropertySymbols){var o=Object.getOwnPropertySymbols(e);for(r=0;r<o.length;r++)t=o[r],n.indexOf(t)>=0||Object.prototype.propertyIsEnumerable.call(e,t)&&(a[t]=e[t])}return a}var d=r.createContext({}),m=function(e){return function(n){var t=s(n.components);return r.createElement(e,o({},n,{components:t}))}},s=function(e){var n=r.useContext(d),t=n;return e&&(t="function"==typeof e?e(n):i(i({},n),e)),t},u=function(e){var n=s(e.components);return r.createElement(d.Provider,{value:n},e.children)},p={inlineCode:"code",wrapper:function(e){var n=e.children;return r.createElement(r.Fragment,{},n)}},h=r.forwardRef((function(e,n){var t=e.components,a=e.mdxType,o=e.originalType,l=e.parentName,d=c(e,["components","mdxType","originalType","parentName"]),m=s(t),u=a,h=m["".concat(l,".").concat(u)]||m[u]||p[u]||o;return t?r.createElement(h,i(i({ref:n},d),{},{components:t})):r.createElement(h,i({ref:n},d))}));function f(e,n){var t=arguments,a=n&&n.mdxType;if("string"==typeof e||a){var o=t.length,l=new Array(o);l[0]=h;var i={};for(var c in n)hasOwnProperty.call(n,c)&&(i[c]=n[c]);i.originalType=e,i.mdxType="string"==typeof e?e:a,l[1]=i;for(var d=2;d<o;d++)l[d]=t[d];return r.createElement.apply(null,l)}return r.createElement.apply(null,t)}h.displayName="MDXCreateElement"},12038:function(e,n,t){t.d(n,{O1:function(){return l},EO:function(){return i},Rr:function(){return c}});var r,a=t(67294),o=t(44256);function l(e){return a.createElement("a",{href:r+e.file},e.file)}function i(e){return a.createElement("a",{href:r+e.file},e.children)}r=(0,o.isInternal)()?"https://www.internalfb.com/code/fbsource/fbcode/":"https://github.com/facebookincubator/Glean/tree/master/";var c=function(e){e.children;var n=e.internal,t=e.external;return(0,o.fbContent)({internal:a.createElement("code",null,n),external:a.createElement("code",null,t)})}},68044:function(e,n,t){t.r(n),t.d(n,{frontMatter:function(){return c},contentTitle:function(){return d},metadata:function(){return m},toc:function(){return s},default:function(){return p}});var r=t(87462),a=t(63366),o=(t(67294),t(3905)),l=(t(44256),t(12038)),i=["components"],c={id:"trying",title:"Trying Glean",sidebar_label:"Trying Glean"},d=void 0,m={unversionedId:"trying",id:"trying",isDocsHomePage:!1,title:"Trying Glean",description:"We provide a Docker image containing a pre-built set of Glean binaries",source:"@site/docs/trying.md",sourceDirName:".",slug:"/trying",permalink:"/docs/trying",editUrl:"https://github.com/facebookincubator/Glean/tree/main/glean/website/docs/trying.md",tags:[],version:"current",frontMatter:{id:"trying",title:"Trying Glean",sidebar_label:"Trying Glean"},sidebar:"someSidebar",previous:{title:"Introduction",permalink:"/docs/introduction"},next:{title:"Building Glean",permalink:"/docs/building"}},s=[{value:"Running the server",id:"running-the-server",children:[],level:2},{value:"Hyperlink demo",id:"hyperlink-demo",children:[],level:2}],u={toc:s};function p(e){var n=e.components,t=(0,a.Z)(e,i);return(0,o.mdx)("wrapper",(0,r.Z)({},u,t,{components:n,mdxType:"MDXLayout"}),(0,o.mdx)("p",null,"We provide a Docker image containing a pre-built set of Glean binaries\nthat you can try out.  These images are built automatically by a\n",(0,o.mdx)("a",{parentName:"p",href:"https://github.com/facebookincubator/Glean/blob/master/.github/workflows/glean-docker.yml"},"Github Action"),"."),(0,o.mdx)("p",null,"Pull the latest demo Docker image (warning, this is around 7GB):"),(0,o.mdx)("pre",null,(0,o.mdx)("code",{parentName:"pre"},"docker pull ghcr.io/facebookincubator/glean/demo:latest\n")),(0,o.mdx)("p",null,"Run it:"),(0,o.mdx)("pre",null,(0,o.mdx)("code",{parentName:"pre"},"docker run -it -p 8888:8888 ghcr.io/facebookincubator/glean/demo:latest\n")),(0,o.mdx)("div",{className:"admonition admonition-info alert alert--info"},(0,o.mdx)("div",{parentName:"div",className:"admonition-heading"},(0,o.mdx)("h5",{parentName:"div"},(0,o.mdx)("span",{parentName:"h5",className:"admonition-icon"},(0,o.mdx)("svg",{parentName:"span",xmlns:"http://www.w3.org/2000/svg",width:"14",height:"16",viewBox:"0 0 14 16"},(0,o.mdx)("path",{parentName:"svg",fillRule:"evenodd",d:"M7 2.3c3.14 0 5.7 2.56 5.7 5.7s-2.56 5.7-5.7 5.7A5.71 5.71 0 0 1 1.3 8c0-3.14 2.56-5.7 5.7-5.7zM7 1C3.14 1 0 4.14 0 8s3.14 7 7 7 7-3.14 7-7-3.14-7-7-7zm1 3H6v5h2V4zm0 6H6v2h2v-2z"}))),"info")),(0,o.mdx)("div",{parentName:"div",className:"admonition-content"},(0,o.mdx)("p",{parentName:"div"},"What's in the image?"),(0,o.mdx)("ul",{parentName:"div"},(0,o.mdx)("li",{parentName:"ul"},"A build of Glean, in ",(0,o.mdx)("inlineCode",{parentName:"li"},"/glean-code")),(0,o.mdx)("li",{parentName:"ul"},"The ",(0,o.mdx)("a",{parentName:"li",href:"https://github.com/facebook/flow/"},"flow")," binary, in ",(0,o.mdx)("inlineCode",{parentName:"li"},"/usr/local/bin/flow")),(0,o.mdx)("li",{parentName:"ul"},"A checkout of ",(0,o.mdx)("a",{parentName:"li",href:"https://github.com/facebook/react/"},"react")," in ",(0,o.mdx)("inlineCode",{parentName:"li"},"/react-code")),(0,o.mdx)("li",{parentName:"ul"},"A Glean database containing the Flow index of React in ",(0,o.mdx)("inlineCode",{parentName:"li"},"/gleandb"))))),(0,o.mdx)("p",null,"Start the Glean ",(0,o.mdx)("a",{parentName:"p",href:"/docs/shell"},"shell"),":"),(0,o.mdx)("pre",null,(0,o.mdx)("code",{parentName:"pre"},"glean shell --db-root /gleandb --schema /glean-code/glean/schema/source\n")),(0,o.mdx)("p",null,"You should see:"),(0,o.mdx)("pre",null,(0,o.mdx)("code",{parentName:"pre"},"Glean Shell, built on <time>, from rev <unknown>\ntype :help for help.\n>\n")),(0,o.mdx)("p",null,"The demo image contains a pre-generated database containing the\nresults of running the Flow indexer on the React repository:"),(0,o.mdx)("pre",null,(0,o.mdx)("code",{parentName:"pre"},"> :list\nreact/0 (complete)\n  Created: 2021-05-24T02:42:33Z (30 days, 9 hours ago)\n")),(0,o.mdx)("p",null,"We can look at the contents:"),(0,o.mdx)("pre",null,(0,o.mdx)("code",{parentName:"pre"},"react> :db react\nusing database react/0\nreact> :stat\nflow.Declaration.3\n  count: 26756\n  size:  888756 (867.93 kB) 4.8248%\n...\nTotal size: 17.57 MB\n")),(0,o.mdx)("h2",{id:"running-the-server"},"Running the server"),(0,o.mdx)("p",null,"Above we showed the shell reading the database from the filesystem\ndirectly. Instead we can run a server that the clients will interact\nwith to make queries:"),(0,o.mdx)("pre",null,(0,o.mdx)("code",{parentName:"pre"},"glean-server --db-root /gleandb --schema /glean-code/glean/schema/source --port 12345\n")),(0,o.mdx)("p",null,"And now the shell can connect to the server:"),(0,o.mdx)("pre",null,(0,o.mdx)("code",{parentName:"pre"},"glean shell --service localhost:12345\n")),(0,o.mdx)("p",null,"The commands work exactly the same as with local databases, but now it\nwould also work over the network."),(0,o.mdx)("h2",{id:"hyperlink-demo"},"Hyperlink demo"),(0,o.mdx)("p",null,"We have a small demo showing how Glean can enable code navigation. The ",(0,o.mdx)(l.EO,{file:"glean/demo/Hyperlink.hs",mdxType:"SrcFileLink"},"glean-hyperlink")," tool\ncreates a webserver that serves hyperlinked source code using data\nfrom a specified Glean database."),(0,o.mdx)("p",null,"We can navigate the React source code as follows. First start the\nGlean server:"),(0,o.mdx)("pre",null,(0,o.mdx)("code",{parentName:"pre"},"glean-server --db-root /gleandb --schema /glean-code/glean/schema/source --port 12345\n")),(0,o.mdx)("p",null,"Next start the Hyperlink server:"),(0,o.mdx)("pre",null,(0,o.mdx)("code",{parentName:"pre"},"glean-hyperlink --service localhost:12345 --repo react --root /react-code --http 8888\n")),(0,o.mdx)("p",null,"Now navigate to ",(0,o.mdx)("inlineCode",{parentName:"p"},"http://localhost:8888")," in your browser, and you\nshould see a list of source files. Click on a file, and navigate\naround the code by clicking on a symbol reference to jump to its\ndefinition.  Try something substantial like\n",(0,o.mdx)("inlineCode",{parentName:"p"},"react-dom/src/client/ReactDOMComponent.js"),"\n(http://localhost:8888/packages/react-dom/src/client/ReactDOMComponent.js) -\nnote how Glean is accurately linking both local and imported\nsymbols."))}p.isMDXComponent=!0}}]);
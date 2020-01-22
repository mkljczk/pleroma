(window.webpackJsonp=window.webpackJsonp||[]).push([[67],{748:function(t,e,a){"use strict";a.r(e);var n,s,o=a(0),i=a(2),c=a(7),r=a(1),l=a(1062),u=a.n(l),d=a(3),h=a.n(d),g=a(12),p=a(973),m=a(667),b=a(664),f=a(6),O=a(295),j=a.n(O),v=a(1063),_=a.n(v),M=Object(f.f)({placeholder:{id:"hashtag.column_settings.select.placeholder",defaultMessage:"Enter hashtags…"},noOptions:{id:"hashtag.column_settings.select.no_options_message",defaultMessage:"No suggestions found"}}),y=Object(f.g)(n=function(t){function e(){for(var e,a=arguments.length,n=new Array(a),s=0;s<a;s++)n[s]=arguments[s];return e=t.call.apply(t,[this].concat(n))||this,Object(r.a)(Object(i.a)(e),"state",{open:e.hasTags()}),Object(r.a)(Object(i.a)(e),"onSelect",function(t){return function(a){return e.props.onChange(["tags",t],a)}}),Object(r.a)(Object(i.a)(e),"onToggle",function(){e.state.open&&e.hasTags()&&e.props.onChange("tags",{}),e.setState({open:!e.state.open})}),Object(r.a)(Object(i.a)(e),"noOptionsMessage",function(){return e.props.intl.formatMessage(M.noOptions)}),e}Object(c.a)(e,t);var a=e.prototype;return a.hasTags=function(){var t=this;return["all","any","none"].map(function(e){return t.tags(e).length>0}).includes(!0)},a.tags=function(t){var e=this.props.settings.getIn(["tags",t])||[];return e.toJSON?e.toJSON():e},a.modeSelect=function(t){return Object(o.a)("div",{className:"column-settings__row"},void 0,Object(o.a)("span",{className:"column-settings__section"},void 0,this.modeLabel(t)),Object(o.a)(_.a,{isMulti:!0,autoFocus:!0,value:this.tags(t),onChange:this.onSelect(t),loadOptions:this.props.onLoad,className:"column-select__container",classNamePrefix:"column-select",name:"tags",placeholder:this.props.intl.formatMessage(M.placeholder),noOptionsMessage:this.noOptionsMessage}))},a.modeLabel=function(t){switch(t){case"any":return Object(o.a)(f.b,{id:"hashtag.column_settings.tag_mode.any",defaultMessage:"Any of these"});case"all":return Object(o.a)(f.b,{id:"hashtag.column_settings.tag_mode.all",defaultMessage:"All of these"});case"none":return Object(o.a)(f.b,{id:"hashtag.column_settings.tag_mode.none",defaultMessage:"None of these"});default:return""}},a.render=function(){return Object(o.a)("div",{},void 0,Object(o.a)("div",{className:"column-settings__row"},void 0,Object(o.a)("div",{className:"setting-toggle"},void 0,Object(o.a)(j.a,{id:"hashtag.column_settings.tag_toggle",onChange:this.onToggle,checked:this.state.open}),Object(o.a)("span",{className:"setting-toggle__label"},void 0,Object(o.a)(f.b,{id:"hashtag.column_settings.tag_toggle",defaultMessage:"Include additional tags in this column"})))),this.state.open&&Object(o.a)("div",{className:"column-settings__hashtags"},void 0,this.modeSelect("any"),this.modeSelect("all"),this.modeSelect("none")))},e}(h.a.PureComponent))||n,w=a(243),I=a(8),C=Object(g.connect)(function(t,e){var a=e.columnId,n=t.getIn(["settings","columns"]),s=n.findIndex(function(t){return t.get("uuid")===a});return a&&s>=0?{settings:n.get(s).get("params")}:{}},function(t,e){var a=e.columnId;return{onChange:function(e,n){t(Object(w.f)(a,e,n))},onLoad:function(t){return Object(I.a)().get("/api/v2/search",{params:{q:t,type:"hashtags"}}).then(function(t){return(t.data.hashtags||[]).map(function(t){return{value:t.name,label:"#"+t.name}})})}}})(y),N=a(33),S=a(671);a.d(e,"default",function(){return k});var k=Object(g.connect)(function(t,e){return{hasUnread:t.getIn(["timelines","hashtag:"+e.params.id,"unread"])>0}})(s=function(t){function e(){for(var e,a=arguments.length,n=new Array(a),s=0;s<a;s++)n[s]=arguments[s];return e=t.call.apply(t,[this].concat(n))||this,Object(r.a)(Object(i.a)(e),"disconnects",[]),Object(r.a)(Object(i.a)(e),"handlePin",function(){var t=e.props,a=t.columnId,n=t.dispatch;n(a?Object(w.h)(a):Object(w.e)("HASHTAG",{id:e.props.params.id}))}),Object(r.a)(Object(i.a)(e),"title",function(){var t=[e.props.params.id];return e.additionalFor("any")&&t.push(" ",Object(o.a)(f.b,{id:"hashtag.column_header.tag_mode.any",values:{additional:e.additionalFor("any")},defaultMessage:"or {additional}"},"any")),e.additionalFor("all")&&t.push(" ",Object(o.a)(f.b,{id:"hashtag.column_header.tag_mode.all",values:{additional:e.additionalFor("all")},defaultMessage:"and {additional}"},"all")),e.additionalFor("none")&&t.push(" ",Object(o.a)(f.b,{id:"hashtag.column_header.tag_mode.none",values:{additional:e.additionalFor("none")},defaultMessage:"without {additional}"},"none")),t}),Object(r.a)(Object(i.a)(e),"additionalFor",function(t){var a=e.props.params.tags;return a&&(a[t]||[]).length>0?a[t].map(function(t){return t.value}).join("/"):""}),Object(r.a)(Object(i.a)(e),"handleMove",function(t){var a=e.props,n=a.columnId;(0,a.dispatch)(Object(w.g)(n,t))}),Object(r.a)(Object(i.a)(e),"handleHeaderClick",function(){e.column.scrollTop()}),Object(r.a)(Object(i.a)(e),"setRef",function(t){e.column=t}),Object(r.a)(Object(i.a)(e),"handleLoadMore",function(t){var a=e.props.params,n=a.id,s=a.tags;e.props.dispatch(Object(N.t)(n,{maxId:t,tags:s}))}),e}Object(c.a)(e,t);var a=e.prototype;return a._subscribe=function(t,e,a){var n=this;void 0===a&&(a={});var s=(a.any||[]).map(function(t){return t.value}),o=(a.all||[]).map(function(t){return t.value}),i=(a.none||[]).map(function(t){return t.value});[e].concat(s).map(function(a){n.disconnects.push(t(Object(S.c)(e,a,function(t){var e=t.tags.map(function(t){return t.name});return o.filter(function(t){return e.includes(t)}).length===o.length&&0===i.filter(function(t){return e.includes(t)}).length})))})},a._unsubscribe=function(){this.disconnects.map(function(t){return t()}),this.disconnects=[]},a.componentDidMount=function(){var t=this.props.dispatch,e=this.props.params,a=e.id,n=e.tags;this._subscribe(t,a,n),t(Object(N.t)(a,{tags:n}))},a.componentWillReceiveProps=function(t){var e=this.props,a=e.dispatch,n=e.params,s=t.params,o=s.id,i=s.tags;o===n.id&&u()(i,n.tags)||(this._unsubscribe(),this._subscribe(a,o,i),this.props.dispatch(Object(N.k)("hashtag:"+o)),this.props.dispatch(Object(N.t)(o,{tags:i})))},a.componentWillUnmount=function(){this._unsubscribe()},a.render=function(){var t=this.props,e=t.hasUnread,a=t.columnId,n=t.multiColumn,s=this.props.params.id,i=!!a;return h.a.createElement(m.a,{ref:this.setRef,name:"hashtag",label:"#"+s},Object(o.a)(b.a,{icon:"hashtag",active:e,title:this.title(),onPin:this.handlePin,onMove:this.handleMove,onClick:this.handleHeaderClick,pinned:i,multiColumn:n,showBackButton:!0},void 0,a&&Object(o.a)(C,{columnId:a})),Object(o.a)(p.a,{trackScroll:!i,scrollKey:"hashtag_timeline-"+a,timelineId:"hashtag:"+s,onLoadMore:this.handleLoadMore,emptyMessage:Object(o.a)(f.b,{id:"empty_column.hashtag",defaultMessage:"There is nothing in this hashtag yet."})}))},e}(h.a.PureComponent))||s}}]);
//# sourceMappingURL=hashtag_timeline.js.map